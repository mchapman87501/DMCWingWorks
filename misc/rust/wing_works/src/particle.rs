pub mod particle {
    use crate::vec2d::vec2d::Vec2D;

    #[derive(Debug, PartialEq, Clone, Copy)]
    pub struct Particle {
        pub mass: f64,
        pub radius: f64,
        pub s: Vec2D,
        pub v: Vec2D,
    }

    impl Particle {
        /// Create a Particle with default mass=1 and radius=1.
        pub fn new(s: &Vec2D, v: &Vec2D) -> Particle {
            Particle{
                mass: 1.0, radius: 0.1,
                s: s.clone(),
                v: v.clone()
            }
        }

        /// Find out if self is close enough to other to be colliding.
        pub fn is_colliding(&self, other: &Particle) -> bool {
            let drad = self.radius + other.radius;
            let drsqr = drad * drad;
            self.s.offset(&other.s).mag_sqr() <= drsqr
        }

        /// Resolve the collision of self with other.
        /// OBS:  Caller is responsible for ensuring self and other are actually
        /// colliding.
        pub fn collide_with(&mut self, other: &mut Particle) {
            let n = self.s.offset(&other.s).unit();
            let jr = self.get_impulse(&other, &n);
            self.v = self.v.offset(&n.scaled(-jr / self.mass));
            other.v = other.v.offset(&n.scaled(jr / self.mass));
        }

        /// Get the impulse magnitude for self colliding with other in
        /// the direction of the unit offset vector between the two.
        fn get_impulse(&self, other: &Particle, n: &Vec2D) -> f64 {
            // e is the coefficient of restitution.  Set to 1 for
            // a perfectly elastic collision, I think.
            let e = 1.0;
            // Relative collision velocity:
            let vr = self.v.offset(&other.v);

            let numer = -(1.0 + e) * vr.dot(&n);
            // Ignore rotational inertia
            let denom = 1.0 / self.mass + 1.0 / other.mass;

            numer / denom
        }

        /// Update self's position.
        pub fn update_position(&mut self) {
            self.s.add(&self.v);
        }
    }

    #[test]
    fn test_is_colliding() {
        let vzero = Vec2D::new(0.0, 0.0);
        let p0 = Particle::new(&Vec2D::new(0.0, 0.0), &vzero);
        let p1 = Particle::new(&Vec2D::new(1.0, 0.0), &vzero);
        assert!(p0.is_colliding(&p1));

        let p2 = Particle::new(&Vec2D::new(2.01, 0.0), &vzero);
        assert!(!p0.is_colliding(&p2));
    }

    #[test]
    fn test_get_impulse() {
        let p0 = Particle::new(
            &Vec2D::new(0.0, 0.0),
            &Vec2D::new(2.0, 0.0));
        let p1 = Particle::new(
            &Vec2D::new(1.0, 0.0),
            &Vec2D::new(0.0, 0.0));

        let n = p0.s.offset(&p1.s).unit();
        let actual = p0.get_impulse(&p1, &n);
        assert_eq!(actual, 2.0);
    }

    #[test]
    fn test_get_impulse_diverging() {
        // Not sure about this: the two particles are close enough
        // to be colliding, but p1 is already moving away from p0.
        let p0 = Particle::new(
            &Vec2D::new(1.0, 0.0),
            &Vec2D::new(2.0, 0.0));
        let p1 = Particle::new(
            &Vec2D::new(0.0, 0.0),
            &Vec2D::new(0.0, 0.0));

        let n = p0.s.offset(&p1.s).unit();
        let actual = p0.get_impulse(&p1, &n);
        assert_eq!(actual, -2.0);
    }
}