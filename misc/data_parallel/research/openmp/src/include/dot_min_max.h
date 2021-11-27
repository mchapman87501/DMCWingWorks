#pragma once

namespace wingworks {
// This is just a record that holds a pair of values
// representing minimum and maximum dot products between
// a vector and some other set of vectors.
struct DotMinMax {
    const double min_m;
    const double max_m;

    DotMinMax(const double vmin, const double vmax)
    : min_m(vmin), max_m(vmax) {}
};

}