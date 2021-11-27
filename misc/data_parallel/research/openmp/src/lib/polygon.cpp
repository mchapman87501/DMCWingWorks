#include "polygon.h"

namespace wingworks {
    using namespace std;

    Polygon::Polygon(const std::vector<Point>& vertices) {
        const size_t num_vertices = vertices.size();
        for (size_t i = 0; i < num_vertices; i++) {
            Segment s(vertices[i], vertices[(i + 1) % num_vertices]);
            edges_m.push_back(s);
            bbox_m.enclose(vertices[i]);
        }
        vertices_m = vertices;

        edge_normals_m.clear();
        for (const auto& e : edges_m) {
            edge_normals_m.push_back(e.as_vector().normal().unit());
        }
    }

    // This algorithm avoids a host of boundary conditions:
    // http://geomalgorithms.com/a03-_inclusion.html
    /*
        Edge Crossing Rules

        1. an upward edge includes its starting endpoint, and excludes its final endpoint;
        
        2. a downward edge excludes its starting endpoint, and includes its final endpoint;
        
        3. horizontal edges are excluded
        
        4. the edge-ray intersection point must be strictly right of the point P.
        
        cn_PnPoly( Point P, Point V[], int n )
        {
            int    cn = 0;    // the  crossing number counter

            // loop through all edges of the polygon
            for (each edge E[i]:V[i]V[i+1] of the polygon) {
                if (E[i] crosses upward ala Rule #1
                || E[i] crosses downward ala  Rule #2) {
                    if (P.x <  x_intersect of E[i] with y=P.y)   // Rule #4
                        ++cn;   // a valid crossing to the right of P.x
                }
            }
            return (cn&1);    // 0 if even (out), and 1 if  odd (in)

        }
    */
    bool Polygon::contains(const Point& p) const {
        if (bbox_m.contains(p)) {
            const double x0 = p.x(), y0 = p.y();
            size_t num_crossings = 0;
            for (const auto &edge : edges_m) {
                if (edge.crosses_upward(y0) || edge.crosses_downward(y0)) {
                    if (x0 < edge.x_intersect(p)) {
                        num_crossings += 1;
                    }
                }
            }
            return (0 != (num_crossings % 2));
        }
        return false;
    }
}
