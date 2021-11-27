#pragma once

#include <cstdlib>
#include <random>
#include <iostream>

#include "vector.h"
#include "particle.h"
#include "world_cells.h"
#include "airfoil.h"
#include "bbox.h"

namespace wingworks {

class World {
public:
    World(
        const Airfoil& foil,
        const double width, const double height, 
        const double max_particle_speed,
        const Vector& wind_vel
    );
    ~World();

    void step() {
        assign_to_cells();
        collide_particles();
        collide_with_airfoil();
        integrate();
    }

    const Vector& force_on_foil() const {
        return net_force_on_foil_m;
    }
    void reset_force_on_foil() {
        net_force_on_foil_m.update(0.0, 0.0);
    }

    double momentum() const {
        double result = 0.0;
        for (size_t i = 0; i < num_particles_m; ++i) {
            result += particles_m[i].momentum();
        }
        return result;
    }

    void write_particle_positions(std::ostream& outs) const;
    void write_force_on_foil(std::ostream& outs) const;

private:
    Airfoil airfoil_m;
    const double world_width_m;
    const double world_height_m;

    const size_t num_particles_m;

    const double max_speed_m;  // ignoring wind, maximum speed

    const Vector wind_vel_m;

    Particle *particles_m;
    WorldCells cells_m;
    const BBox world_bbox_m;
    Vector net_force_on_foil_m;

    void randomize();
    // Recycle a particle -- bring it back into the world.
    void recycle(Particle& p, size_t index);

    bool is_out_of_world(const Particle& p) const;

    void assign_to_cells();
    void collide_cell_particles(const Cell& cell);    
    void collide_particles();
    void collide_with_airfoil();
    void integrate();
};

}