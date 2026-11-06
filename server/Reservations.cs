using System.Text.Json;
using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Reservation(
    long Id,
    long ScreeningId,
    long UserId,
    IReadOnlyList<string> Seats,
    double TotalPrice,
    string Status);

public record ReservationInput(
    long? ScreeningId,
    IReadOnlyList<string?>? Seats,
    double? TotalPrice,
    string? Status);

public static class Reservations
{
    public const string ConfirmedStatus = "Подтверждено";
    public const string PendingStatus = "Ожидает оплаты";
    public const string CancelledStatus = "Отменено";

    private static readonly HashSet<string> AllowedStatuses =
        [ConfirmedStatus, PendingStatus, CancelledStatus];

    private static Reservation ReadReservation(SqliteDataReader reader) => new(
        reader.GetInt64(0),
        reader.GetInt64(1),
        reader.GetInt64(2),
        JsonSerializer.Deserialize<List<string>>(reader.GetString(3))
            ?? throw new JsonException("Reservation seats cannot be null"),
        reader.GetDouble(4),
        reader.GetString(5));

    private static Reservation? Find(SqliteConnection conn, long userId, long id)
    {
        using var cmd = conn.Cmd(
            "SELECT id, screening_id, user_id, seats_json, total_price, status " +
            "FROM reservations WHERE id = $id AND user_id = $userId",
            ("$id", id),
            ("$userId", userId));
        using var reader = cmd.ExecuteReader();
        return reader.Read() ? ReadReservation(reader) : null;
    }

