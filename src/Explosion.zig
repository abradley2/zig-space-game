const std = @import("std");
const sdl = @import("./sdl.zig");
const components = @import("./components.zig");
const AnimationData = components.AnimationData;
const systems = @import("./systems.zig");
const DstRect = @import("./DstRect.zig");
const Explosion = @This();

x_pos: f32,
y_pos: f32,
alive: bool = true,
current_animation_ticks: u16 = 0,
current_animation_frame_idx: usize = 0,

src_rects: [7]sdl.SDL_Rect = .{
    sdl.SDL_Rect{
        .x = 16,
        .y = 112,
        .w = 16,
        .h = 16,
    },
    sdl.SDL_Rect{
        .x = 32,
        .y = 112,
        .w = 16,
        .h = 16,
    },
    sdl.SDL_Rect{
        .x = 48,
        .y = 112,
        .w = 16,
        .h = 16,
    },
    sdl.SDL_Rect{
        .x = 64,
        .y = 112,
        .w = 16,
        .h = 16,
    },
    sdl.SDL_Rect{
        .x = 80,
        .y = 112,
        .w = 16,
        .h = 16,
    },
    sdl.SDL_Rect{
        .x = 96,
        .y = 112,
        .w = 16,
        .h = 16,
    },
    sdl.SDL_Rect{
        .x = 112,
        .y = 112,
        .w = 16,
        .h = 16,
    },
},

pub fn hasLifetime(self: *Explosion) *bool {
    return &self.alive;
}

pub fn getSrcRect(self: *Explosion) sdl.SDL_Rect {
    return self.src_rects[self.current_animation_frame_idx];
}

pub fn getDstRect(self: *Explosion) DstRect {
    return DstRect{
        .x = self.x_pos,
        .y = self.y_pos,
        .w = 32,
        .h = 32,
    };
}

pub fn hasAnimation(self: *Explosion) AnimationData {
    return AnimationData{
        .frames = &self.src_rects,
        .ticks_per_frame = 7,
        .current_ticks = &self.current_animation_ticks,
        .current_frame_idx = &self.current_animation_frame_idx,
    };
}

pub fn onTick(self: *Explosion) void {
    if (self.current_animation_frame_idx == self.src_rects.len - 1) {
        self.alive = false;
    }
}

pub const AnimateSystem = systems.AnimateSystem(
    Explosion,
    .{ .hasAnimation = Explosion.hasAnimation },
);
