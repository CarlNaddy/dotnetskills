using dotnetskills.Components;
using dotnetskills.Components.Account;
using dotnetskills.Data;
using dotnetskills.Data.Seed;
using dotnetskills.Endpoints;
using dotnetskills.Features.Email;
using dotnetskills.Features.Jobs;
using Hangfire;
using Hangfire.PostgreSql;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MudBlazor.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddMudServices();
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");

string[] supportedCultures = ["en", "de"];
var localizationOptions = new RequestLocalizationOptions()
    .SetDefaultCulture(supportedCultures[0])
    .AddSupportedCultures(supportedCultures)
    .AddSupportedUICultures(supportedCultures);

var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException(
        "Connection string 'Default' is not configured. Set it via user-secrets in "
        + "development or the ConnectionStrings__Default environment variable in production.");

// Factory, not AddDbContext: interactive Blazor components outlive a request
// scope, so each operation creates a short-lived context (MS "Blazor with EF Core").
builder.Services.AddDbContextFactory<AppDbContext>(options => options.UseNpgsql(connectionString));

// ASP.NET Core Identity stores need a scoped AppDbContext; hand them one from the
// same factory so there is still a single context configuration.
builder.Services.AddScoped<AppDbContext>(sp =>
    sp.GetRequiredService<IDbContextFactory<AppDbContext>>().CreateDbContext());

// Authentication & authorization (parity plan P3.2–P3.5) — Identity with EF Core
// stores in AppDbContext.
builder.Services.AddCascadingAuthenticationState();

// P3.5: Listings are public to read, gated to write. "ListingsWriter" = any
// signed-in user (create / edit); "ListingsAdmin" = the Admin role (delete).
// An Admin user is seeded in P3.6.
builder.Services.AddAuthorizationBuilder()
    .AddPolicy("ListingsWriter", policy => policy.RequireAuthenticatedUser())
    .AddPolicy("ListingsAdmin", policy => policy.RequireRole("Admin"));

var authentication = builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = IdentityConstants.ApplicationScheme;
    options.DefaultSignInScheme = IdentityConstants.ExternalScheme;
});
authentication.AddIdentityCookies();

// P3.4: external OAuth2 providers. Each registers only when its ClientId (and
// secret) are configured — key shape Authentication:<Provider>:{ClientId,
// ClientSecret}, from user-secrets in dev / env vars in prod. Callback paths
// are the handler defaults: /signin-google, /signin-microsoft, /signin-github.
var googleAuth = builder.Configuration.GetSection("Authentication:Google");
if (!string.IsNullOrEmpty(googleAuth["ClientId"]))
{
    authentication.AddGoogle(options =>
    {
        options.ClientId = googleAuth["ClientId"]!;
        options.ClientSecret = googleAuth["ClientSecret"]!;
    });
}

var microsoftAuth = builder.Configuration.GetSection("Authentication:Microsoft");
if (!string.IsNullOrEmpty(microsoftAuth["ClientId"]))
{
    authentication.AddMicrosoftAccount(options =>
    {
        options.ClientId = microsoftAuth["ClientId"]!;
        options.ClientSecret = microsoftAuth["ClientSecret"]!;
    });
}

var gitHubAuth = builder.Configuration.GetSection("Authentication:GitHub");
if (!string.IsNullOrEmpty(gitHubAuth["ClientId"]))
{
    authentication.AddGitHub(options =>
    {
        options.ClientId = gitHubAuth["ClientId"]!;
        options.ClientSecret = gitHubAuth["ClientSecret"]!;
        options.Scope.Add("user:email");
    });
}

builder.Services.AddIdentityCore<ApplicationUser>(options =>
    // P4.2: a registered user must confirm their email before signing in —
    // SignInManager checks this automatically, surfacing SignInResult.NotAllowed.
    // External logins bypass it (ExternalLogin.razor sets EmailConfirmed = true,
    // trusting the provider's own verification); the dev admin seed does too.
    options.SignIn.RequireConfirmedAccount = true)
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<AppDbContext>()
    .AddSignInManager()
    .AddDefaultTokenProviders();

// P3.3: Register/Login static-SSR pages redirect via NavigationManager, which
// throws a handled NavigationException during static rendering — see
// Components/Account/IdentityRedirectManager.cs.
builder.Services.AddScoped<IdentityRedirectManager>();

// Email (parity plan P4.2) — MailKit over SMTP settings in EmailOptions (dev
// default: the smtp4dev sink in compose.yaml, zero config needed). Templates
// are Razor components rendered to HTML via HtmlRenderer (the first-party way
// to render components outside a request, .NET 8+) — see docs/email.md.
builder.Services.Configure<EmailOptions>(builder.Configuration.GetSection("Email"));
builder.Services.AddScoped<HtmlRenderer>();
builder.Services.AddScoped<RazorEmailRenderer>();
builder.Services.AddScoped<IEmailSender<ApplicationUser>, MailKitEmailSender>();

// Background jobs (parity plan P4.1) — Hangfire, storage in the app's own
// Postgres DB (own schema, managed by Hangfire itself — not an EF Core
// migration; see docs/background-jobs.md). AddHangfireServer runs the worker
// as a hosted service, started by app.Run() below — never during `seed`.
builder.Services.AddHangfire(config => config
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UsePostgreSqlStorage(options => options.UseNpgsqlConnection(connectionString)));
builder.Services.AddHangfireServer();
builder.Services.AddScoped<ListingJobs>();

var app = builder.Build();

// `dotnet run -- seed`: apply migrations + seed sample data, then exit.
if (args.Contains(SeedCommand.Verb))
{
    await SeedCommand.RunAsync(app.Services);
    return;
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRequestLocalization(localizationOptions);

app.UseStaticFiles();
app.UseAntiforgery();

app.MapCultureEndpoints();
app.MapAccountEndpoints();
app.MapHangfireDashboard("/hangfire", new DashboardOptions
{
    Authorization = [new HangfireDashboardAuthorizationFilter()],
});
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

// Recurring jobs are declarative — re-registering the same job id on every
// startup just updates its schedule, so this is idempotent.
using (var scope = app.Services.CreateScope())
{
    var recurringJobs = scope.ServiceProvider.GetRequiredService<IRecurringJobManager>();
    recurringJobs.AddOrUpdate<ListingJobs>(
        "daily-listing-count",
        job => job.RecordDailyListingCountAsync(CancellationToken.None),
        Cron.Daily());
}

app.Run();
