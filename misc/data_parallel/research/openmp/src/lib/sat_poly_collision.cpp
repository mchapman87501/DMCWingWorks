#include "sat_poly_collision.h"
#include "dot_min_max.h"

namespace wingworks {

    double SATPolyCollision::overlap_distance(
        const Particle& particle, const Vector& normal
    ) const
    {
        const DotMinMax p0 = polygon_m.projected_extrema(normal);
        const DotMinMax p1 = particle.projected_extrema(normal);

        // If the minimum of one body is less than the maximum of the other,
        // then the overlap is the smaller of the min/max differences.
        // I think.
        // Need to draw a diagram to see whether this covers the case of
        // one body being completely within the other...
        //
        // Put another way: how far do you need to offset one body so the
        // two no longer overlap?
        const double dist0 = p1.max_m - p0.min_m;
        const double dist1 = p0.max_m - p1.min_m;
        const double min_dist = (dist0 < dist1) ? dist0 : dist1;
        return (min_dist <= 0) ? -1.0 : min_dist;
    }

    // https://www.metanetsoftware.com/technique/tutorialA.html
    // If the objects overlap along all of the possible separating axes,
    // then they are definitely overlapping each other;
    // we've found a collision, and this means we need to determine the
    // **projection vector**, which will push the two objects apart.
    // At this point, we've already done most of the work:
    // each axis is a potential direction along which we can project
    // the objects.
    // So, all we need to do is find the axis with the smallest amount
    // of overlap between the two objects, and we're done --
    // the **direction** of the projection vector is the same as the axis 
    // direction, and the **length** of the projection vector is equal to
    // the size of the overlap along that axis.

    bool SATPolyCollision::find_collision_normal(
        const Particle& particle, Vector& normal_result
    )
    {
        double best_overlap = -1.0;
        Vector best_normal;
        const size_t num_normals = edge_normals_m.size();
        for (size_t i = 0; i < num_normals; ++i) {
            const Vector& curr_normal(edge_normals_m[i]);
            const double curr_overlap = overlap_distance(
                particle, curr_normal);
            if (curr_overlap < 0) {
                return false;
            }

            if ((best_overlap < 0.0) || (curr_overlap < best_overlap)) {
                best_overlap = curr_overlap;
                best_normal = curr_normal;
            }
        }

        // Which polygon vertex is nearest the particle center?
        const Point center = particle.pos();
        const Point nearest = polygon_m.nearest_vertex_to(center);
        Vector normal = nearest.offset(center).normal();
        double curr_overlap = overlap_distance(particle, normal);

        // TODO DRY
        if (curr_overlap < 0.0) {
            return false;
        }
        if ((best_overlap < 0.0) || (curr_overlap < best_overlap)) {
            best_overlap = curr_overlap;
            best_normal = normal;
        }

        if (best_overlap > 0.0) {
            normal_result = best_normal.scaled(best_overlap);
            return true;
        }
        return false;
    }
}
