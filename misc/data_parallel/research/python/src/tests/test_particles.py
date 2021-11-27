from wingworks import particles


def test_creation() -> None:
    p = particles.Particles(100)

    dm = p.dist()
    print(dm)
