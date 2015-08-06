using MMA
using Base.Test

import MMA: eval_constraint, eval_objective

function f(x, grad)
    if length(grad) != 0
        grad[1] = 0.0
        grad[2] = 0.5/sqrt(x[2])
    end
    sqrt(x[2])
end

function g(x::Vector, grad::Vector, a, b)
    if length(grad) != 0
        grad[1] = 3a * (a*x[1] + b)^2
        grad[2] = -1
    end
    (a*x[1] + b)^3 - x[2]
end

m = MMAModel(2, f, xtol = 1e-6)

box!(m, 1, 0.0, 100.0)
box!(m, 2, 0.0, 100.0)

ineq_constraint!(m, (x,grad) -> g(x,grad,2,0))
ineq_constraint!(m, (x,grad) -> g(x,grad,-1,1))

################3

@test dim(m) == 2

# Objective
let
    grad1 = zeros(2)
    grad2 = zeros(2)
    p = [1.234, 2.345]
    @test_approx_eq eval_objective(m, p, grad2) f(p, grad1)
    @test_approx_eq grad1 grad2
end

# Box
@test min(m, 1) == 0.0
@test max(m, 1) == 100.0
@test min(m, 2) == 0.0
@test max(m, 2) == 100.0

# Inequalities
let
    grad1 = zeros(2)
    grad2 = zeros(2)
    p = [1.234, 2.345]
    @test_approx_eq eval_constraint(m, 1, p, grad1) g(p,grad2 ,2,0)
    @test_approx_eq grad1 grad2

    @test_approx_eq eval_constraint(m, 2, p, grad1) g(p,grad2,-1,1)
    @test_approx_eq grad1 grad2
end

r = solve(m, [0.5, 5.0])
println(r)

@test abs(r.obj_value - sqrt(8/27)) < 1e-6
@test norm(r.minimum - [1/3, 8/27]) < 1e-6