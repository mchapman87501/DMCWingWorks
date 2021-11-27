#pragma once

#include <cmath>
#include "point.h"
#include "vector.h"

namespace wingworks {
class Segment {
private:
    Point p0_m;
    Point pf_m;

public:
    Segment(const Point& p0, const Point& pf)
    : p0_m(p0), pf_m(pf)
    {}

    // Find out whether this Segment extends upward from p0 to pf,
    // crossing the given y coordinate.
    bool crosses_upward(double y) const {
        const double y0 = p0_m.y();
        const double yf = pf_m.y();
        return ((y0 < yf) && (y0 <= y) && (y < yf));
    }

    // Find out whether this Segment extends downward from p0 to pf,
    // crossing the given y coordinate.
    bool crosses_downward(double y) const {
        const double y0 = p0_m.y();
        const double yf = pf_m.y();
        return ((y0 > yf) && (yf <= y) && (y < y0));
    }

    // Assuming this Segment is not horizontal,
    // Get the x coordinate at which this segment crosses
    // the y coordinate of a point.
    double x_intersect(const Point& p) const {
        const double dy = pf_m.y() - p0_m.y();
        const double dx = pf_m.x() - p0_m.x();

        // If the line is nearly vertical, pretend the intersection
        // lies to the left of the point.
        if (::abs(dx) < 1.0e-6) {
            return p.x() - 1.0;
        }
        // What to do if the line is nearly horizontal?

        const double dy_fract = (p.y() - p0_m.y()) / dy;
        const double result = p0_m.x() + dy_fract * dx;
        return result;
    }

    // Get this segment as a "vector" -- a direction and distance
    // relative to the origin.
    Vector as_vector() const {
        return Vector(pf_m.x() - p0_m.x(), pf_m.y() - p0_m.y());
    }
};

} // namespace