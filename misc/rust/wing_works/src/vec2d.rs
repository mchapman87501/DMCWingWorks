pub mod vec2d {
    #[derive(Debug, PartialEq, Clone, Copy)]
    pub struct Vec2D {
        pub x: f64,
        pub y: f64,
    }
    
    impl Vec2D {
        /// Create a new instance
        pub fn new(x: f64, y: f64) -> Vec2D {
            Vec2D{x: x, y: y}
        }

        /// Get the offset of self from other.
        pub fn offset(&self, other: &Vec2D) -> Vec2D {
            Vec2D { x: self.x - other.x, y: self.y - other.y }
        }

        /// Get the sum of self and other.
        pub fn adding(&self, other: &Vec2D) -> Vec2D {
            Vec2D { x: self.x + other.x, y: self.y + other.y }
        }

        /// Add other to self.
        pub fn add(&mut self, other: &Vec2D) {
            self.x += other.x;
            self.y += other.y;
        }

        /// Get the dot product of self and other -- the magnitude of
        /// self in the direction of other.
        pub fn dot(&self, other: &Vec2D) -> f64 {
            self.x * other.x + self.y * other.y
        }

        /// Get self's magnitude.
        pub fn magnitude(&self) -> f64 {
            (self.x * self.x + self.y * self.y).sqrt()
        }

        pub fn mag_sqr(&self) -> f64 { self.x * self.x + self.y * self.y }

        /// Get the unit vector with the same direction as self.
        pub fn unit(&self) -> Vec2D {
            let m = self.magnitude();
            if m <= 0.0 {
                // What to return for null vectors?
                Vec2D { x: 0.0, y: 0.0 }
            } else {
                Vec2D { x: self.x / m, y: self.y / m }
            }
        }

        /// Get self multiplied by a scalar
        pub fn scaled(&self, s: f64) -> Vec2D {
            Vec2D { x: self.x * s, y: self.y * s }
        }
    }

    #[test]
    fn test_offset() {
        let v1 = Vec2D { x: 1.0, y: 1.0 };
        let v2 = Vec2D { x: -1.0, y: 0.0 };
        let v3 = v1.offset(&v2);
        assert_eq!(v3, Vec2D{x: 2.0, y: 1.0});
    }

    #[test]
    fn test_adding() {
        let v1 = Vec2D { x: 1.0, y: 1.0 };
        let v2 = Vec2D { x: -1.0, y: 0.0 };
        let v3 = v1.adding(&v2);
        assert_eq!(v3, Vec2D{x:0.0, y: 1.0});
    }

    #[test]
    fn test_dot() {
        let d = Vec2D{x: 10.0, y: 1.0}.dot(&Vec2D{x: 1.0, y: 0.0});
        assert_eq!(d, 10.0);
        let d = Vec2D{x: 1.0, y: 0.0}.dot(&Vec2D{x: 1.0, y: 0.0});
        assert_eq!(d, 1.0);
        let d = Vec2D{x: 0.0, y: 0.0}.dot(&Vec2D{x: 1.0, y: 0.0});
        assert_eq!(d, 0.0);
        let d = Vec2D{x: 0.0, y: 1.0}.dot(&Vec2D{x: 1.0, y: 0.0});
        assert_eq!(d, 0.0);
    }

    #[test]
    fn test_magnitude() {
        assert_eq!((2.0f64).sqrt(), Vec2D{x: 1.0, y: 1.0}.magnitude());
    }

    #[test]
    fn test_unit() {
        let u = Vec2D{x:25.4, y:0.0}.unit();
        let expected = Vec2D{x:1.0, y:0.0};
        assert_eq!(u, expected);

        let u = Vec2D{x: 3.0, y: 4.0}.unit();
        let expected = Vec2D{x: 0.6, y: 0.8};
        assert_eq!(u, expected);

        let u = Vec2D{x: 0.0, y: 0.0}.unit();
        let expected = Vec2D{x: 0.0, y:0.0};
        assert_eq!(u, expected);
    }

    #[test]
    fn test_scaled() {
        let v = Vec2D{x: 3.5, y: 0.0}.scaled(1.0/3.5);
        let expected = Vec2D{x: 1.0, y: 0.0};
        assert_eq!(v, expected);
    }
}
