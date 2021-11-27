#include <iostream>
#include <iomanip>
#include <sstream>
#include <fstream>

#include <chrono>

#include <vector>
#include <cmath>
#include <cstring>
#include <algorithm>
#include <stdexcept>
#include <random>

#include "point.h"
#include "particle.h"
#include "airfoil.h"
#include "world.h"

using namespace std;
using namespace wingworks;
using namespace std::chrono;

namespace {
    void write_airfoil_shape(std::ostream& outs, const Airfoil& airfoil) {
        outs << "X,Y" << std::endl;
        auto vertices = airfoil.shape().vertices();
        for (const auto& p : vertices) {
            outs << p.x() << "," << p.y() << std::endl;
        }
    }

    void write_airfoil(const Airfoil& airfoil) {
        ofstream outf("airfoil.csv");
        write_airfoil_shape(outf, airfoil);
        outf.close();
    }

    string foil_force_file_name(const size_t step_num) {
        ostringstream outs;
        outs << "net_force_" << setfill('0') << setw(4) << step_num << ".csv";
        return outs.str();
    }

    void write_foil_forces(const size_t step_num, const World& world) {
        ofstream outf(foil_force_file_name(step_num));
        world.write_force_on_foil(outf);
        outf.close();
    }

    string pos_file_name(const size_t step_num) {
        ostringstream outs;
        outs << "positions_" << setfill('0') << setw(4) << step_num << ".csv";
        return outs.str();
    }

    void write_positions(const size_t step_num, const World& world) {
        ofstream outf(pos_file_name(step_num));
        world.write_particle_positions(outf);
        outf.close();
    }
}

int main(int argc, char **argv) {
    const double world_width = 128.0;
    const double world_height = 72.0;

    const double aoa_rad = 10.0 * M_PI / 180.0;
    const Airfoil airfoil(
        world_width / 8.0, world_height / 2.0,
        world_width / 4.0,
        aoa_rad
    );
    write_airfoil(airfoil);

    const double max_particle_speed = 0.0005;
    const Point wind_vel = Point(0.11, 0.0);

    World world(
        airfoil, world_width, world_height, max_particle_speed, wind_vel);

    Vector total_foil_force;


    const size_t movie_seconds = 20;
    const size_t fps = 30;
    const size_t steps_per_frame = 10;

    size_t index = 0;
    double mv_prev = 0.0;
    steady_clock::time_point t0 = steady_clock::now();
    for (size_t sec = 1; sec <= movie_seconds; ++sec) {
        for (size_t iframe = 1; iframe <= fps; iframe++) {
            for (size_t istep = 1; istep <= steps_per_frame; ++istep) {
                world.step();
            }

            index += 1;
            write_positions(index, world);

            write_foil_forces(index, world);
            total_foil_force.add(world.force_on_foil());

            world.reset_force_on_foil();

            steady_clock::time_point tf = steady_clock::now();
            duration<double> dt = duration_cast<duration<double>>(tf - t0);
            t0 = tf;

            const double mv = world.momentum();
            const double dmv = mv - mv_prev;
            mv_prev = mv;

            cout
                << sec << "." << iframe << "/" << movie_seconds 
                << ": net mv = " << mv
                << ", Δmv = " << dmv
                << "; dt = " << dt.count() << " seconds"
                << endl;
        }
    }
    // The direction of the force is backwards, hence the scale:
    cout
        << "Summed force on foil: "
        << total_foil_force.scaled(-1.0).to_str() << endl;
    return 0;
}
