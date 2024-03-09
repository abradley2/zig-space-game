const std = @import("std");
const heap = std.heap;
const path = std.fs.path;
const AutoHashMap = std.hash_map.AutoHashMap;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const tiled = @import("./tiled.zig");
const sdl = @import("./sdl.zig");
const BlasterEntity = @import("./BlasterEntity.zig");
const PlayerEntity = @import("./PlayerEntity.zig");
const EnemyFighter = @import("./EnemyFighter.zig");
const Camera = @import("./Camera.zig");
const DstRect = @import("./DstRect.zig");
const Controls = @import("./Controls.zig");
const Spawner = @import("./Spawner.zig");
const Explosion = @import("./Explosion.zig");
const systems = @import("./systems.zig");
const EntityPool = systems.EntityPool;

pub fn main() !void {
    const window = try sdl.createWindow();
    const renderer = try sdl.createRenderer(window);

    var level_arena_cur = heap.ArenaAllocator.init(heap.page_allocator);
    var level_arena_nxt = heap.ArenaAllocator.init(heap.page_allocator);

    var entity_gpa = heap.GeneralPurposeAllocator(.{}){};

    const path_segments: [2][]const u8 = .{ "assets", "space-shooter-sheet-transparent.png" };
    const asset_path: [*:0]u8 = try path.joinZ(entity_gpa.allocator(), &path_segments);
    const surface = try sdl.loadSDLPNG(asset_path);

    const game_texture = try sdl.textureFromSurface(renderer, surface);

    var blaster_entities = EntityPool(BlasterEntity, .{
        .isRemovable = BlasterEntity.isRemovable,
    }){};
    var enemy_fighters = EntityPool(EnemyFighter, .{
        .isRemovable = EnemyFighter.isRemovable,
    }){};
    var explosions = EntityPool(Explosion, .{
        .isRemovable = Explosion.isRemovable,
    }){};

    var camera = Camera{};

    var spawner = Spawner{};
    var spawner_events: [5]Spawner.Event = undefined;

    var controls = Controls{};

    var player_entity = try PlayerEntity.init(
        entity_gpa.allocator(),
        200,
        400,
    );

    const map_file_path_segments: [2][]const u8 = .{ "levels", "level_00_00.json" };
    var cur_map_layers: [][]?StaticTile = try loadTiledData(
        level_arena_cur.allocator(),
        map_file_path_segments,
        null,
    );
    var nxt_map_layers: [][]?StaticTile = try loadTiledData(
        level_arena_nxt.allocator(),
        map_file_path_segments,
        null,
    );

    var run = true;

    sdl.setRenderSettings();

    var total_ticks = sdl.getTicks();
    var frames: u32 = 0;
    while (run) {
        defer {
            frames = frames + 1;
            enemy_fighters.cleanupEntities(entity_gpa.allocator(), frames);
            explosions.cleanupEntities(entity_gpa.allocator(), frames);
            blaster_entities.cleanupEntities(entity_gpa.allocator(), frames);
        }

        const game_loop_start = sdl.getTicks();
        handleEvent(&run, &controls);

        {
            var blaster_entity_opt = blaster_entities.list.first;
            while (blaster_entity_opt) |blaster_entity_node| {
                blaster_entity_opt = blaster_entity_node.next;
                BlasterEntity.AnimateSystem.onTick(&blaster_entity_node.data);
                blaster_entity_node.data.onTick();
            }
        }
        {
            var enemy_fighter_opt = enemy_fighters.list.first;
            while (enemy_fighter_opt) |enemy_fighter_node| {
                enemy_fighter_opt = enemy_fighter_node.next;
                EnemyFighter.AnimateSystem.onTick(&enemy_fighter_node.data);
                enemy_fighter_node.data.onTick();
            }
        }
        {
            var explosion_opt = explosions.list.first;
            while (explosion_opt) |explosion_node| {
                explosion_opt = explosion_node.next;
                Explosion.AnimateSystem.onTick(&explosion_node.data);
                explosion_node.data.onTick(frames);
            }
        }

        if (player_entity.onTick(controls)) |event| {
            switch (event) {
                PlayerEntity.Event.FireBlaster => {
                    try blaster_entities.addEntity(
                        entity_gpa.allocator(),
                        BlasterEntity.new(player_entity.x_pos, player_entity.y_pos),
                    );

                    try blaster_entities.addEntity(
                        entity_gpa.allocator(),
                        BlasterEntity.new(player_entity.x_pos + 10, player_entity.y_pos),
                    );
                },
            }
        }

        for (spawner.onTick(&spawner_events)) |event| {
            switch (event) {
                .spawn_fighter => |x_pos| {
                    try enemy_fighters.addEntity(
                        entity_gpa.allocator(),
                        EnemyFighter{
                            .x_pos = x_pos,
                            .y_pos = camera.y_pos,
                        },
                    );
                },
            }
        }

        var err = sdl.setRenderDrawColor(renderer, 0, 0, 0, 50);
        if (err != 0) return error.SetRenderDrawColorError;

        err = sdl.renderClear(renderer);
        if (err != 0) return error.RenderClearError;

        // Render static map rects
        var did_display = false;
        for (cur_map_layers) |layer| {
            for (layer) |texture_rect_opt| {
                if (texture_rect_opt) |texture_rect| {
                    const dst_rect = camera.dstRectLens(texture_rect.dst_rect);

                    // TODO: this must scale to zoom
                    if (texture_rect.dst_rect.y < 640 + camera.y_pos) {
                        sdl.renderCopy(
                            renderer,
                            game_texture,
                            &texture_rect.src_rect,
                            &dst_rect,
                        );
                        did_display = true;
                    }
                }
            }
        }

        camera.onTick();

        if (did_display == false) {
            cur_map_layers = try advanceTreadmill(
                &level_arena_cur,
                &level_arena_nxt,
                nxt_map_layers,
            );
            nxt_map_layers = try loadTiledData(
                level_arena_nxt.allocator(),
                map_file_path_segments,
                camera,
            );
            continue;
        }

        const nxt_camera = camera.withYScrollOffset(640);
        for (nxt_map_layers) |layer| {
            for (layer) |texture_rect_opt| {
                if (texture_rect_opt) |texture_rect| {
                    sdl.renderCopy(
                        renderer,
                        game_texture,
                        &texture_rect.src_rect,
                        &nxt_camera.dstRectLens(texture_rect.dst_rect),
                    );
                }
            }
        }

        sdl.renderCopy(
            renderer,
            game_texture,
            &player_entity.getSrcRect(),
            &camera.dstRectLens(player_entity.getDstRect()),
        );

        {
            var blaster_entity_opt = blaster_entities.list.first;
            while (blaster_entity_opt) |blaster_entity_node| {
                blaster_entity_opt = blaster_entity_node.next;

                if (blaster_entity_node.data.removed_at != null) continue;

                var src_rect = blaster_entity_node.data.getSrcRect();
                var dst_rect = camera.dstRectLens(blaster_entity_node.data.getDstRect());
                if (dst_rect.y > 0) {
                    sdl.renderCopy(renderer, game_texture, &src_rect, &dst_rect);
                    continue;
                }
                if (blaster_entity_node.data.removed_at == null)
                    blaster_entity_node.data.removed_at = frames;
            }
        }

        {
            var enemy_fighter_opt = enemy_fighters.list.first;
            while (enemy_fighter_opt) |enemy_fighter_node| {
                enemy_fighter_opt = enemy_fighter_node.next;

                if (enemy_fighter_node.data.removed_at != null) continue;

                var src_rect = enemy_fighter_node.data.getSrcRect();
                var dst_rect = camera.dstRectLens(enemy_fighter_node.data.getDstRect());
                const center = sdl.SDL_Point{ .x = 7, .y = 8 };
                if (@as(f32, @floatFromInt(dst_rect.y)) < 640.0 * camera.zoom_level) {
                    sdl.renderCopyEx(renderer, game_texture, &src_rect, &dst_rect, 180.0, &center);
                    continue;
                }
                if (enemy_fighter_node.data.removed_at == null)
                    enemy_fighter_node.data.removed_at = frames;
            }
        }

        {
            var explosion_opt = explosions.list.first;
            while (explosion_opt) |explosion_node| {
                explosion_opt = explosion_node.next;

                if (explosion_node.data.removed_at != null) continue;

                var src_rect = explosion_node.data.getSrcRect();
                var dst_rect_1 = explosion_node.data.getDstRect();
                dst_rect_1.y -= 5;
                dst_rect_1.x -= 5;
                var dst_rect_2 = explosion_node.data.getDstRect();
                dst_rect_2.x -= 10;
                dst_rect_2.y -= 10;
                var dst_rect_3 = explosion_node.data.getDstRect();
                dst_rect_3.y -= 12;

                sdl.renderCopy(renderer, game_texture, &src_rect, &camera.dstRectLens(dst_rect_1));
                sdl.renderCopy(renderer, game_texture, &src_rect, &camera.dstRectLens(dst_rect_2));
                sdl.renderCopy(renderer, game_texture, &src_rect, &camera.dstRectLens(dst_rect_3));
            }
        }

        sdl.renderPresent(renderer);

        {
            var enemy_fighter_opt = enemy_fighters.list.first;
            while (enemy_fighter_opt) |enemy_fighter_node| {
                enemy_fighter_opt = enemy_fighter_node.next;
                var blaster_entity_opt = blaster_entities.list.first;
                while (blaster_entity_opt) |blaster_entity_node| {
                    blaster_entity_opt = blaster_entity_node.next;
                    const blaster_dst_rect = blaster_entity_node.data.getDstRect();
                    const enemy_dst_rect = enemy_fighter_node.data.getDstRect();
                    // check if rects collide
                    if (blaster_dst_rect.x < enemy_dst_rect.x + enemy_dst_rect.w and
                        blaster_dst_rect.x + blaster_dst_rect.w > enemy_dst_rect.x and
                        blaster_dst_rect.y < enemy_dst_rect.y + enemy_dst_rect.h and
                        blaster_dst_rect.y + blaster_dst_rect.h > enemy_dst_rect.y)
                    {
                        if (enemy_fighter_node.data.removed_at == null) {
                            enemy_fighter_node.data.removed_at = frames;

                            try explosions.addEntity(
                                entity_gpa.allocator(),
                                Explosion{
                                    .x_pos = enemy_fighter_node.data.x_pos,
                                    // set explosion y with camera offeset
                                    .y_pos = enemy_fighter_node.data.y_pos,
                                },
                            );
                        }
                    }
                }
            }
        }

        const game_loop_end = sdl.getTicks();

        const game_loop_duration = game_loop_end - game_loop_start;
        const target_game_loop_duration = 16;
        // std.debug.print("Computation time: {d}\n", .{game_loop_duration});

        if (game_loop_duration + 1 < target_game_loop_duration) {
            sdl.delay(target_game_loop_duration - (game_loop_duration + 1));
        }
        const next_total_ticks = sdl.getTicks();
        // const frame_delta = next_total_ticks - total_ticks;
        // std.debug.print("Delta: {d}\n", .{frame_delta});
        total_ticks = next_total_ticks;
    }
}

