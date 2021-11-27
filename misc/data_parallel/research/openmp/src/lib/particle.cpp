#include "particle.h"
#include <cmath>
#include <stdexcept>
#include <iostream>

namespace wingworks {
    void Particle::collide_with(Particle& other) {
        Point v_new;
        Point other_v_new;
        resolve_collision_with(other, v_new, other_v_new);

        vel_m = v_new;
        other.vel_m = other_v_new;
    }

    void Particle::resolve_collision_with(
        const Particle& other, Point& v_result, Point& other_v_result
    ) const {
        Point n = pos_m.offset(other.pos_m).unit();
        const double jr = calc_impulse_with(other, n);
        v_result = vel_m.offset(n.scaled(-jr / mass_m));
        other_v_result = other.vel_m.offset(n.scaled(jr / other.mass_m));
    }

    double Particle::calc_impulse_with(const Particle& other, const Point& normal) const {
        // e is the coefficient of restitution.  Set to 1 for
        // a perfectly elastic collision, I think.
        const double e = 1.0;
        // Relative collision velocity:
        const Point vr = vel_m.offset(other.vel_m);
        const double numer = -(1.0 + e) * vr.dot(normal);

        // Ignore rotational inertia
        const double denom = (1.0 / mass_m) + (1.0 / other.mass_m);

        return numer / denom;
    }
}