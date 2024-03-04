const std = @import("std");
const sdl = @import("./sdl.zig");
const DstRect = @import("./DstRect.zig");

const Camera = @This();

x_pos: f32 = 0.0,
y_pos: f32 = 0.0,
zoom_level: f32 = 1,

pub const camera_scroll_speed: f32 = 0.5;

pub fn withYScrollOffset(self: Camera, y_offset: f32) Camera {
    return Camera{
        .x_pos = self.x_pos,
        .y_pos = self.y_pos + y_offset,
        .zoom_level = self.zoom_level,
    };
}

pub fn onTick(self: *Camera) void {
    self.y_pos = self.y_pos - Camera.camera_scroll_speed;
}

pub fn dstRectLens(self: Camera, dst_rect: DstRect) sdl.SDL_Rect {
    // TODO: can cache the multiplication of own zoom level! (and everywhere for that matter)
    const dst_rect_x: i32 = @intFromFloat(@round((dst_rect.x * self.zoom_level) + ((self.x_pos * self.zoom_level) * -1)));
    const dst_rect_y: i32 = @intFromFloat(@round((dst_rect.y * self.zoom_level) + ((self.y_pos * self.zoom_level) * -1)));

    const dst_rect_w: i32 = @intFromFloat(@round(dst_rect.w * self.zoom_level));
    const dst_rect_h: i32 = @intFromFloat(@round(dst_rect.h * self.zoom_level));

    return sdl.SDL_Rect{
        .x = @as(c_int, @intCast(dst_rect_x)),
        .y = @as(c_int, @intCast(dst_rect_y)),
        .w = @as(c_int, @intCast(dst_rect_w)),
        .h = @as(c_int, @intCast(dst_rect_h)),
    };
}
