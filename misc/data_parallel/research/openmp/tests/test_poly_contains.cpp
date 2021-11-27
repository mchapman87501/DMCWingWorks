#include <iostream>
#include <vector>
#include <assert.h>
#include <cmath>

#include "point.h"
#include "particle.h"
#include "polygon.h"

using namespace std;
using namespace wingworks;


void test_poly_contains_1() {
    vector<Point> vertices;
    const double x_center = 3.0;
    const double r = 3.0;
    for (double angle = 0.0; angle <= 2.0 * M_PI; angle += M_PI / 180.0) {
        vertices.push_back(Point(x_center + r * ::cos(angle), r * ::sin(angle)));
    }
    Polygon poly(vertices);

    assert(!poly.contains(Point(0.0, 0.0)));
    assert(poly.contains(Point(0.1, 0.0)));
    assert(poly.contains(Point(3.0, 2.9)));
    assert(!poly.contains(Point(3.0, -3.1)));
    assert(poly.contains(Point(1.0, 1.0)));
    assert(poly.contains(Point(5.9, 0.0)));
    assert(!poly.contains(Point(6.0, 0.0)));
}

void test_poly_bbox() {
    Polygon poly({
        Point(0.0, 0.0),
        Point(1.0, 0.0),
        Point(1.0, 1.0),
        Point(0.0, 1.0)
    });

    assert(poly.bbox().xmin() == 0.0);
    assert(poly.bbox().ymin() == 0.0);
    assert(poly.bbox().width() == 1.0);
    assert(poly.bbox().height() == 1.0);
}

int main(int, char**) {
    test_poly_contains_1();
    test_poly_bbox();
    return 0;
}