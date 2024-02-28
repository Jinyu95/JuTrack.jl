include("../src/JuTrack.jl")
using. JuTrack
using Enzyme
using BenchmarkTools
using Plots
using Serialization
Enzyme.API.runtimeActivity!(true)


function twiss_test(xx, esr)
    changed_idx = [3]
    lenQ1 = esr[3].len
    new_Q1 = KQUAD(len=lenQ1, k1=xx)
    changed_ele = [new_Q1]

    twiss_in = EdwardsTengTwiss(betax=50.0,betay=10.0)
    ss, name, twiss_out = ADTwissline(twiss_in, esr, 0.0, 2, length(esr), changed_idx, changed_ele)
    return twiss_out.betax
end

function tuning_test(target)
    esr = deserialize("esr_main_vector.jls")

    x0 = -0.2278853772
    niter = 20
    step = 0.00001

    x0_vals = Float64[]
    beta_vals = Float64[]
    grad_vals = Float64[]
    for i in 1:niter
        beta0 = twiss_test(x0, esr)
        if i == 1
            println("init beta0: ", beta0)
        end
        grad = autodiff(Forward, twiss_test, DuplicatedNoNeed, Duplicated(x0, 1.0),  Const(esr))
        x0 -= step * grad[1]
        beta1 = twiss_test(x0, esr)
        println("beta0: ", beta0, " beta1: ", beta1, "grad:", grad, "at step ", i)
        push!(x0_vals, x0)
        push!(beta_vals, beta1)
        push!(grad_vals, grad[1])
        if beta1 < target
            println("tuning finished at step ", i, " with beta1: ", beta1, " and target: ", target)
            break
        end
    end
    return x0_vals, beta_vals, grad_vals
end
x0_vals, beta_vals, grad_vals = tuning_test(10.0)

using LaTeXStrings
p1 = plot(1:length(x0_vals), x0_vals, title = L"Evolution\ of\ k_1", xlabel = L"Iteration", ylabel = L"Strength (m^{-1})", legend = false, line=:dash, marker=:circle)
p2 = plot(1:length(beta_vals), beta_vals, title = L"Evolution\ of\ \beta_x", xlabel = L"Iteration", ylabel = L"\beta_x(m)", legend = false, line=:dash, marker=:circle)
p3 = plot(1:length(grad_vals), grad_vals, title = L"Evolution\ of\ \frac{\partial \beta_x}{\partial k_1}", xlabel = L"Iteration", 
    ylabel = L"\partial \beta_x /\partial k_1", legend = false, line=:dash, marker=:circle)
plot(p1, p2, p3, layout = (3, 1), size=(800, 650))


