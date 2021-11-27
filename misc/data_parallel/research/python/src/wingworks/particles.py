"""
particles holds the state of all particles in the world.
"""

import numpy as np
from scipy.spatial import distance_matrix

class Particles:
    """
    Particles holds the state of a set of particles.
    """
    _radius = 1.0

    def __init__(
            self,
            num_particles: int,
            world_extent: float = 1000,
            max_vel: float = 0.0001
    ) -> None:
        self._shape = shape = (num_particles, 2)
        self._pos = np.random.rand(*self._shape) * world_extent
        self._vel = np.random.rand(*self._shape) - 0.5 * max_vel
        self._acc = np.zeros(shape)

    def dist(self) -> np.ndarray:
        # This scales really badly.
        return distance_matrix(self._pos, self._pos)
