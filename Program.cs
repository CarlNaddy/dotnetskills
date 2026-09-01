using dotnetskills.Components;
using dotnetskills.Components.Account;
using dotnetskills.Data;
using dotnetskills.Data.Seed;
using dotnetskills.Endpoints;
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

builder.Services.AddIdentityCore<ApplicationUser>()
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<AppDbContext>()
    .AddSignInManager()
    .AddDefaultTokenProviders();

// P3.3: Register/Login static-SSR pages redirect via NavigationManager, which
// throws a handled NavigationException during static rendering — see
// Components/Account/IdentityRedirectManager.cs.
builder.Services.AddScoped<IdentityRedirectManager>();

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
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
