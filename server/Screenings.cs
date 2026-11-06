using System.Text.Json;
using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Screening(
    long Id,
    long MovieId,
    string Hall,
    DateTimeOffset DateTime,
    double Price,
    IReadOnlyList<string> SeatsTaken);

public record ScreeningInput(
    long? MovieId,
    string? Hall,
    DateTimeOffset? DateTime,
    double? Price);

public static class Screenings
{
    private static Screening ReadScreening(SqliteDataReader reader) => new(
        reader.GetInt64(0),
        reader.GetInt64(1),
        reader.GetString(2),
        DateTimeOffset.Parse(reader.GetString(3)),
        reader.GetDouble(4),
        []);

    private static Screening? Find(SqliteConnection conn, long id)
    {
        using var cmd = conn.Cmd(
            "SELECT id, movie_id, hall, date_time, price FROM screenings WHERE id = $id",
            ("$id", id));
        using var reader = cmd.ExecuteReader();
        return reader.Read() ? ReadScreening(reader) : null;
    }

    private static Screening WithTakenSeats(SqliteConnection conn, Screening screening)
    {
        var seats = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        using var cmd = conn.Cmd(
            "SELECT seats_json FROM reservations " +
            "WHERE screening_id = $screeningId AND status <> $cancelled",
            ("$screeningId", screening.Id),
            ("$cancelled", Reservations.CancelledStatus));
        using var reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            var reservationSeats = JsonSerializer.Deserialize<List<string>>(reader.GetString(0))
                ?? throw new JsonException("Reservation seats cannot be null");
            seats.UnionWith(reservationSeats);
        }

        return screening with { SeatsTaken = seats.Order(StringComparer.Ordinal).ToArray() };
    }

    public static IResult List(
        SqliteConnection conn,
        long? movieId = null,
        int page = 1,
        int limit = 20,
        string search = "")
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);
        var pattern = $"%{search}%";
        const string where = "($movieId IS NULL OR movie_id = $movieId) AND hall LIKE $pattern";

        long total;
        using (var count = conn.Cmd(
                   $"SELECT COUNT(*) FROM screenings WHERE {where}",
                   ("$movieId", movieId),
                   ("$pattern", pattern)))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<Screening>();
        using (var cmd = conn.Cmd(
                   $"SELECT id, movie_id, hall, date_time, price FROM screenings WHERE {where} " +
                   "ORDER BY date_time, id LIMIT $limit OFFSET $offset",
                   ("$movieId", movieId),
                   ("$pattern", pattern),
                   ("$limit", limit),
                   ("$offset", (page - 1) * limit)))
        using (var reader = cmd.ExecuteReader())
        {
            while (reader.Read()) items.Add(ReadScreening(reader));
        }

        var resultItems = items
            .Select(item => WithTakenSeats(conn, item))
            .ToArray();
        return Results.Json(new
        {
            items = resultItems,
            page,
            limit,
            total,
        });
    }

    public static IResult ListEndpoint(
        long? movieId = null,
        int page = 1,
        int limit = 20,
        string search = "")
    {
        using var conn = Db.Open();
        return List(conn, movieId, page, limit, search);
    }

    public static IResult Create(ScreeningInput input)
    {
        if (!TryValidate(input, out var movieId, out var hall, out var dateTime,
                out var price, out var error))
            return Errors.Validation(error!);

        using var conn = Db.Open();
        if (!MovieExists(conn, movieId))
            return Errors.NotFound("Movie not found");

        using (var insert = conn.Cmd(
                   "INSERT INTO screenings (movie_id, hall, date_time, price) " +
                   "VALUES ($movieId, $hall, $dateTime, $price)",
                   ("$movieId", movieId),
                   ("$hall", hall),
                   ("$dateTime", dateTime.ToString("O")),
                   ("$price", price)))
        {
            insert.ExecuteNonQuery();
        }

        var screening = Find(conn, conn.LastInsertRowId())!;
        return Results.Created(
            $"/screenings/{screening.Id}",
            WithTakenSeats(conn, screening));
    }

    public static IResult GetOne(long id)
    {
        using var conn = Db.Open();
        var screening = Find(conn, id);
        return screening is null
            ? Errors.NotFound("Screening not found")
            : Results.Json(WithTakenSeats(conn, screening));
    }

    public static IResult Update(long id, ScreeningInput input)
    {
        using var conn = Db.Open();
        if (Find(conn, id) is null)
            return Errors.NotFound("Screening not found");

        if (!TryValidate(input, out var movieId, out var hall, out var dateTime,
                out var price, out var error))
            return Errors.Validation(error!);

        if (!MovieExists(conn, movieId))
            return Errors.NotFound("Movie not found");

        using (var update = conn.Cmd(
                   "UPDATE screenings SET movie_id = $movieId, hall = $hall, " +
                   "date_time = $dateTime, price = $price WHERE id = $id",
                   ("$movieId", movieId),
                   ("$hall", hall),
                   ("$dateTime", dateTime.ToString("O")),
                   ("$price", price),
                   ("$id", id)))
        {
            update.ExecuteNonQuery();
        }

        return Results.Json(WithTakenSeats(conn, Find(conn, id)!));
    }

    public static IResult Delete(long id)
    {
        using var conn = Db.Open();
        if (Find(conn, id) is null)
            return Errors.NotFound("Screening not found");

        using (var count = conn.Cmd(
                   "SELECT COUNT(*) FROM reservations WHERE screening_id = $id",
                   ("$id", id)))
        {
            if ((long)count.ExecuteScalar()! > 0)
                return Errors.Error(409, "CONFLICT", "Screening has reservations");
        }

        using (var delete = conn.Cmd("DELETE FROM screenings WHERE id = $id", ("$id", id)))
        {
            delete.ExecuteNonQuery();
        }

        return Results.NoContent();
    }

    private static bool MovieExists(SqliteConnection conn, long movieId)
    {
        using var cmd = conn.Cmd("SELECT 1 FROM movies WHERE id = $id", ("$id", movieId));
        return cmd.ExecuteScalar() is not null;
    }

    private static bool TryValidate(
        ScreeningInput input,
        out long movieId,
        out string hall,
        out DateTimeOffset dateTime,
        out double price,
        out string? error)
    {
        movieId = input.MovieId ?? 0;
        hall = Errors.Trimmed(input.Hall) ?? "";
        dateTime = input.DateTime ?? default;
        price = input.Price ?? double.NaN;
        error = null;

        if (movieId <= 0) error = "movieId must be a positive integer";
        else if (hall.Length == 0) error = "hall is required";
        else if (dateTime == default) error = "dateTime is required";
        else if (!double.IsFinite(price) || price <= 0)
            error = "price must be greater than zero";

        return error is null;
    }
}