    public static IResult List(
        HttpContext context,
        int page = 1,
        int limit = 20,
        string search = "")
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);
        var userId = Auth.CurrentUserId(context);
        var pattern = $"%{search}%";
        const string where = "user_id = $userId AND (status LIKE $pattern OR seats_json LIKE $pattern)";

        using var conn = Db.Open();
        long total;
        using (var count = conn.Cmd(
                   $"SELECT COUNT(*) FROM reservations WHERE {where}",
                   ("$userId", userId),
                   ("$pattern", pattern)))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<Reservation>();
        using (var cmd = conn.Cmd(
                   "SELECT id, screening_id, user_id, seats_json, total_price, status " +
                   $"FROM reservations WHERE {where} ORDER BY id DESC " +
                   "LIMIT $limit OFFSET $offset",
                   ("$userId", userId),
                   ("$pattern", pattern),
                   ("$limit", limit),
                   ("$offset", (page - 1) * limit)))
        using (var reader = cmd.ExecuteReader())
        {
            while (reader.Read()) items.Add(ReadReservation(reader));
        }

        return Results.Json(new { items, page, limit, total });
    }

    public static IResult Create(HttpContext context, ReservationInput input)
    {
        if (!TryValidate(input, out var screeningId, out var seats, out var status,
                out var error))
            return Errors.Validation(error!);

        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        using var transaction = conn.BeginTransaction();

        var price = FindScreeningPrice(conn, transaction, screeningId);
        if (price is null) return Errors.NotFound("Screening not found");
        if (status != CancelledStatus &&
            HasTakenSeat(conn, transaction, screeningId, seats))
            return Errors.Error(409, "SEAT_UNAVAILABLE", "One or more seats are unavailable");

        var totalPrice = price.Value * seats.Count;
        using (var insert = conn.Cmd(
                   "INSERT INTO reservations " +
                   "(screening_id, user_id, seats_json, total_price, status) " +
                   "VALUES ($screeningId, $userId, $seats, $totalPrice, $status)",
                   ("$screeningId", screeningId),
                   ("$userId", userId),
                   ("$seats", JsonSerializer.Serialize(seats)),
                   ("$totalPrice", totalPrice),
                   ("$status", status)))
        {
            insert.Transaction = transaction;
            insert.ExecuteNonQuery();
        }

        var id = conn.LastInsertRowId();
        transaction.Commit();
        return Results.Created(
            $"/reservations/{id}",
            Find(conn, userId, id)!);
    }

    public static IResult GetOne(HttpContext context, long id)
    {
        using var conn = Db.Open();
        var reservation = Find(conn, Auth.CurrentUserId(context), id);
        return reservation is null
            ? Errors.NotFound("Reservation not found")
            : Results.Json(reservation);
    }

    public static IResult Update(HttpContext context, long id, ReservationInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        var existing = Find(conn, userId, id);
        if (existing is null)
            return Errors.NotFound("Reservation not found");

        if (!TryValidate(input, out var screeningId, out var seats, out var status,
                out var error))
            return Errors.Validation(error!);

        using var transaction = conn.BeginTransaction();
        var price = FindScreeningPrice(conn, transaction, screeningId);
        if (price is null) return Errors.NotFound("Screening not found");
        if (status != CancelledStatus &&
            HasTakenSeat(conn, transaction, screeningId, seats, excludingReservationId: id))
            return Errors.Error(409, "SEAT_UNAVAILABLE", "One or more seats are unavailable");

        var sameBooking = existing.ScreeningId == screeningId &&
            existing.Seats.Order(StringComparer.Ordinal)
                .SequenceEqual(seats.Order(StringComparer.Ordinal));
        var totalPrice = sameBooking ? existing.TotalPrice : price.Value * seats.Count;
        using (var update = conn.Cmd(
                   "UPDATE reservations SET screening_id = $screeningId, seats_json = $seats, " +
                   "total_price = $totalPrice, status = $status " +
                   "WHERE id = $id AND user_id = $userId",
                   ("$screeningId", screeningId),
                   ("$seats", JsonSerializer.Serialize(seats)),
                   ("$totalPrice", totalPrice),
                   ("$status", status),
                   ("$id", id),
                   ("$userId", userId)))
        {
            update.Transaction = transaction;
            update.ExecuteNonQuery();
        }

        transaction.Commit();
        return Results.Json(Find(conn, userId, id)!);
    }

    public static IResult Delete(HttpContext context, long id)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        if (Find(conn, userId, id) is null)
            return Errors.NotFound("Reservation not found");

        using (var delete = conn.Cmd(
                   "DELETE FROM reservations WHERE id = $id AND user_id = $userId",
                   ("$id", id),
                   ("$userId", userId)))
        {
            delete.ExecuteNonQuery();
        }

        return Results.NoContent();
    }

    private static double? FindScreeningPrice(
        SqliteConnection conn,
        SqliteTransaction transaction,
        long screeningId)
    {
        using var cmd = conn.Cmd(
            "SELECT price FROM screenings WHERE id = $id",
            ("$id", screeningId));
        cmd.Transaction = transaction;
        var result = cmd.ExecuteScalar();
        return result is null ? null : Convert.ToDouble(result);
    }

    private static bool HasTakenSeat(
        SqliteConnection conn,
        SqliteTransaction transaction,
        long screeningId,
        IReadOnlyCollection<string> seats,
        long? excludingReservationId = null)
    {
        using var cmd = conn.Cmd(
            "SELECT id, seats_json FROM reservations " +
            "WHERE screening_id = $screeningId AND status <> $cancelled " +
            "AND ($excludedId IS NULL OR id <> $excludedId)",
            ("$screeningId", screeningId),
            ("$cancelled", CancelledStatus),
            ("$excludedId", excludingReservationId));
        cmd.Transaction = transaction;
        using var reader = cmd.ExecuteReader();
        var taken = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        while (reader.Read())
        {
            var existing = JsonSerializer.Deserialize<List<string>>(reader.GetString(1))
                ?? throw new JsonException("Reservation seats cannot be null");
            taken.UnionWith(existing);
        }

        return seats.Any(taken.Contains);
    }

    private static bool TryValidate(
        ReservationInput input,
        out long screeningId,
        out List<string> seats,
        out string status,
        out string? error)
    {
        screeningId = input.ScreeningId ?? 0;
        seats = input.Seats?.Select(seat => seat?.Trim() ?? "").ToList() ?? [];
        status = Errors.Trimmed(input.Status) ?? ConfirmedStatus;
        error = null;

        if (screeningId <= 0) error = "screeningId must be a positive integer";
        else if (seats.Count == 0 || seats.Count > 80)
            error = "Select between 1 and 80 seats";
        else if (seats.Any(seat => !IsValidSeat(seat)))
            error = "Seats must be in the A1-H10 range";
        else if (seats.Distinct(StringComparer.OrdinalIgnoreCase).Count() != seats.Count)
            error = "Duplicate seats are not allowed";
        else if (!AllowedStatuses.Contains(status))
            error = "status is invalid";

        return error is null;
    }

    private static bool IsValidSeat(string seat)
    {
        if (seat.Length is < 2 or > 3 || seat[0] is < 'A' or > 'H') return false;
        return int.TryParse(seat.AsSpan(1), out var number) &&
            number is >= 1 and <= 10 &&
            seat == $"{seat[0]}{number}";
    }
}
