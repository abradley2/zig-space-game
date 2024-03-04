const std = @import("std");
const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
});

pub const SDL_Texture: type = c.SDL_Texture;
pub const SDL_Renderer: type = c.SDL_Renderer;
pub const SDL_Rect: type = c.SDL_Rect;
pub const SDL_Event: type = c.SDL_Event;
pub const SDL_QUIT: c_int = c.SDL_QUIT;
pub const SDL_KEYDOWN: c_int = c.SDL_KEYDOWN;
pub const SDL_KEYUP: c_int = c.SDL_KEYUP;
pub const SDL_Point: type = c.SDL_Point;
pub const SDL_Keycode: type = c.SDL_Keycode;

pub const SDLK_a = c.SDLK_a;
pub const SDLK_b = c.SDLK_b;
pub const SDLK_c = c.SDLK_c;
pub const SDLK_d = c.SDLK_d;
pub const SDLK_e = c.SDLK_e;
pub const SDLK_f = c.SDLK_f;
pub const SDLK_g = c.SDLK_g;
pub const SDLK_h = c.SDLK_h;
pub const SDLK_i = c.SDLK_i;
pub const SDLK_j = c.SDLK_j;
pub const SDLK_k = c.SDLK_k;
pub const SDLK_l = c.SDLK_l;
pub const SDLK_m = c.SDLK_m;
pub const SDLK_n = c.SDLK_n;
pub const SDLK_o = c.SDLK_o;
pub const SDLK_p = c.SDLK_p;
pub const SDLK_q = c.SDLK_q;
pub const SDLK_r = c.SDLK_r;
pub const SDLK_s = c.SDLK_s;
pub const SDLK_t = c.SDLK_t;
pub const SDLK_u = c.SDLK_u;
pub const SDLK_v = c.SDLK_v;
pub const SDLK_w = c.SDLK_w;
pub const SDLK_x = c.SDLK_x;
pub const SDLK_y = c.SDLK_y;
pub const SDLK_z = c.SDLK_z;

pub const SDLK_SPACE = c.SDLK_SPACE;

pub fn renderCopyEx(
    renderer: *SDL_Renderer,
    texture: *SDL_Texture,
    f: *const SDL_Rect,
    t: *const SDL_Rect,
    angle: f64,
    center: *const SDL_Point,
) void {
    _ = c.SDL_RenderCopyEx(renderer, texture, f, t, angle, center, c.SDL_FLIP_NONE);
}

pub fn setRenderSettings() void {
    _ = c.SDL_SetHint(c.SDL_HINT_RENDER_SCALE_QUALITY, "2");
    _ = c.SDL_SetHint(c.SDL_HINT_RENDER_LINE_METHOD, "2");
}

pub fn delay(ms: u32) void {
    c.SDL_Delay(ms);
}

pub fn pollEvent(e: *SDL_Event) c_int {
    return c.SDL_PollEvent(e);
}

pub fn renderPresent(renderer: *SDL_Renderer) void {
    c.SDL_RenderPresent(renderer);
}

pub fn renderClear(renderer: *SDL_Renderer) c_int {
    return c.SDL_RenderClear(renderer);
}

pub fn setRenderDrawColor(renderer: *SDL_Renderer, r: u8, g: u8, b: u8, a: u8) c_int {
    return c.SDL_SetRenderDrawColor(renderer, r, g, b, a);
}

pub fn getTicks() u32 {
    return c.SDL_GetTicks();
}

pub fn renderCopy(
    renderer: *SDL_Renderer,
    texture: *SDL_Texture,
    f: *const SDL_Rect,
    t: *const SDL_Rect,
) void {
    _ = c.SDL_RenderCopy(renderer, texture, f, t);
}

pub fn initSDL() error{InitSDLError}!void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) return error.InitSDLError;
}

pub fn initSDLImage() error{InitSDLImageError}!void {
    const flags = c.IMG_INIT_PNG;
    if (c.IMG_Init(c.IMG_INIT_PNG) != flags) return error.InitSDLImageError;
}

pub fn loadSDLPNG(path: [*:0]const u8) error{LoadSDLPNGError}!*c.SDL_Surface {
    return c.IMG_Load(path) orelse error.LoadSDLPNGError;
}

pub fn freeSDLPNG(surface: *c.SDL_Surface) void {
    c.SDL_FreeSurface(surface);
}

pub fn textureFromSurface(renderer: *c.SDL_Renderer, surface: *c.SDL_Surface) error{TextureFromSurfaceError}!*c.SDL_Texture {
    const texture = c.SDL_CreateTextureFromSurface(renderer, surface) orelse error.TextureFromSurfaceError;
    c.SDL_FreeSurface(surface);
    return texture;
}

pub fn createWindow() error{CreateWindowError}!*c.SDL_Window {
    const window = c.SDL_CreateWindow(
        "Zig/SDL2",
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        640,
        480,
        0,
        // c.SDL_WINDOW_ALLOW_HIGHDPI + c.SDL_WINDOW_RESIZABLE,
    ) orelse error.CreateWindowError;
    return window;
}

pub fn createRenderer(window: *c.SDL_Window) error{CreateRendererError}!*c.SDL_Renderer {
    const renderer = c.SDL_CreateRenderer(
        window,
        -1,
        c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC,
    ) orelse error.CreateRendererError;
    return renderer;
}
