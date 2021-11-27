pub mod world {
    use rand::{thread_rng, Rng};

    use rayon::prelude::*;

    use crate::particle::particle::Particle;
    use crate::vec2d::vec2d::Vec2D;
    use std::sync::{Mutex, Arc};

    pub struct World {
        air: Vec<Particle>,
    }

    impl World {
        pub fn new(size: i32) -> World {
            let mut air = Vec::new();
            let mut rng = thread_rng();
            // Should/could one use multiple thread-local RNGs?

            for _ in 0..size {
                // Random position, random velocity.
                let x = rng.gen_range(0.0, 5000.0);
                let y = rng.gen_range(0.0, 5000.0);
                let vx = rng.gen_range(-1000.0, 1000.0);
                let vy = rng.gen_range(-1000.0, 1000.0);
                let s = Vec2D::new(x, y);
                let v = Vec2D::new(vx, vy);
                let particle = Particle::new(&s, &v);

                air.push(particle);
            }
            World{air: air}
        }

        fn do_collisions(&mut self) -> Vec<Particle> {
            // To avoid contention:
            // Detect collisions in self.air.
            // Perform collisions in a copy of self.air.
            let new_air_mux = Arc::new(Mutex::new(self.air.clone()));
            let air = &self.air;
            let num_particles = air.len();
            (0..num_particles).into_par_iter().for_each(|i| {
                ((i + 1)..num_particles).into_par_iter().for_each(|j| {
                    if air[i].is_colliding(&air[j]) {
                        let mut new_air = new_air_mux.lock().unwrap();
                        let mut p1 = new_air[j].clone();
                        new_air[i].collide_with(&mut p1);
                        new_air[j] = p1;
                    }
                });
            });
            return new_air_mux.lock().unwrap().to_owned();
        }

        pub fn print_col_headers(&self) {
            println!("Index,X,Y");
        }

        pub fn print_positions(&self, index: usize) {
            for particle in &self.air {
                let pos = &particle.s;
                println!("{},{},{}", index, pos.x, pos.y);
            }
        }

        pub fn update_positions(&mut self) {
            let mut new_air = self.do_collisions();
            new_air.par_iter_mut().for_each(|p| p.update_position());
            self.air = new_air;
        }

        pub fn print_position_headers(&self) {
            println!("Iteration,X,Y")
        }

    }
}