#pragma once
#include <cstdlib>
#include <cmath>
#include <vector>
#include <stdexcept>
#include <sstream>
#include <iostream>

#include "particle.h"

namespace wingworks {
// 2D: should be more like 4, with extras for adding particles
// that really belong to up to 8 neighbors.
// A problem: particles may be randomized in such a way that they overlap.
const static size_t max_particles_per_cell = 128; 

using Cell = std::vector<size_t>;

class WorldCells {
private:
    double cell_extent_m;
    size_t num_horiz_m;
    size_t num_vert_m;
    size_t num_cells_m;
    Cell *cells_m;

public:
    WorldCells(
        const double world_width, const double world_height,
        const double cell_extent)
    {
        cell_extent_m = cell_extent;
        num_horiz_m = ::ceil(world_width / cell_extent);
        num_vert_m = ::ceil(world_height / cell_extent);
        num_cells_m = num_horiz_m * num_vert_m;
        cells_m = new Cell[num_cells_m];
    }

    ~WorldCells() {
        delete [] cells_m;
    }

    void clear();
    void add(const Particle& particle, const size_t particle_index);
    size_t size() const { return num_cells_m; }

    const Cell& cell(size_t cell_index) const {
        if (cell_index >= num_cells_m) {
            throw std::invalid_argument("Cell index is out of range.");
        }
        return cells_m[cell_index];
    }
};

}