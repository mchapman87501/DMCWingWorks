#include "airfoil_collision.h"

namespace wingworks {
    bool AirfoilCollision::is_colliding(const Particle& particle, Vector& recoil_vec_result) {
        const Polygon& shape(foil_m.shape());

        SATPolyCollision collider(shape);
        return collider.find_collision_normal(particle, recoil_vec_result);
    }

    Vector AirfoilCollision::resolve_collision(
        Particle& particle, Vector& recoil_vec
    ) const
    {
        particle.move_to(particle.pos().adding(recoil_vec));
        Vector n = recoil_vec.unit();
        double accel_mag = accel_from_foil(particle, n);
        Vector particle_accel = n.scaled(-accel_mag);
        particle.accelerate(particle_accel);
        return particle_accel.scaled(particle.mass());
    }

    double AirfoilCollision::accel_from_foil(
        const Particle& particle, const Vector& normal
    ) const
    {
            // e is the coefficient of restitution.  Set to 1 for
            // a perfectly elastic collision, I think.
            const double e = 1.0;
            // Relative collision velocity:
            Vector vr = foil_m.vel().offset(particle.vel());
            // Ignore rotational inertia.  Treat the airfoil as
            // being infinitely massive.
            return -(1.0 + e) * vr.dot(normal);
    }
}