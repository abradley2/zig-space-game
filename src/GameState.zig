const std = @import("std");

const GameState = @This();

rewind_start_tick: ?u32 = null,
total_ticks: u32 = 0,

pub fn onTick(self: *GameState) void {
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
