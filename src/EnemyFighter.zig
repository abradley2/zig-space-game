const std = @import("std");
const sdl = @import("./sdl.zig");
const components = @import("./components.zig");
const AnimationData = components.AnimationData;
const systems = @import("./systems.zig");
const DstRect = @import("./DstRect.zig");

const EnemyFighter = @This();

alive: bool = true,
x_pos: f32,
y_pos: f32,
current_animation_ticks: u16 = 0,
current_animation_frame_idx: usize = 0,
src_rects: [2]sdl.SDL_Rect = .{
    sdl.SDL_Rect{
        .x = 32,
        .y = 33,
        .w = 16,
        .h = 14,
    },
    sdl.SDL_Rect{
        .x = 48,
        .y = 33,
        .w = 16,
        .h = 14,
    },
},

pub fn hasLifetime(self: *EnemyFighter) *bool {
    return &self.alive;
}

pub fn hasAnimation(self: *EnemyFighter) AnimationData {
    return AnimationData{
        .frames = &self.src_rects,
        .ticks_per_frame = 20,
        .current_ticks = &self.current_animation_ticks,
        .current_frame_idx = &self.current_animation_frame_idx,
    };
}

pub fn onTick(self: *EnemyFighter) void {
    self.y_pos = self.y_pos + 0.5;
}

pub fn getSrcRect(self: *EnemyFighter) sdl.SDL_Rect {
    return self.src_rects[self.current_animation_frame_idx];
}

pub fn getDstRect(self: *EnemyFighter) DstRect {
    return DstRect{
        .x = self.x_pos,
        .y = self.y_pos,
        .w = @floatFromInt(self.src_rects[self.current_animation_frame_idx].w),
        .h = @floatFromInt(self.src_rects[self.current_animation_frame_idx].h),
    };
}

pub const AnimateSystem = systems.AnimateSystem(
    EnemyFighter,
    .{ .hasAnimation = EnemyFighter.hasAnimation },
);
