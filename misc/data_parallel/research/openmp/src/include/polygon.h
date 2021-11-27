#pragma once

#include <vector>
#include <algorithm>

#include "point.h"
#include "segment.h"
#include "bbox.h"
#include "dot_min_max.h"

namespace wingworks {

class Polygon {
private:
    std::vector<Point> vertices_m;
    std::vector<Segment> edges_m;
    std::vector<Vector> edge_normals_m;
    BBox bbox_m;

public:
    Polygon(const std::vector<Point>& vertices);

    Polygon(const Polygon& src)
    : vertices_m(src.vertices_m)
    , edges_m(src.edges_m)
    , edge_normals_m(src.edge_normals_m)
    , bbox_m(src.bbox_m)
    {}

    const BBox& bbox() const { return bbox_m; }
    
    // Find out whether a point lies on or within the boundaries of self.
    bool contains(const Point& p) const;

    // Get normal "vectors" for each edge.
    const std::vector<Vector>& edge_normals() const {
        return edge_normals_m;
    }

    const std::vector<Point>& vertices() const {
        return vertices_m;
    }

    Point nearest_vertex_to(const Point& p) const {
        Point result;
        double min_dist = 0.0;
        for (size_t i = 0; i < vertices_m.size(); ++i) {
            const Point& vertex(vertices_m[i]);
            const double dsqr = vertex.offset(p).mag_sqr();
            if ((i == 0) || (dsqr < min_dist)) {
                result = vertex;
                min_dist = dsqr;
            }
        }
        return result;
    }

    // TODO get min and max dot products (projection) of a vector
    // vs. all of self's vertices (not edges).
    DotMinMax projected_extrema(const Vector& unit_vec) const {
        double dot_min = 0.0;
        double dot_max = 0.0;
        for (size_t i = 0; i < vertices_m.size(); ++i) {
            const double curr_dot = vertices_m[i].dot(unit_vec);
            if (i == 0) {
                dot_min = curr_dot;
                dot_max = curr_dot;
            } else {
                dot_min = (dot_min < curr_dot) ? dot_min : curr_dot;
                dot_max = (dot_max > curr_dot) ? dot_max : curr_dot;
            }
        }
        return DotMinMax(dot_min, dot_max);
    }
};

}
