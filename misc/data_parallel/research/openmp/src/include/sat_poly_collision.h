#pragma once

#include<vector>

#include "particle.h"
#include "vector.h"
#include "polygon.h"

namespace wingworks {

// SATPolyCollision calculates collisions between points
// and polygons, using the Separated Axis Theorem.
class SATPolyCollision {
private:
    // More memory management issues -- control yer scopes.
    const Polygon& polygon_m;
    const std::vector<Vector>& edge_normals_m;

    double overlap_distance(const Particle& particle, const Vector& normal) const;
public:
    SATPolyCollision(const Polygon& poly)
    : polygon_m(poly)
    , edge_normals_m(poly.edge_normals())
    {

    }

    // Find the normal vector for a collision between a particle and a vector.
    // If there is a collision, the normal is stored in normal_result and
    // the method returns true.  Otherwise the method returns false.
    bool find_collision_normal(
        const Particle& particle, Vector& normal_result);
};

}