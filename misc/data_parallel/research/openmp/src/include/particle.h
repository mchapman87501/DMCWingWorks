#pragma once
#include "point.h"
#include "vector.h"
#include "bbox.h"
#include "dot_min_max.h"

namespace wingworks {
    class Particle {
    private:
        const double mass_m = 1.0;
        const double radius_m = 0.5;

        Point pos_m;
        Point vel_m;

    public:
        Particle(){}
        Particle(const Particle& src)
        : pos_m(src.pos_m), vel_m(src.vel_m) {}

        void move_to(const double x, const double y) {
            pos_m.update(x, y);
        }

        void move_to(const Point& p) {
            pos_m = p;
        }

        void set_vel(const double vx, const double vy) {
            vel_m.update(vx, vy);
        }

        void accelerate(const Vector& a) {
            vel_m.add(a);
        }

        double dist_sqr(const Particle& other) const {
            return pos_m.dist_sqr(other.pos_m);
        }

        bool is_colliding_with(const Particle& other) const {
            const double coll_dist = radius_m + other.radius_m;
            return pos_m.dist_sqr(other.pos_m) <= (coll_dist * coll_dist);
        }

        const BBox bbox() const {
            const double x = pos_m.x();
            const double y = pos_m.y();
            return BBox(x - radius_m, y - radius_m, x + radius_m, y + radius_m);
        }

        /**
         * Find the new velocities of two particles after they have collided.
         */
        void resolve_collision_with(
            const Particle& other, Point& v_result, Point& other_v_result
        ) const;

        /**
         * Collide with another particle, updating velocities of both.
         */
        void collide_with(Particle& other);

        /**
         * Update position based on velocity.
         */
        void integrate() {
            pos_m.add(vel_m);
        }

        double mass() const { return mass_m; }
        double radius() const { return radius_m; }
        double pos_x() const { return pos_m.x(); }
        double pos_y() const { return pos_m.y(); }
        const Point& pos() const { return pos_m; }
        const Point& vel() const { return vel_m; }

        double momentum() const { return mass_m * vel().magnitude(); }

        DotMinMax projected_extrema(const Vector& unit_vec) const {
            const double center_dot = pos_m.dot(unit_vec);
            return DotMinMax(center_dot - radius_m, center_dot + radius_m);
        }

    private:
        double calc_impulse_with(const Particle& other, const Point& normal) const;
    };
}