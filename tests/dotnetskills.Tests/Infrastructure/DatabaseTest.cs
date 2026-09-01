using dotnetskills.Data;

namespace dotnetskills.Tests.Infrastructure;

/// <summary>
/// Base class for tests that exercise a real PostgreSQL database. Derive from it,
/// pass the injected <see cref="PostgresFixture"/> through, and call
/// <see cref="CreateContext"/> for a fresh <see cref="AppDbContext"/>. The schema
/// is emptied before every test. Requires Docker (see <see cref="PostgresFixture"/>).
/// </summary>
[Collection(DatabaseCollectionDefinition.Name)]
public abstract class DatabaseTest(PostgresFixture fixture) : IAsyncLifetime
{
    /// <summary>The running test's cancellation token — thread it through EF async calls.</summary>
    protected static CancellationToken Ct => TestContext.Current.CancellationToken;

    protected AppDbContext CreateContext() => fixture.CreateContext();

    public async ValueTask InitializeAsync() => await fixture.ResetAsync();

    public ValueTask DisposeAsync()
    {
        GC.SuppressFinalize(this);
        return ValueTask.CompletedTask;
    }
}
