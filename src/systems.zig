const std = @import("std");
const heap = std.heap;
const Allocator = std.mem.Allocator;
const SinglyLinkedList = std.SinglyLinkedList;
const components = @import("./components.zig");

pub fn EntityPool(
    comptime T: anytype,
    comptime impl: struct {
        isRemovable: components.IsRemovable(T),
    },
) type {
    return struct {
        pub const Self = @This();
        list: SinglyLinkedList(T) = SinglyLinkedList(T){},

        pub fn addEntity(self: *Self, alloc: Allocator, entity: T) !void {
            const next_entity_node = try alloc.create(SinglyLinkedList(T).Node);
            next_entity_node.* = SinglyLinkedList(T).Node{
                .data = entity,
            };
            self.list.prepend(next_entity_node);
        }

        pub fn cleanupEntities(self: *Self, alloc: Allocator, current_game_frame: u32) void {
            var cur_entity_node = self.list.first;
            while (cur_entity_node) |entity_node| {
                cur_entity_node = entity_node.next;

                const removed_at_opt = impl.isRemovable(&entity_node.data).*;

                if (removed_at_opt) |removed_at| {
                    if (current_game_frame > removed_at + (60 * 5)) {
                        self.list.remove(entity_node);
                        alloc.destroy(entity_node);
                    }
                }
            }
        }
    };
}

pub fn AnimateSystem(
    comptime T: anytype,
    comptime impl: struct {
        hasAnimation: components.HasAnimation(T),
    },
) type {
    return struct {
        pub fn onTick(self: *T) void {
            const data = impl.hasAnimation(self);

            const current_ticks = data.current_ticks.*;
            data.current_ticks.* = current_ticks + 1;

            if (current_ticks + 1 >= data.ticks_per_frame) {
                data.current_ticks.* = 0;
                const current_frame_idx = data.current_frame_idx.*;
                data.current_frame_idx.* = current_frame_idx + 1;

                if (current_frame_idx + 1 >= data.frames.len) {
                    data.current_frame_idx.* = 0;
                }
            }
        }
    };
}
