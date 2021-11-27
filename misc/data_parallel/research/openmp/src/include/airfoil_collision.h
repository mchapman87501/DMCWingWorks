#pragma once

#include "particle.h"
#include "vector.h"
#include "airfoil.h"
#include "sat_poly_collision.h"

namespace wingworks {

class AirfoilCollision {
private:
    const Airfoil& foil_m;

public:
    // Bit of a lifetime issue, there...
    AirfoilCollision(const Airfoil& foil)
    : foil_m(foil) {

    }

    bool is_colliding(const Particle& particle, Vector& recoil_vec_result);
    
    Vector resolve_collision(Particle& particle, Vector& recoil_vec) const;
    double accel_from_foil(const Particle& particle, const Vector& normal) const;
};

}