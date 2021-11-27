link_libraries(wingworks)

function(def_test name)
    add_executable(test_${name} test_${name}.cpp)
    add_test(${name} test_${name})
endfunction()


def_test(particle_collision)
def_test(poly_contains)
def_test(airfoil_collision)
