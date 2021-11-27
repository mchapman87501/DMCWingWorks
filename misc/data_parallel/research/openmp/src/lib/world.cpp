#include "world.h"

#include <random>
#include <iostream>
#include <sstream>

#include <omp.h>

#include "sat_poly_collision.h"
#include "airfoil_collision.h"
#include "particle.h"
#include "point.h"


namespace {
    static std::random_device rd;  // Provides seed for random number engine
    static std::mt19937 gen(rd()); // Standard mersenne_twister_engine
}
namespace wingworks {
    // Use a little secret knowledge of particle size to calculate max number
    // of particles without overlap.  Assume square grid rather than hex
    // packing.  Assume no airfoil.
    // Apply an over-density fudge factor (FF).
    const double ff = 10.0;

    World::World(
        const Airfoil& foil,
        const double width, const double height,
        const double max_particle_speed, const Vector& wind_vel
    )
    : airfoil_m(foil)
    , world_width_m(width)
    , world_height_m(height)
    , num_particles_m(width * height * ff)  // Particle radius: 0.5
    , max_speed_m(max_particle_speed)
    , wind_vel_m(wind_vel)
    , cells_m(width, height, 1.0)  // Particle radius == 0.5
    , world_bbox_m(0.0, 0.0, width, height)
    {
        std::cout << "Number of particles: " << num_particles_m << std::endl;
        particles_m = new Particle[num_particles_m];
        reset_force_on_foil();
        randomize();
    }

    World::~World() {
        delete [] particles_m;
    }
    
    void World::randomize() {
        std::uniform_real_distribution<> sxrand(0.0, world_width_m);
        std::uniform_real_distribution<> syrand(0.0, world_height_m);
        
        std::uniform_real_distribution<> vrand(-max_speed_m, max_speed_m);

        for (size_t i = 0; i < num_particles_m; ++i) {
            double x = sxrand(gen);
            double y = syrand(gen);
            while (airfoil_m.shape().contains(Point(x, y))) {
                x = sxrand(gen);
                y = syrand(gen);
            }
            particles_m[i].move_to(x, y);

            // Get a random particle speed, with added wind.
            const Vector vel(
                wind_vel_m
                .adding(Vector(vrand(gen), vrand(gen))
                .unit().scaled(max_speed_m)));
            particles_m[i].set_vel(vel.x(), vel.y());
        }
    }

    void World::recycle(Particle& p, size_t index) {
        std::uniform_real_distribution<> syrand(0.0, world_height_m);
        std::uniform_real_distribution<> vrand(-max_speed_m, max_speed_m);

        // TODO try just wrapping around, with a little randomzation.
        // Depending on wind vel a particle may flow out the top, bottom,
        // or right side of the world stage.
        double x = p.pos_x();
        while (x < 0) {
            x += world_width_m;
        }
        while (x > world_width_m) {
            x -= world_width_m;
        }
        double y = syrand(gen);
        while (airfoil_m.shape().contains(Point(x, y))) {
            y = syrand(gen);
        }
        const double vx = vrand(gen) + wind_vel_m.x();
        const double vy = vrand(gen) + wind_vel_m.y();
        p.move_to(x, y);
        p.set_vel(vx, vy);
    }

    // As in Swift version, divide the world into subregions.  Fewer particles
    // per region makes less work than full pairwise collision test:
    // k * O(M**2) < O(N**2) when M << N.
    //
    // Change from Swift implementation: Use the grid sizing strategy outlined
    // by NVidia, here:
    // https://developer.download.nvidia.com/assets/cuda/files/particles.pdf
    // Apparently it's pretty common.
    void World::assign_to_cells() {
        cells_m.clear();
        for (size_t i = 0; i < num_particles_m; ++i) {
            cells_m.add(particles_m[i], i);
        }
    }

    // This has a bug: it allows two particles to collide repeatedly,
    // once for each cell that they share.
    void World::collide_cell_particles(const Cell& cell) {
        const size_t num_particles = cell.size();
        
        const size_t *raw_cell = cell.data();
        #pragma omp target teams distribute parallel for
        for (size_t i = 0; i < num_particles; ++i) {
            Particle& p_i = particles_m[raw_cell[i]];
            for (size_t j = i + 1; j < num_particles; ++j) {
                Particle& p_j = particles_m[raw_cell[j]];
                if (p_i.is_colliding_with(p_j)) {
                    #pragma omp critical
                    p_i.collide_with(p_j);
                }
            }
        }
    }

    void World::collide_particles() {
        for (size_t i_cell = 0; i_cell < cells_m.size(); ++i_cell) {
            const Cell& cell = cells_m.cell(i_cell);
            // What if two particles appear together in multiple cells,
            // thus colliding multiple times?
            collide_cell_particles(cell);
        }
    }

    void World::collide_with_airfoil() {
        AirfoilCollision collider(airfoil_m);

        #pragma omp parallel for
        for (size_t i = 0; i < num_particles_m; ++i) {
            Particle& particle(particles_m[i]);
            Vector recoil_vec;
            // Each loop iteration mutates only one particle,
            // and depends on no mutable state.  So I think no
            // critical section is needed here.
            if (collider.is_colliding(particle, recoil_vec)) {
                    particle.move_to(particle.pos().adding(recoil_vec));
                    const Vector impulse = collider.resolve_collision(
                            particle, recoil_vec);
                    #pragma omp critical
                    {
                        net_force_on_foil_m.add(impulse);
                    }                        
            }
        }
    }

    void World::integrate() {
        #pragma omp parallel for
        for (size_t i = 0; i < num_particles_m; ++i) {
            Particle& p(particles_m[i]);
            p.integrate();
            if (is_out_of_world(p)) {
                recycle(p, i);
            }
        }
    }

    bool World::is_out_of_world(const Particle& p) const {
        return !world_bbox_m.contains(p.pos());
    }

    // These belong somewhere else...
    void World::write_particle_positions(std::ostream& outs) const {
        // Positions, positions + velocities... whatever
        outs << "X,Y,VX,VY" << std::endl;
        for (size_t i = 0; i < num_particles_m; ++i) {
            const Particle& p(particles_m[i]);
            Point pos(p.pos());
            Point vel(p.vel());
            outs << pos.x() << "," << pos.y() << ","
                 << vel.x() << "," << vel.y()
                 << std::endl;
        }
    }

    void World::write_force_on_foil(std::ostream& outs) const {
        outs 
            << "X,Y" << std::endl
            << net_force_on_foil_m.x() << "," << net_force_on_foil_m.y() << std::endl;
    }
}