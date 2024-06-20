using CUDA
include("SplitRandom.jl") 
include("mh.jl")
include("Particles.jl")

# D = dim 
# N = num particles 
# T = num annealing params

@kernel function iid_(rngs, path, 
        states          # D x N
        ) 
    i = @index(Global)  # ∈ 1 .. N 
    rng = rngs[i]
    state = @view states[:, i]
    iid_sample!(rng, path, state)
end

@kernel function propagate_and_weigh_(rngs, path, 
        states,         # D x N
        buffers,        # D x N
        log_weights,    # N 
        betas           # T
        )   
    i = @index(Global)  # ∈ 1 .. N 
    rng = rngs[i]
    T = length(betas) 
    for t in 2:T 
        state = @view states[:, i]
        buffer = @view buffers[:, i]
        log_weights[i] += log_density(path, betas[t], state) - log_density(path, betas[t-1], state)
        mh!(rng, path, state, buffer, betas[t]) 
    end
end 

struct AIS{X, Y}
    iid_kernel::X 
    prop_kernel::Y
end
AIS(; backend::Backend = CPU()) = AIS(iid_(backend), propagate_and_weigh_(backend))

function ais(a::AIS, path; T::Int, N::Int, backend::Backend = CPU(), seed::Int = 1, elt_type::Type{E} = Float32) where {E}
    rngs = SplitRandomArray(N; backend, seed) 
    D = dimensionality(path)
    states = KernelAbstractions.zeros(backend, E, D, N)

    # initialization: iid sampling from reference
    @time begin
        a.iid_kernel(rngs, path, states, ndrange=N) 
        KernelAbstractions.synchronize(backend)
    end

    # parallel propagation 
    betas_ = range(0.0, stop=1.0, length=T)
    betas = KernelAbstractions.zeros(backend, E, T) 
    betas .= betas_

    buffers = KernelAbstractions.zeros(backend, E, D, N) 
    log_weights = KernelAbstractions.zeros(backend, E, D, N) 
    @time begin
        a.prop_kernel(rngs, path, states, buffers, log_weights, betas, ndrange=N)
        KernelAbstractions.synchronize(backend)
    end 

    return Particles(states, vec(log_weights))
end

