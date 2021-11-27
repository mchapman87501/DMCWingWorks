#include <iostream>
#include <sstream>
#include <assert.h>
#include <cmath>

#include "particle.h"

using namespace std;
using namespace wingworks;


void test_part_coll_1() {
    Particle p1;
    Particle p2;

    assert(p1.pos_x() == 0.0);
    assert(p1.pos_y() == 0.0);
    p1.set_vel(0.01, 0.0);

    p2.move_to(0.5, 0.0);
    // Symmetric speeds:
    p2.set_vel(-0.01, 0.0);

    p1.collide_with(p2);

    cout << "After collision, particle 1 vel: " << p1.vel().to_str() << endl
        << "particle 2 vel: " << p2.vel().to_str() << endl;
    assert(p1.vel().x() == -p2.vel().x());
    // Without a test framework it's hard to test for approximate equality.
    assert(p1.vel().x() <= -0.009);

    assert(p1.vel().y() == 0.0);
    assert(p2.vel().y() == 0.0);
}

bool eq(const double v1, const double v2, const double eps_fract = 1.0e-6) {
    const double dv = ::abs(v1 - v2);
    const double av1 = ::abs(v1);
    const double av2 = ::abs(v2);
    const double denom = (av1 < av2) ? av1 : av2;
    return (dv / denom) <= eps_fract;
}

void test_steady_speed() {
    Particle p1;
    p1.move_to(0.0, 0.0);
    const double dx = 0.1;
    const size_t num_steps = 10;

    p1.set_vel(dx, 0.0);
    for (size_t i = 0; i < num_steps; ++i) {
        p1.integrate();
    }
    assert(p1.vel().x() == dx);
    cout << "After integration, particle position: " << p1.pos().to_str() << endl;
    const double expected = num_steps * dx;
    assert(eq(p1.pos().x(), expected));
}

void test_conserve_momentum() {
    Particle p1;
    Particle p2;

    p1.move_to(0.0, 0.0);
    p2.move_to(0.0, 1.0);

    p1.set_vel(0.0, 1.0);
    p2.set_vel(0.0, -1.0);

    const double mv0 = p1.momentum() + p2.momentum();
    // Repeatedly collide, always from the same relative position.
    for (size_t i = 0; i < 10; ++i) {
        p1.collide_with(p2);
        p1.integrate();
        p2.integrate();
        p1.move_to(0.0, 0.0);
        p2.move_to(0.0, 1.0);
    }

    const double mvf = p1.momentum() + p2.momentum();
    assert(eq(mv0, mvf));
}

string vel_lines(const Particle& particle) {
    const Point& p(particle.pos());
    const Point& v(particle.vel());

    ostringstream outs;
    outs << "[" << p.x() << ", " << p.x() + v.x() << "], "
         << "[" << p.y() << ", " << p.y() + v.y() << "]";
    return outs.str();
}

string pos_point(const Particle& particle) {
    const Point& p(particle.pos());

    ostringstream outs;
    outs << "[" << p.x() << "], "
         << "[" << p.y() << "]";
    return outs.str();

}

string plot_msg(
    const Particle& part1, const Particle& part2,
    const string& name, const string& symbol,
    const string& color1, const string& color2
)
{
    ostringstream outs;
    outs
        << "plt.plot(" << pos_point(part1) << ", '" << symbol << "', color='" << color1 << "', label='" << name << " p1')" << endl
        << "plt.plot(" << vel_lines(part1) << ", '-', color='" << color1 << "', label=None)" << endl
        << "plt.plot(" << pos_point(part2) << ", '" << symbol << "', color='" << color2 << "', label='" << name << " p2')" << endl
        << "plt.plot(" << vel_lines(part2) << ", '-', color='" << color2 << "', label=None)" << endl
    ;
    return outs.str();
}

string extra_plots(const Particle& p1, const Particle& p2) {
    ostringstream outs;

    const Point pos1 = p1.pos();
    const Point vrel = p1.vel().offset(p2.vel());
    // The "normal" to the collision:  the unit vector of relative
    // particle positions:
    const Point n = p1.pos().offset(p2.pos()).unit();

    const double vrdot = vrel.dot(n);

    outs
        << "plt.plot([" << pos1.x() << ", " << pos1.x() + vrel.x() << "]"
        << ", [" << pos1.y() << ", " << pos1.y() + vrel.y() << "]"
        << ", ':', label='v_rel (v·n = " << vrdot << ")')"
        << endl

        << "plt.plot([" << pos1.x() << ", " << pos1.x() + n.x() << "]"
        << ", [" << pos1.y() << ", " << pos1.y() + n.y() << "]"
        << ", '-.', label='normal')"
        << endl;

    return outs.str();
}

bool tcmv2_case(size_t index, const double x, const double y) {
    Particle p1;
    Particle p2;

    p1.move_to(x, y);
    p2.move_to(0.0, 0.0);

    p1.set_vel(0.5, 0.5);
    p2.set_vel(0.5, -0.5);

    const double mv0 = p1.momentum() + p2.momentum();

    const string initial_plot_msg = plot_msg(p1, p2, "Initial", ".", "blue", "red");

    ostringstream test_name;
    // Compose the test name as a Python matplotlib code fragment.
    test_name << index << ": " << x << ", " << y;

    string annotations = extra_plots(p1, p2);

    const bool collision = p1.is_colliding_with(p2);
    if (collision) {
        p1.collide_with(p2);
    }
    const double mv = p1.momentum() + p2.momentum();
    bool success = eq(mv, mv0);
    if (!success) {
        cout << endl << "# FAIL " << test_name.str() << endl
             << "f = plt.figure()" << endl
             << initial_plot_msg << endl
             << plot_msg(p1, p2, "Final", "o", "cyan", "magenta") << endl
             << annotations
             << "plt.legend(loc='upper right')" << endl
             << "f.savefig('fail_" << index << ".png')" << endl
             << "plt.close('all')" << endl
             << "#   Δmv: " << (mv - mv0) << " (" << mv0 << " -> " << mv << ")"
                << (collision ? ", Collision" : "") << endl;
    } else {
        cout << "# PASS " << test_name.str() << endl;
    }
    return success;
}

void test_conserve_mv_2() {
    bool success = true;
    cout << "import matplotlib.pyplot as plt" << endl;
    size_t i = 0;
    for (double x = 0.0; x < 2.0; x += 0.1) {
        for (double y = -1.0; y < 1.0; y += 0.25) {
            if (!tcmv2_case(i, x, y)) {
                success = false;
            }
            i += 1;
        }
    }                  
    assert(success);
}

int main(int, char**) {
    test_part_coll_1();
    test_steady_speed();
    test_conserve_momentum();
    test_conserve_mv_2();
    return 0;
}