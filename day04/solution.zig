const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const mem = std.mem;

const example = false;
const input = @embedFile(if (example) "example.txt" else "input.txt");

const Card = struct {
    id: usize,
    winning: [winning_count]u32,
    numbers: [numbers_count]u32,

    const winning_count = if (example) 5 else 10;
    const numbers_count = if (example) 10 else 27;

    pub fn getMatches(self: Card) usize {
        var matches: usize = 0;
        for (self.numbers) |num| {
            const is_winning_num = mem.indexOfScalar(u32, &self.winning, num) != null;
            if (is_winning_num) {
                matches += 1;
            }
        }
        return matches;
    }

    // part 1
    pub fn getPoints(self: Card) u32 {
        const matches = self.getMatches();

        if (matches > 0) {
            return @as(u32, 1) << @intCast(matches - 1);
        }
        return 0;
    }
};

test "card getPoints" {
    // const card1 = Card{};
    // testing.expectEqual(@as(u32, 1), actual: @TypeOf(expected))
}

pub fn solvePart2For(cards: []const Card, start: usize) usize {
    const card = cards[start];
    const matches = card.getMatches();

    var child_matches: usize = 0;
    for ((start + 1)..(start + matches + 1)) |i| {
        child_matches += solvePart2For(cards, i);
    }
    return matches + child_matches;
}

pub fn parseCard(line: []const u8) !Card {
    var info_it = mem.split(u8, line, ": ");
    const card_header = info_it.next().?;

    const id_str = mem.trim(u8, card_header, "Card ");
    const id = try std.fmt.parseInt(usize, id_str, 10);

    const card_contents = info_it.next().?;

    var contents_it = mem.split(u8, card_contents, " | ");
    const winning_str = contents_it.next().?;
    const numbers_str = contents_it.next().?;

    var winning: [Card.winning_count]u32 = undefined;
    var numbers: [Card.numbers_count]u32 = undefined;

    try parseNumberList(winning_str, &winning);
    try parseNumberList(numbers_str, &numbers);

    const card = Card{
        .id = id,
        .winning = winning,
        .numbers = numbers,
    };
    return card;
}

pub fn parseNumberList(str: []const u8, numbers: []u32) !void {
    var numbers_it = mem.split(u8, str, " ");
    var i: usize = 0;
    while (numbers_it.next()) |num_str| {
        if (num_str.len == 0) {
            continue;
        }

        numbers[i] = try std.fmt.parseInt(u32, num_str, 10);

        i += 1;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const line_sep = "\r\n";

    var cards = std.ArrayList(Card).init(alloc);
    defer cards.deinit();

    var line_it = mem.split(u8, input, line_sep);
    while (line_it.next()) |line| {
        const card = try parseCard(line);
        try cards.append(card);
    }

    var total_points: usize = 0;
    for (cards.items) |card| {
        total_points += card.getPoints();
    }

    var total_points2: usize = cards.items.len;
    for (0..cards.items.len) |i| {
        total_points2 += solvePart2For(cards.items, i);
    }

    print("(Part 1) Total points: {}\n", .{total_points});
    print("(Part 2) Total points: {}\n", .{total_points2});
}
