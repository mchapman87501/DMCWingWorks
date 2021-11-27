#include "airfoil.h"

#include <vector>
#include "point.h"

namespace {
    using namespace std;
    using namespace wingworks;

    vector<Point> get_vertex_coords(
        const double left, const double bottom, const double width,
        const double aoa_rads
    )
    {
        struct C {
            double x, y;
            C(double xin, double yin): x(xin), y(yin) {}
        };

        // These coordinates need to be proportionally scaled and offset
        // to create a shape with its origin at (left, bottom) and with the
        // given width.
        vector<C> raw_coords {
            C(0.0, 0.0),
            C(0.2, 0.3),
            C(0.4275, 0.5),
            C(1.0, 0.7),
            C(1.75, 0.87),
            C(2.5, 0.9),
            C(4.25, 0.7),
            C(10.0, -0.7),
            C(5.0, -0.55),
            C(1.25, -0.35),
            C(0.4275, -0.3),
            C(0.2, -0.2),
        };

        vector<Point> result;

        vector<double> xvals;
        vector<double> yvals;
        for (const C& vertex : raw_coords) {
            xvals.push_back(vertex.x);
            yvals.push_back(vertex.y);
        }

        const double xmin = *::min_element(xvals.begin(), xvals.end());
        const double xmax = *::max_element(xvals.begin(), xvals.end());
        const double ymin = *::min_element(yvals.begin(), yvals.end());

        // Clockwise, not ccw
        const double caoa = ::cos(-aoa_rads);
        const double saoa = ::sin(-aoa_rads);

        const double mag = xmax - xmin;
        const double scale = width;
        vector<Point> scaled_coords;
        for (const C& v : raw_coords) {
            const double xnorm = (v.x - xmin) / mag;
            const double ynorm = (v.y - ymin) / mag;
            const double rx = caoa * xnorm - saoa * ynorm;
            const double ry = saoa * xnorm + caoa * ynorm;

            const double x = scale * rx + left;
            const double y = scale * ry + bottom;
            scaled_coords.push_back(Point(x, y));
        }
        return scaled_coords;
    }
}

namespace wingworks {
    Airfoil::Airfoil(const double left, const double bottom, const double width, const double aoa_rads)
    : shape_m(get_vertex_coords(left, bottom, width, aoa_rads))
    {
        const BBox& origin(shape_m.bbox());
        pos_m = Vector(origin.xmin(), origin.ymin());
        vel_m = Vector(0.0, 0.0);
    }
}