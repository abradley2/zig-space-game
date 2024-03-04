const std = @import("std");
const fs = std.fs;
const json = std.json;
const Allocator = std.mem.Allocator;

pub const Layer = struct {
    data: []u16,
    visible: bool,
};

pub const TileSet = struct {
    firstgid: u16 = 0,
    columns: u16,
    image: [:0]const u8,
    imageheight: u16,
    imagewidth: u16,
    margin: u16,
    name: []const u8,
    spacing: u16,
    tilecount: u16,
    tileheight: u16,
    tilewidth: u16,
};

pub const TileSetRef = struct {
    firstgid: u16,
    source: []const u8,
};

pub const TileMap = struct {
    height: u16,
    width: u16,
    tileheight: c_int,
    tilewidth: c_int,
    layers: []Layer,
    tilesets: []TileSetRef,
};

fn readFile(alloc: Allocator, file_path: []const u8) ![]const u8 {
    const buf = try fs.cwd().readFileAlloc(
        alloc,
        file_path,
        1024 * 64,
    );
    return buf;
}

pub fn loadTileMap(
    alloc: Allocator,
    file_path: []const u8,
) !struct {
    TileMap,
    []TileSet,
} {
    const tile_map_bytes = try readFile(
        alloc,
        file_path,
    );

    const tile_map = try std.json.parseFromSliceLeaky(
        TileMap,
        alloc,
        tile_map_bytes,
        .{ .ignore_unknown_fields = true },
    );

    var tile_sets = try alloc.alloc(TileSet, tile_map.tilesets.len);

    const file_dir = std.fs.path.dirname(file_path) orelse unreachable;

    for (tile_map.tilesets, 0..) |tileset_metadata, idx| {
        const tile_set_path_segments: [2][]const u8 = .{ file_dir, tileset_metadata.source };
        const tile_set_path = try fs.path.join(
            alloc,
            &tile_set_path_segments,
        );

        const tile_set = try loadTileset(
            alloc,
            tileset_metadata.firstgid,
            tile_set_path,
        );

        tile_sets[idx] = tile_set;
    }

    return .{ tile_map, tile_sets };
}

pub fn loadTileset(
    alloc: Allocator,
    firstgid: u16,
    file_name: []const u8,
) !TileSet {
    const tile_set_dir = std.fs.path.dirname(file_name) orelse unreachable;

    const tile_set_bytes = try readFile(
        alloc,
        file_name,
    );

    var tile_set = try std.json.parseFromSliceLeaky(
        TileSet,
        alloc,
        tile_set_bytes,
        .{ .ignore_unknown_fields = true },
    );

    const tile_set_image_path_segments: [2][]const u8 = .{
        tile_set_dir,
        tile_set.image,
    };

    tile_set.image = try fs.path.joinZ(
        alloc,
        &tile_set_image_path_segments,
    );
    tile_set.firstgid = firstgid;

    return tile_set;
}
