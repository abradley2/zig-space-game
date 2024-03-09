const std = @import("std");
const rand = std.rand;

const Spawner = @This();

age: u32 = 0,
last_spawn: u32 = 0,

const spawn_rate: u32 = 5;
var rand_impl = rand.DefaultPrng.init(42);

pub const Event: type = union(enum) {
    spawn_fighter: f32,
};

pub fn onTick(self: *Spawner, event_slots: [*]Event) []Event {
    var event_idx: usize = 0;

    self.age = self.age + 1;

    if (self.age - self.last_spawn > spawn_rate) {
        const fighter_spawn = rand_impl.random().intRangeAtMost(u32, 0, 460);
        const fighter_spawn_x: f32 = @floatFromInt(fighter_spawn);
        event_slots[event_idx] = Event{ .spawn_fighter = fighter_spawn_x };

        self.last_spawn = self.age;
        event_idx += 1;
    }

    return event_slots[0..event_idx];
}
