#include <iostream>
#include <vector>
#include <assert.h>
#include <cmath>

#include "particle.h"
#include "point.h"
#include "vector.h"
#include "airfoil.h"
#include "airfoil_collision.h"

using namespace std;
using namespace wingworks;


void test_collision_1() {
    Airfoil foil(10.0, 0.0, 50.0);
    AirfoilCollision ac(foil);

    Particle p;
    p.move_to(0.0, 0.0);
    Vector recoil;
    bool result = ac.is_colliding(p, recoil);
    assert(!result);

    cout << "Airfoil vertices: " << endl;
    const vector<Point>& shape = foil.shape().vertices();
    for (const Point& point : shape) {
        cout << "  " << point.to_str() << endl;
    }
    cout << endl;

    // Hard to get this right due to airfoil shape.
    Point foil_vertex(shape[2]);


    p.move_to(foil_vertex.adding(Point(-1.0e-4, 0.0)));
    p.set_vel(0.1, 0.0);
    result = ac.is_colliding(p, recoil);

    cout << "Particle pos 1: " << p.pos().to_str() << endl;
    cout << "Recoil 1: " << recoil.to_str() << endl;
    assert(result);
    assert(!foil.shape().contains(p.pos()));

    // Move just inside.
    p.move_to(foil_vertex.adding(Point(1.0e-4, 0.0)));
    assert(foil.shape().contains(p.pos()));

    result = ac.is_colliding(p, recoil);
    assert(result);
    cout << "Particle pos 2: " << p.pos().to_str() << endl;
    cout << "Recoil 2: " << recoil.to_str() << endl;

    p.move_to(foil_vertex.adding(Point(0.1, 0.0)));
    Point pos0(p.pos());
    Vector v0(p.vel());
    ac.resolve_collision(p, recoil);
    // Recoil *should* move the point just outside the polygon.
    // And it should change its velocity.
    cout << "Collision changed position from " << pos0.to_str() << " to " << p.pos().to_str() << endl;
    cout << "    Changed vel from " << v0.to_str() << " to " << p.vel().to_str() << endl;
    // TODO confirm the new velocity is away from the foil.
}


int main(int, char**) {
    test_collision_1();
    return 0;
}