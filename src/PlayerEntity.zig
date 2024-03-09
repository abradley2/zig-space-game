const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const sdl = @import("./sdl.zig");
const DstRect = @import("./DstRect.zig");
const Controls = @import("./Controls.zig");
const Camera = @import("./Camera.zig");

const PlayerEntity = @This();

const fire_cooldown_time: u8 = 5;

x_pos: f32,
y_pos: f32,
alloc: Allocator,
fire_cooldown: u8 = 0,
src_rect: sdl.SDL_Rect = sdl.SDL_Rect{
    .x = 353,
    .y = 129,
    .w = 32,
    .h = 32,
},

pub const Event: type = enum {
    FireBlaster,
};

pub const player_speed: f32 = 4.5;

pub fn onTick(self: *PlayerEntity, controls: Controls) ?Event {
    var event: ?Event = null;
    if (controls.left_key) {
        self.x_pos -= player_speed;
    }
    if (controls.right_key) {
        self.x_pos += player_speed;
    }
    if (controls.up_key) {
        self.y_pos -= player_speed;
    }
    if (controls.down_key) {
        self.y_pos += player_speed;
    }

    if (controls.fire_key) {
        if (self.fire_cooldown == 0) {
            self.fire_cooldown = fire_cooldown_time;
            event = PlayerEntity.Event.FireBlaster;
        } else {
            self.fire_cooldown = self.fire_cooldown - 1;
        }
    } else {
        self.fire_cooldown = 0;
    }

    self.y_pos = self.y_pos - Camera.camera_scroll_speed;

    return event;
}

pub fn init(
    alloc: Allocator,
    x_pos: f32,
    y_pos: f32,
) !*PlayerEntity {
    const player = try alloc.create(PlayerEntity);
    player.* = PlayerEntity{
        .x_pos = x_pos,
        .y_pos = y_pos,
        .alloc = alloc,
    };

    return player;
}

pub fn deinit(self: *PlayerEntity) void {
    self.alloc.destroy(self);
}

pub fn getSrcRect(self: *PlayerEntity) sdl.SDL_Rect {
    return self.src_rect;
}

pub fn getDstRect(self: *PlayerEntity) DstRect {
    const w: f32 = @floatFromInt(self.src_rect.w);
    const h: f32 = @floatFromInt(self.src_rect.h);
    return DstRect{
        .x = self.x_pos,
        .y = self.y_pos,
        .w = w,
        .h = h,
    };
}
