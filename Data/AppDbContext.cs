using Microsoft.EntityFrameworkCore;

namespace dotnetskills.Data;

/// <summary>
/// The application's Entity Framework Core context. Entities are added to it as
/// features land — the first one at rails-parity plan P1.8.
/// </summary>
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
}
