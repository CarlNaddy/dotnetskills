using dotnetskills.Data;
using dotnetskills.Features.Listings;

namespace dotnetskills.Endpoints;

/// <summary>
/// Read-only JSON API over <see cref="Listing"/> (parity plan P4.3's worked
/// surface for caching + rate limiting). Public, unauthenticated — same
/// "public to read" policy the Blazor pages use (P3.5); there is no write
/// endpoint here.
/// </summary>
public static class ListingsApiEndpoints
{
    public static IEndpointRouteBuilder MapListingsApiEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/listings")
            .CacheOutput("Listings")
            .RequireRateLimiting("Api");

        group.MapGet("/", async (ListingQueries queries, CancellationToken ct) =>
            Results.Ok(await queries.GetAllAsync(ct)));

        group.MapGet("/{id:int}", async (int id, ListingQueries queries, CancellationToken ct) =>
        {
            var listing = await queries.GetByIdAsync(id, ct);
            return listing is null ? Results.NotFound() : Results.Ok(listing);
        });

        return app;
    }
}
