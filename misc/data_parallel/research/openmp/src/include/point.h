#pragma once

#include <cmath>
#include <string>

namespace wingworks {
    class Point {
    private:
        double x_m;
        double y_m;

    public:
        Point(double x, double y): x_m(x), y_m(y) {}
        Point(): x_m(0.0), y_m(0.0) {}
        Point(const Point& src): x_m(src.x_m), y_m(src.y_m) {}
        Point& operator=(const Point& src) {
            x_m = src.x_m;
            y_m = src.y_m;
            return *this;
        }

        void update(const double x, const double y) {
            x_m = x;
            y_m = y;
        }

        double dist_sqr(const Point& other) const {
            const double dx = x_m - other.x_m;
            const double dy = y_m - other.y_m;
            return (dx * dx) + (dy * dy);
        }

        Point offset(const Point& other) const {
            return Point(x_m - other.x_m, y_m - other.y_m);
        }

        void add(const Point& other) {
            x_m += other.x_m;
            y_m += other.y_m;
        }

        Point adding(const Point& other) const {
            return Point(x_m + other.x_m, y_m + other.y_m);
        }

        Point scaled(const double s) const {
            return Point(x_m * s, y_m * s);
        }

        inline double dot(const Point& other) const {
            return (x_m * other.x_m) + (y_m * other.y_m);
        }

        Point normal() const {
            return Point(-y_m, x_m);
        }

        double mag_sqr() const {
            return (x_m * x_m + y_m * y_m);
        }

        double magnitude() const {
            return ::sqrt(mag_sqr());
        }

        Point unit() const;

        double x() const { return x_m; }
        double y() const { return y_m; }

        std::string to_str() const;
    };

}