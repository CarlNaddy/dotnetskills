using Microsoft.EntityFrameworkCore;

namespace dotnetskills.Data.Seed;

/// <summary>
/// Entry point for <c>dotnet run -- seed</c>: applies pending migrations, then
/// runs <see cref="DbSeeder"/>. Keeps a fresh clone to a single command.
/// </summary>
public static class SeedCommand
{
    public const string Verb = "seed";

    public static async Task RunAsync(IServiceProvider services)
    {
        await using var scope = services.CreateAsyncScope();
        var factory = scope.ServiceProvider.GetRequiredService<IDbContextFactory<AppDbContext>>();
        var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger(Verb);

        await using var db = await factory.CreateDbContextAsync();

        logger.LogInformation("Applying pending migrations...");
        await db.Database.MigrateAsync();

        await DbSeeder.SeedAsync(db, logger);
    }
}
