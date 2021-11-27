#pragma once

#include "polygon.h"
#include "vector.h"

namespace wingworks {
    class Airfoil {
    private:
        Polygon shape_m;
        Vector pos_m;
        Vector vel_m;

        // const double mass_m = 1.0e3;

    public:
        Airfoil(const double left, const double bottom, const double width, const double aoa_rads);

        Airfoil(const Airfoil& src)
        : shape_m(src.shape_m)
        , pos_m(src.pos_m)
        , vel_m(src.vel_m)
        {}

        inline const Polygon& shape() const { return shape_m; }
        const Vector& vel() const { return vel_m; }
    };
}