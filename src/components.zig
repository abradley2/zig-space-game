const std = @import("std");
const sdl = @import("./sdl.zig");
const DstRect = @import("./DstRect.zig");

pub const AnimationData: type = struct {
    frames: []const sdl.SDL_Rect,
    current_frame_idx: *usize,
    current_ticks: *u16,
    ticks_per_frame: u16,
};

pub fn HasAnimation(comptime T: anytype) type {
    return fn (self: *T) AnimationData;
}

pub fn HasDstRect(comptime T: anytype) type {
    return fn (self: *T) *sdl.SDL_Rect;
}

pub fn HasLifetime(comptime T: anytype) type {
    return fn (self: *T) *bool;
}
