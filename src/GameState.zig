const std = @import("std");
const Controls = @import("./Controls.zig");

const GameState = @This();

rewind_start_tick: ?u32 = null,
total_ticks: u32 = 0,

pub fn onTick(self: *GameState, controls: Controls) void {
    if (controls.rewind_key) {
        if (self.rewind_start_tick == null) {
            self.rewind_start_tick = self.total_ticks;
        }
    }

    std.debug.print("total_ticks: {} | rewind_start_tick: {?}\n", .{ self.total_ticks, self.rewind_start_tick });

    if (self.rewind_start_tick) |rewind_start_tick| {
        if (rewind_start_tick > self.total_ticks + 120) {
            self.rewind_start_tick = null;
            return;
        }

        self.total_ticks -= 1;
        return;
    }

    self.total_ticks += 1;
}
