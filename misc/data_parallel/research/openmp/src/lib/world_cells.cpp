#include "world_cells.h"

namespace wingworks {

    void WorldCells::clear() {
        #pragma omp parallel for
        for (size_t i = 0; i < num_cells_m; ++i) {
            cells_m[i].clear();
        }
    }

    void WorldCells::add(const Particle& particle, const size_t particle_index) {
        // Assign the particle to any cell with which it overlaps.
        const double x(particle.pos_x());
        const double y(particle.pos_y());
        const double r(particle.radius());
        const double x_coords[3] {x - r, x, x + r};
        const double y_coords[3] {y - r, y, y + r};

        for (size_t iy = 0; iy < 3; ++iy) {
            const double y_curr = y_coords[iy];
            const double i_cell_row = y_curr / cell_extent_m; // Truncate.
            const size_t row_offset = i_cell_row * num_horiz_m;

            for (size_t ix = 0; ix < 3; ++ix) {
                const double x_curr = x_coords[ix];
                const double i_cell_col = x_curr / cell_extent_m;
                const size_t cell_index = row_offset + i_cell_col;

                if (0 <= cell_index && cell_index < num_cells_m) {
                    cells_m[cell_index].push_back(particle_index);
                }
            }
        }
    }

} // namespace