using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace dotnetskills.Data;

/// <summary>
/// The application's Entity Framework Core context. Also the ASP.NET Core
/// Identity store (parity plan P3.2) — one database, one context, one migration
/// history. Entities are added to it as features land.
/// </summary>
public class AppDbContext(DbContextOptions<AppDbContext> options)
    : IdentityDbContext<ApplicationUser>(options)
{
    public DbSet<Listing> Listings => Set<Listing>();
    public DbSet<JobRun> JobRuns => Set<JobRun>();
    public DbSet<StoredFile> StoredFiles => Set<StoredFile>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Listing>(listing =>
        {
            listing.Property(l => l.Status)
                .HasConversion<string>()
                .HasMaxLength(20);
        });
    }
}
