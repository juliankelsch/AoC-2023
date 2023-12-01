const std = @import("std");
const testing = std.testing;

const InvalidInput = error{
    lineWithoutCalibration,
};

const digits = "0123456789";

const part1 = struct {
    fn getLineCalibration(line: []const u8) InvalidInput!u32 {
        const first_index = std.mem.indexOfAny(u8, line, digits) orelse {
            return InvalidInput.lineWithoutCalibration;
        };

        const last_index = std.mem.lastIndexOfAny(u8, line, digits) orelse {
            return InvalidInput.lineWithoutCalibration;
        };

        const first_digit = @as(u32, line[first_index] - '0');
        const last_digit = @as(u32, line[last_index] - '0');

        const calibration: u32 = first_digit * 10 + last_digit;
        return calibration;
    }

    fn getCalibrationSum(input: []const u8) InvalidInput!u32 {
        var lines = std.mem.splitScalar(u8, input, '\n');

        var sum: u32 = 0;
        while (lines.next()) |line| {
            sum += try getLineCalibration(line);
        }
        return sum;
    }
};

const word2digit = [_]struct { []const u8, u32 }{
    .{ "zero", 0 },
    .{ "one", 1 },
    .{ "two", 2 },
    .{ "three", 3 },
    .{ "four", 4 },
    .{ "five", 5 },
    .{ "six", 6 },
    .{ "seven", 7 },
    .{ "eight", 8 },
    .{ "nine", 9 },
};

const part2 = struct {
    fn getLineCalibration(line: []const u8) InvalidInput!u32 {
        var first_digit: ?u32 = null;
        var last_digit: ?u32 = null;

        for (line, 0..) |char, i| {
            last_digit = switch (char) {
                '0'...'9' => |digit| digit - '0',
                else => blk: {
                    for (word2digit) |entry| {
                        const word = entry[0];
                        if (std.mem.startsWith(u8, line[i..], word)) {
                            const digit = entry[1];
                            break :blk digit;
                        }
                    }
                    // else it stays the same
                    break :blk last_digit;
                },
            };

            if (first_digit == null) {
                first_digit = last_digit;
            }
        }

        if (first_digit == null) {
            return InvalidInput.lineWithoutCalibration;
        }

        const calibration: u32 = first_digit.? * 10 + last_digit.?;
        return calibration;
    }

    fn getCalibrationSum(input: []const u8) InvalidInput!u32 {
        var lines = std.mem.splitScalar(u8, input, '\n');

        var sum: u32 = 0;
        while (lines.next()) |line| {
            sum += try getLineCalibration(line);
        }
        return sum;
    }
};

test "part 1" {
    const input =
        \\1adfaf1
        \\0adfaf3
        \\7adf4af2
        \\askldjf3ajsf
        \\saldjf0a;dfj
    ;

    // => 11 + 3 + 72 + 33 + 0 = 119

    const expected: u32 = 119;
    try testing.expectEqual(expected, try part1.getCalibrationSum(input));
}

test "part 2" {
    const input =
        \\1adfafone
        \\zeroadfaf3
        \\7adffouraf2
        \\askldjfthreeajsf
        \\saldjf0a;dfj
    ;

    // => 11 + 3 + 72 + 33 + 0 = 119

    const expected: u32 = 119;
    try testing.expectEqual(expected, try part2.getCalibrationSum(input));
}

pub fn main() !void {
    const input = @embedFile("input.txt");
    const solution1 = try part1.getCalibrationSum(input);
    const solution2 = try part2.getCalibrationSum(input);
    std.debug.print("Part 1: {}\n", .{solution1});
    std.debug.print("Part 2: {}\n", .{solution2});
}
