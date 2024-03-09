const std = @import("std");

const GameState = @This();

total_ticks: u32 = 0,

pub fn onTick(self: *GameState) void {
    self.total_ticks += 1;
}
