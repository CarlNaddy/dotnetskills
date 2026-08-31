using Microsoft.EntityFrameworkCore;

namespace dotnetskills.Data;

/// <summary>
/// The application's Entity Framework Core context. Entities are added to it as
/// features land.
/// </summary>
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Listing> Listings => Set<Listing>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Listing>(listing =>
        {
            listing.Property(l => l.Status)
                .HasConversion<string>()
                .HasMaxLength(20);
        });
    }
}
