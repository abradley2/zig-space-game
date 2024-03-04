const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const sdl = @import("./sdl.zig");
const components = @import("./components.zig");
const systems = @import("./systems.zig");
const DstRect = @import("./DstRect.zig");

const BlasterEntity = @This();

is_alive: bool = true,
current_frame: usize,
current_ticks: u16,
x_pos: f32,
y_pos: f32,

pub const blaster_speed = 8.0;

pub const src_rects: [2]sdl.SDL_Rect = .{
    sdl.SDL_Rect{
        .x = 4,
        .y = 85,
        .w = 5,
        .h = 10,
    },
    sdl.SDL_Rect{
        .x = 10,
        .y = 85,
        .w = 5,
        .h = 10,
    },
};
pub fn onTick(self: *BlasterEntity) void {
    self.y_pos = self.y_pos - blaster_speed;
}

pub fn hasLifetime(self: *BlasterEntity) *bool {
    return &self.is_alive;
}

pub fn hasAnimation(self: *BlasterEntity) components.AnimationData {
    return components.AnimationData{
        .frames = &BlasterEntity.src_rects,
        .current_frame_idx = &self.current_frame,
        .current_ticks = &self.current_ticks,
        .ticks_per_frame = 7,
    };
}
pub const AnimateSystem = systems.AnimateSystem(
    BlasterEntity,
    .{ .hasAnimation = BlasterEntity.hasAnimation },
);
pub fn getSrcRect(self: *BlasterEntity) sdl.SDL_Rect {
    return BlasterEntity.src_rects[self.current_frame];
}
pub fn getDstRect(self: *BlasterEntity) DstRect {
    return DstRect{
        .x = self.x_pos,
        .y = self.y_pos,
        .w = @floatFromInt(BlasterEntity.src_rects[self.current_frame].w),
        .h = @floatFromInt(BlasterEntity.src_rects[self.current_frame].h),
    };
}

pub fn new(x_pos: f32, y_pos: f32) BlasterEntity {
    return BlasterEntity{
        .current_ticks = 0,
        .current_frame = 0,
        .x_pos = x_pos,
        .y_pos = y_pos,
    };
}