fn advanceTreadmill(
    cur_arena: *ArenaAllocator,
    nxt_arena: *ArenaAllocator,
    nxt_layers: [][]?StaticTile,
) ![][]?StaticTile {
    _ = cur_arena.reset(ArenaAllocator.ResetMode.retain_capacity);

    var cur_layers = try cur_arena.allocator().alloc([]?StaticTile, nxt_layers.len);
    for (nxt_layers, 0..) |layer, layer_idx| {
        const cur_layer: []?StaticTile = try cur_arena.allocator().alloc(?StaticTile, layer.len);
        @memcpy(cur_layer, nxt_layers[layer_idx]);
        cur_layers[layer_idx] = cur_layer;
    }

    _ = nxt_arena.reset(ArenaAllocator.ResetMode.retain_capacity);

    return cur_layers;
}

fn handleEvent(run: *bool, controls: *Controls) void {
    var ev: sdl.SDL_Event = undefined;

    while (sdl.pollEvent(&ev) != 0) {
        switch (ev.type) {
            sdl.SDL_QUIT => {
                run.* = false;
                break;
            },
            sdl.SDL_KEYDOWN => {
                const key_code = ev.key.keysym.sym;
                controls.handleKeydown(key_code);
            },
            sdl.SDL_KEYUP => {
                const key_code = ev.key.keysym.sym;
                controls.handleKeyup(key_code);
            },
            else => {},
        }
    }
}

