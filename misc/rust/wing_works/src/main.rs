use DMCWingWorks::world::world::World;

fn main() {
    let mut world = World::new(200000);
    world.print_position_headers();
    for index in 0..10 {
        world.print_positions(index + 1);
        world.update_positions();
    }
}