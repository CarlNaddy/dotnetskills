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

// Authentication & authorization (parity plan P3.2) — Identity with EF Core
// stores in AppDbContext. Login/register/manage pages land in P3.3.
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddAuthorization();

builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = IdentityConstants.ApplicationScheme;
    options.DefaultSignInScheme = IdentityConstants.ExternalScheme;
})
.AddIdentityCookies();

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
