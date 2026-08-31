using dotnetskills.Components;
using dotnetskills.Data;
using dotnetskills.Data.Seed;
using Microsoft.EntityFrameworkCore;
using MudBlazor.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddMudServices();

var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException(
        "Connection string 'Default' is not configured. Set it via user-secrets in "
        + "development or the ConnectionStrings__Default environment variable in production.");

// Factory, not AddDbContext: interactive Blazor components outlive a request
// scope, so each operation creates a short-lived context (MS "Blazor with EF Core").
builder.Services.AddDbContextFactory<AppDbContext>(options => options.UseNpgsql(connectionString));

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

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
