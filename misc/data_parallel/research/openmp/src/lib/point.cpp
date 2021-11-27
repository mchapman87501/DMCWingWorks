#include "point.h"
#include <sstream>

namespace wingworks {
    Point Point::unit() const {
        Point result;

        const double m = magnitude();
        if (m > 0) {
            result.x_m = x_m / m;
            result.y_m = y_m / m;
        }
        return result;
    }

    std::string Point::to_str() const {
        std::ostringstream outs;
        outs << "(" << x_m << ", " << y_m << ")";
        return outs.str();
    }
}