const StaticTileSrc: type = struct {
    src_rect: sdl.SDL_Rect,
};

const StaticTile: type = struct {
    src_rect: sdl.SDL_Rect,
    dst_rect: DstRect,
};

const StaticTileMap: type = AutoHashMap(u16, StaticTileSrc);

fn loadStaticTileSrcMap(
    tile_sets: []tiled.TileSet,
    texture_map: *StaticTileMap,
) !void {
    for (tile_sets) |tile_set| {
        var current_gid: u16 = tile_set.firstgid;
        var current_lid: u16 = 0;

        var row: c_int = 0;
        var col: c_int = 0;
        while (current_lid < tile_set.tilecount) {
            const src_rect = sdl.SDL_Rect{
                .x = col * tile_set.tilewidth,
                .y = row * tile_set.tileheight,
                .w = tile_set.tilewidth,
                .h = tile_set.tileheight,
            };

            try texture_map.put(current_gid, StaticTileSrc{
                .src_rect = src_rect,
            });

            current_lid = current_lid + 1;
            current_gid = current_gid + 1;

            col = col + 1;
            if (col == tile_set.columns) {
                col = 0;
                row = row + 1;
            }
        }
    }
}

pub fn loadTiledData(
    rect_alloc: Allocator,
    map_file_path_segments: [2][]const u8,
    camera_opt: ?Camera,
) ![][]?StaticTile {
    var y_offset: f32 = 0;
    if (camera_opt) |camera| {
        y_offset = camera.y_pos - 1;
    }

    var fba_buf: [std.os.PATH_MAX]u8 = undefined;
    var fba = heap.FixedBufferAllocator.init(&fba_buf);

    var tiled_data_arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer tiled_data_arena.deinit();

    const map_file_path = try std.fs.path.join(fba.allocator(), &map_file_path_segments);
    const map_data = try tiled.loadTileMap(tiled_data_arena.allocator(), map_file_path);
    const tile_map: tiled.TileMap = map_data.@"0";
    const tile_sets: []tiled.TileSet = map_data.@"1";

    var texture_map = StaticTileMap.init(rect_alloc);
    try loadStaticTileSrcMap(tile_sets, &texture_map);

    var layers = try rect_alloc.alloc([]?StaticTile, tile_map.layers.len);
    for (tile_map.layers, 0..) |layer, layer_idx| {
        var layer_rects = try rect_alloc.alloc(?StaticTile, layer.data.len);
        layers[layer_idx] = layer_rects;

        var col: u16 = 0;
        var row: u16 = 0;

        for (layer.data, 0..) |tile_gid, tile_idx| {
            defer {
                col = col + 1;
                if (col == tile_map.width) {
                    col = 0;
                    row = row + 1;
                }
            }

            const offset_x: f32 = @floatFromInt(tile_map.tilewidth * col);
            const offset_y: f32 = @floatFromInt(tile_map.tileheight * row);
            const src_rect_opt = texture_map.get(tile_gid);
            if (src_rect_opt) |src_rect| {
                layer_rects[tile_idx] = StaticTile{
                    .src_rect = src_rect.src_rect,
                    .dst_rect = DstRect{
                        .x = offset_x,
                        .y = offset_y + y_offset,
                        .w = @floatFromInt(tile_map.tilewidth),
                        .h = @floatFromInt(tile_map.tileheight),
                    },
                };
                continue;
            }
            layer_rects[tile_idx] = null;
        }
    }

    return layers;
}
