#include "bbox.h"
#include <sstream>

namespace wingworks {
    using namespace std;

    bool BBox::overlaps(const BBox& other) const {
        if ((xmax_m < other.xmin_m) 
            || (xmin_m > other.xmax_m)
            || (ymax_m < other.ymin_m)
            || (ymin_m > other.ymax_m)
        ) {
            return false;
        }
        return true;
    }

    std::string BBox::to_str() const {
        ostringstream outs;
        outs
            << "(xmin=" << xmin_m << ", ymin=" << ymin_m 
            << ", xmax=" << xmax_m << ", ymax=" << ymax_m << ")";
        return outs.str();
    }
}