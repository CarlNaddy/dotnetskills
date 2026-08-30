namespace dotnetskills;

/// <summary>One plate in the listing gallery lightbox.</summary>
public sealed record GalleryPhoto(
    string Sheet,
    string Name,
    string Location,
    string Architect,
    string Year,
    string Image);
