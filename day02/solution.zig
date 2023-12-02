const std = @import("std");
const Allocator = std.mem.Allocator;
const EnumArray = std.EnumArray;

pub const InvalidInput = error{
    MissingGame,
    MissingGameId,
    MissingHands,
    MissingCubeAmount,
    MissingCubeColor,
    UnknownColor,
};

pub const CubeColor = enum {
    red,
    green,
    blue,
};

pub const CubeSet = struct {
    red_amount: u32 = 0,
    green_amount: u32 = 0,
    blue_amount: u32 = 0,
};

const Game = struct {
    id: usize,
    hands: std.ArrayList(CubeSet),

    pub fn initParse(line: []const u8, allocator: Allocator) !Game {
        var line_split = std.mem.splitScalar(u8, line, ':');
        const game_info = line_split.next() orelse {
            return InvalidInput.MissingGame;
        };
        const hands = line_split.next() orelse {
            return InvalidInput.MissingHands;
        };

        var game_split = std.mem.splitScalar(u8, game_info, ' ');
        const game_name = game_split.next() orelse {
            return InvalidInput.MissingGameId;
        };
        _ = game_name;
        const game_id_str = game_split.next() orelse {
            return InvalidInput.MissingGameId;
        };
        const game_id = try std.fmt.parseInt(usize, game_id_str, 10);

        var game = Game{
            .id = game_id,
            .hands = std.ArrayList(CubeSet).init(allocator),
        };

        var hands_iter = std.mem.splitScalar(u8, hands, ';');

        while (hands_iter.next()) |hand_str| {
            var cube_infos = std.mem.splitScalar(u8, hand_str, ',');
            var hand = CubeSet{};
            while (cube_infos.next()) |cube_info| {
                const trimmed_cube_info = std.mem.trim(u8, cube_info, " \r");
                var cube_info_split = std.mem.splitScalar(u8, trimmed_cube_info, ' ');
                const amount_str = cube_info_split.next() orelse {
                    return InvalidInput.MissingCubeAmount;
                };
                // std.debug.print("{s}\n", .{amount_str});
                const amount = try std.fmt.parseInt(u32, amount_str, 10);
                const color_str = cube_info_split.next() orelse {
                    return InvalidInput.MissingCubeColor;
                };
                const cube_color = std.meta.stringToEnum(CubeColor, color_str) orelse {
                    return InvalidInput.UnknownColor;
                };

                switch (cube_color) {
                    .red => hand.red_amount = amount,
                    .green => hand.green_amount = amount,
                    .blue => hand.blue_amount = amount,
                }
            }
            try game.hands.append(hand);
        }

        return game;
    }

    pub fn getMinCubeSet(self: Game) CubeSet {
        var cube_set = CubeSet{};
        for (self.hands.items) |hand| {
            cube_set.red_amount = @max(cube_set.red_amount, hand.red_amount);
            cube_set.green_amount = @max(cube_set.green_amount, hand.green_amount);
            cube_set.blue_amount = @max(cube_set.blue_amount, hand.blue_amount);
        }
        return cube_set;
    }

    pub fn isPossibleWith(self: Game, bag: CubeSet) bool {
        for (self.hands.items) |hand| {
            if (hand.red_amount > bag.red_amount) {
                return false;
            }

            if (hand.green_amount > bag.green_amount) {
                return false;
            }

            if (hand.blue_amount > bag.blue_amount) {
                return false;
            }
        }
        return true;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var games = std.ArrayList(Game).init(alloc);

    const input = @embedFile("input.txt");
    var lines = std.mem.splitScalar(u8, input, '\n');
    var id_sum: usize = 0;
    var power_sum: u32 = 0;

    const bag = CubeSet{ .red_amount = 12, .green_amount = 13, .blue_amount = 14 };

    while (lines.next()) |line| {
        const game = try Game.initParse(line, alloc);
        const is_possible = game.isPossibleWith(bag);
        if (is_possible) {
            id_sum += game.id;
        }

        const min_set = game.getMinCubeSet();
        const power = min_set.red_amount * min_set.green_amount * min_set.blue_amount;
        power_sum += power;

        // std.debug.print("Game({}, {s}): {any}\n", .{ game.id, if (is_possible) "possible" else "not possible", game.hands.items });
        try games.append(game);
    }

    std.debug.print("Sum of possible game ids: {}\n", .{id_sum});
    std.debug.print("Sum of powers: {}\n", .{power_sum});
}
