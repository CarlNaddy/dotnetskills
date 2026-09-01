using dotnetskills.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace dotnetskills.Endpoints;

public static class AccountEndpoints
{
    /// <summary>
    /// <c>POST /Account/Logout</c> — signs the user out via
    /// <see cref="SignInManager{TUser}"/> and redirects. A minimal API
    /// endpoint, not a component: sign-out must run before the response
    /// starts, and the calling page may be rendering interactively
    /// (<c>dotnet-blazor:configure-auth</c>).
    /// </summary>
    public static IEndpointRouteBuilder MapAccountEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/Account/Logout", async (
            SignInManager<ApplicationUser> signInManager,
            [FromForm] string returnUrl) =>
        {
            await signInManager.SignOutAsync();
            return Results.LocalRedirect(string.IsNullOrEmpty(returnUrl) ? "/" : returnUrl);
        });

        return app;
    }
}
