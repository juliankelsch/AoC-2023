const std = @import("std");
const print = std.debug.print;

const Engine = struct {
    data: []const u8,
    width: usize,
    height: usize,

    pub fn init(data: []const u8) Engine {
        return .{
            .data = data,
            .width = std.mem.indexOf(u8, input, "\r\n") orelse 0 + 1,
            .height = std.mem.count(u8, input, "\r\n") + 1,
        };
    }

    pub fn index(self: Engine, x: usize, y: usize) usize {
        return y * (self.width + 2) + x;
    }

    pub fn insideBounds(self: Engine, x: isize, y: isize) bool {
        return x < self.width and y < self.height;
    }

    pub fn at(self: Engine, x: usize, y: usize) u8 {
        // + 2 because of window newline \r\n
        return self.data[self.index(x, y)];
    }
};

fn fillAdjacencyMap(engine: Engine, map: []bool) void {
    var y: usize = 0;
    while (y < engine.height) : (y += 1) {
        var x: usize = 0;
        while (x < engine.width) : (x += 1) {
            const char = engine.at(x, y);
            const is_symbol = char != '.' and !std.ascii.isDigit(char);
            if (is_symbol) {
                var dy: isize = -1;
                while (dy < 2) : (dy += 1) {
                    var dx: isize = -1;
                    while (dx < 2) : (dx += 1) {
                        const cellx = @as(isize, @intCast(x)) + dx;
                        const celly = @as(isize, @intCast(y)) + dy;
                        if (engine.insideBounds(cellx, celly)) {
                            // print("{}/{} ", .{ cellx, celly });
                            map[engine.index(@intCast(cellx), @intCast(celly))] = true;
                        }
                    }
                }
                // print("\n", .{});
            }
        }
    }
}

fn fillGearMap(engine: Engine, map: []?usize) void {
    var y: usize = 0;
    while (y < engine.height) : (y += 1) {
        var x: usize = 0;
        while (x < engine.width) : (x += 1) {
            const char = engine.at(x, y);
            const is_gear = char == '*';
            if (is_gear) {
                var dy: isize = -1;
                while (dy < 2) : (dy += 1) {
                    var dx: isize = -1;
                    while (dx < 2) : (dx += 1) {
                        const cellx = @as(isize, @intCast(x)) + dx;
                        const celly = @as(isize, @intCast(y)) + dy;
                        if (engine.insideBounds(cellx, celly)) {
                            // print("{}/{} ", .{ cellx, celly });
                            map[engine.index(@intCast(cellx), @intCast(celly))] = engine.index(x, y);
                        }
                    }
                }
                // print("\n", .{});
            }
        }
    }
}

fn printMap(engine: Engine, map: []bool) void {
    var y: usize = 0;
    while (y < engine.height) : (y += 1) {
        var x: usize = 0;
        while (x < engine.width) : (x += 1) {
            const c: u8 = if (map[engine.index(x, y)]) '#' else '.';
            print("{c} ", .{c});
        }
        print("\n", .{});
    }
}

fn printGearMap(engine: Engine, map: []?usize) void {
    var y: usize = 0;
    while (y < engine.height) : (y += 1) {
        var x: usize = 0;
        while (x < engine.width) : (x += 1) {
            const c: usize = if (map[engine.index(x, y)]) |g| g else 0;
            print("{} ", .{c});
        }
        print("\n", .{});
    }
}

const input = @embedFile("input.txt");
var adjacency_map = [_]bool{false} ** input.len;

// maps the gear index to the engine schematic
var gear_map = [_]?usize{null} ** input.len;

// 559667

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var alloc = arena.allocator();
    defer arena.deinit();

    var gear_numbers = std.AutoArrayHashMap(usize, std.ArrayList(usize)).init(alloc);

    const engine = Engine.init(input);
    fillAdjacencyMap(engine, &adjacency_map);
    fillGearMap(engine, &gear_map);

    // printGearMap(engine, &gear_map);
    // printMap(engine, &adjacency_map);

    // print("engine {}:{}\n", .{ engine.width, engine.height });

    var y: usize = 0;
    var num: usize = 0;
    var sum: usize = 0;
    var adjacent = false;
    var gear: ?usize = null;
    while (y < engine.height) : (y += 1) {
        var x: usize = 0;
        while (x < engine.width) : (x += 1) {
            const char = engine.at(x, y);
            switch (char) {
                '0'...'9' => |digit| {
                    const index = engine.index(x, y);
                    adjacent = adjacent or adjacency_map[index];
                    gear = gear orelse gear_map[index];
                    num = num * 10 + (digit - '0');
                },
                else => {
                    if (gear) |g| {
                        const entry = try gear_numbers.getOrPut(g);
                        if (!entry.found_existing) {
                            entry.value_ptr.* = std.ArrayList(usize).init(alloc);
                        }

                        try entry.value_ptr.*.append(num);
                    }
                    gear = null;

                    if (adjacent) {
                        // print("+ {}", .{num});
                        sum += num;
                    }
                    adjacent = false;
                    num = 0;
                },
            }
            // print("{c} ", .{char});
        }
        // print("\n", .{});
    }

    if (gear) |g| {
        const entry = try gear_numbers.getOrPut(g);
        if (!entry.found_existing) {
            entry.value_ptr.* = std.ArrayList(usize).init(alloc);
        }

        try entry.value_ptr.*.append(num);
    }

    if (adjacent) {
        // print("+ {}", .{num});
        sum += num;
    }

    var gear_ratio_sum: usize = 0;
    var gear_num_it = gear_numbers.iterator();
    while (gear_num_it.next()) |gear_num_entry| {
        const nums = gear_num_entry.value_ptr.*.items;
        if (nums.len == 2) {
            gear_ratio_sum += nums[0] * nums[1];
        }
    }

    print("(part 1) sum: {}\n", .{sum});
    print("(part 2) gear ratio sum: {}\n", .{gear_ratio_sum});
}
