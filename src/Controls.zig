const std = @import("std");
const sdl = @import("./sdl.zig");

const Controls = @This();

left_key: bool = false,
right_key: bool = false,
up_key: bool = false,
down_key: bool = false,
fire_key: bool = false,

pub fn handleKeydown(self: *Controls, key_code: sdl.SDL_Keycode) void {
    switch (key_code) {
        sdl.SDLK_a => self.left_key = true,
        sdl.SDLK_d => self.right_key = true,
        sdl.SDLK_w => self.up_key = true,
        sdl.SDLK_s => self.down_key = true,
        sdl.SDLK_SPACE => self.fire_key = true,
        else => {},
    }
}

pub fn handleKeyup(self: *Controls, key_code: sdl.SDL_Keycode) void {
    switch (key_code) {
        sdl.SDLK_a => self.left_key = false,
        sdl.SDLK_d => self.right_key = false,
        sdl.SDLK_w => self.up_key = false,
        sdl.SDLK_s => self.down_key = false,
        sdl.SDLK_SPACE => self.fire_key = false,
        else => {},
    }
}
