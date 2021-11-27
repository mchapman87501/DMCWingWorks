#pragma once

#include "point.h"

#include <string>

namespace wingworks {
    class BBox {
    private:
        double xmin_m, ymin_m, xmax_m, ymax_m;

    public:
        BBox(double xmin, double ymin, double xmax, double ymax)
        : xmin_m(xmin), ymin_m(ymin), xmax_m(xmax), ymax_m(ymax)
        {}

        BBox(): BBox(0.0, 0.0, 0.0, 0.0) {}
        BBox(const BBox& src) {
            xmin_m = src.xmin_m;
            xmax_m = src.xmax_m;
            ymin_m = src.ymin_m;
            ymax_m = src.ymax_m;
        }
        BBox& operator=(const BBox& src) {
            xmin_m = src.xmin_m;
            xmax_m = src.xmax_m;
            ymin_m = src.ymin_m;
            ymax_m = src.ymax_m;
            return *this;
        }

        void update(double xmin, double ymin, double xmax, double ymax) {
            // Caller must ensure xmin <= xmax, etc.
            xmin_m = xmin;
            ymin_m = ymin;
            xmax_m = xmax;
            ymax_m = ymax;
        }

        double xmin() const { return xmin_m; }
        double ymin() const { return ymin_m; }
        double width() const { return xmax_m - xmin_m; }
        double height() const { return ymax_m - ymin_m; }

        bool contains(const Point& p) const {
            const double x = p.x(), y = p.y();
            return ((xmin_m <= x) && (x < xmax_m)
                    && (ymin_m <= y) && (y < ymax_m));
        }

        // Extend this BBox as needed to contain point p.
        void enclose(const Point& p) {
            const double x = p.x(), y = p.y();
            if (x < xmin_m) {
                xmin_m = x;
            }
            if (x > xmax_m) {
                xmax_m = x;
            }
            if (y < ymin_m) {
                ymin_m = y;
            }
            if (y > ymax_m) {
                ymax_m = y;
            }
        }

        void extend_bounds(const double fraction) {
            const double w_delta = width() * fraction / 2.0;
            xmin_m -= w_delta;
            xmax_m += w_delta;

            const double h_delta = height() * fraction / 2.0;
            ymin_m -= h_delta;
            ymax_m += h_delta;
        }

        bool overlaps(const BBox& other) const;

        std::string to_str() const;
    };
}