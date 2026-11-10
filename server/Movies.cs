using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Movie(
    long Id,
    string Title,
    string Genre,
    int DurationMin,
    string PosterUrl,
    double Rating);

public record MovieInput(
    string? Title,
    string? Genre,
    int? DurationMin,
    string? PosterUrl,
    double? Rating);

public static class Movies
{
    private static Movie ReadMovie(SqliteDataReader reader) => new(
        reader.GetInt64(0),
        reader.GetString(1),
        reader.GetString(2),
        reader.GetInt32(3),
        reader.GetString(4),
        reader.GetDouble(5));

    private static Movie? Find(SqliteConnection conn, long id)
    {
        using var cmd = conn.Cmd(
            "SELECT id, title, genre, duration_min, poster_url, rating " +
            "FROM movies WHERE id = $id",
            ("$id", id));
        using var reader = cmd.ExecuteReader();
        return reader.Read() ? ReadMovie(reader) : null;
    }

    public static IResult List(int page = 1, int limit = 20, string search = "")
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);
        var pattern = $"%{search.ToLowerInvariant()}%";

        using var conn = Db.Open();
        long total;
        using (var count = conn.Cmd(
                   "SELECT COUNT(*) FROM movies " +
                   "WHERE ulower(title) LIKE $pattern OR ulower(genre) LIKE $pattern",
                   ("$pattern", pattern)))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<Movie>();
        using (var cmd = conn.Cmd(
                   "SELECT id, title, genre, duration_min, poster_url, rating " +
                   "FROM movies WHERE ulower(title) LIKE $pattern OR ulower(genre) LIKE $pattern " +
                   "ORDER BY id DESC LIMIT $limit OFFSET $offset",
                   ("$pattern", pattern),
                   ("$limit", limit),
                   ("$offset", (page - 1) * limit)))
        using (var reader = cmd.ExecuteReader())
        {
            while (reader.Read()) items.Add(ReadMovie(reader));
        }

        return Results.Json(new { items, page, limit, total });
    }

    public static IResult Create(MovieInput input)
    {
        if (!TryValidate(input, out var title, out var genre, out var durationMin,
                out var posterUrl, out var rating, out var error))
            return Errors.Validation(error!);

        using var conn = Db.Open();
        using (var insert = conn.Cmd(
                   "INSERT INTO movies (title, genre, duration_min, poster_url, rating) " +
                   "VALUES ($title, $genre, $durationMin, $posterUrl, $rating)",
                   ("$title", title),
                   ("$genre", genre),
                   ("$durationMin", durationMin),
                   ("$posterUrl", posterUrl),
                   ("$rating", rating)))
        {
            insert.ExecuteNonQuery();
        }

        var movie = Find(conn, conn.LastInsertRowId())!;
        return Results.Created($"/movies/{movie.Id}", movie);
    }

    public static IResult GetOne(long id)
    {
        using var conn = Db.Open();
        var movie = Find(conn, id);
        return movie is null
            ? Errors.NotFound("Movie not found")
            : Results.Json(movie);
    }

    public static IResult Update(long id, MovieInput input)
    {
        using var conn = Db.Open();
        if (Find(conn, id) is null) return Errors.NotFound("Movie not found");

        if (!TryValidate(input, out var title, out var genre, out var durationMin,
                out var posterUrl, out var rating, out var error))
            return Errors.Validation(error!);

        using (var update = conn.Cmd(
                   "UPDATE movies SET title = $title, genre = $genre, " +
                   "duration_min = $durationMin, poster_url = $posterUrl, rating = $rating " +
                   "WHERE id = $id",
                   ("$title", title),
                   ("$genre", genre),
                   ("$durationMin", durationMin),
                   ("$posterUrl", posterUrl),
                   ("$rating", rating),
                   ("$id", id)))
        {
            update.ExecuteNonQuery();
        }

        return Results.Json(Find(conn, id)!);
    }

    public static IResult Delete(long id)
    {
        using var conn = Db.Open();
        if (Find(conn, id) is null) return Errors.NotFound("Movie not found");

        using (var count = conn.Cmd(
                   "SELECT COUNT(*) FROM screenings WHERE movie_id = $id",
                   ("$id", id)))
        {
            if ((long)count.ExecuteScalar()! > 0)
                return Errors.Error(409, "CONFLICT", "Movie has screenings");
        }

        using (var delete = conn.Cmd("DELETE FROM movies WHERE id = $id", ("$id", id)))
        {
            delete.ExecuteNonQuery();
        }

        return Results.NoContent();
    }

    private static bool TryValidate(
        MovieInput input,
        out string title,
        out string genre,
        out int durationMin,
        out string posterUrl,
        out double rating,
        out string? error)
    {
        title = Errors.Trimmed(input.Title) ?? "";
        genre = Errors.Trimmed(input.Genre) ?? "";
        durationMin = input.DurationMin ?? 0;
        posterUrl = input.PosterUrl?.Trim() ?? "";
        rating = input.Rating ?? double.NaN;
        error = null;

        if (title.Length == 0) error = "title is required";
        else if (genre.Length == 0) error = "genre is required";
        else if (durationMin <= 0) error = "durationMin must be greater than zero";
        else if (!double.IsFinite(rating) || rating is < 0 or > 10)
            error = "rating must be between 0 and 10";

        return error is null;
    }
}
