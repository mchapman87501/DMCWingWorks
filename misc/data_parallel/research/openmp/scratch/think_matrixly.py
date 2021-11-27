#!/usr/bin/env python3

import math
import numpy as np

# Invent a series of 2d points.
pos_list = []

total_points = 100
side = int(math.sqrt(total_points))
for x in range(side):
    for y in range(side):
        pos_list.append([x, y])

# Convert to a NumPy array.
positions = np.array(pos_list, dtype=np.float)

# Compute pairwise distances from a point to all subsequent points.
# Presumably these array-like operations map well onto GPU logic.
num_positions = len(positions)
for i in range(num_positions):
    curr_p = list(positions[i])
    num_remaining = num_positions - i - 1
    if num_remaining > 0:
        curr_p_vec = np.array([curr_p] * num_remaining)

        component_dists = curr_p_vec - positions[i+1:]
        sq_comp_dists = component_dists * component_dists
        dist_sqr = np.add.reduce(sq_comp_dists, 1)
        print(f"Dist sqr's from point {i}: {dist_sqr}")
