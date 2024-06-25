using CUDA
include("SplitRandom.jl") 
include("mh.jl")
include("Particles.jl")
include("barriers.jl")

# D = dim 
# N = num particles 
# T = num annealing params

@kernel function iid_(rngs, @Const(path), 
        states          # D x N
        ) 
    n = @index(Global)  # ∈ 1 .. N 
    rng = rngs[n]
    state = @view states[:, n]
    iid_sample!(rng, path, state)
end

@kernel function propagate_and_weigh_(rngs, @Const(path), @Const(explorer), 
        states,         # D x N
        buffers,        # D x N
        log_weights,    # N 
        log_increments, # T x N of nothing
        @Const(betas)   # T
        )   
    n = @index(Global)  # ∈ 1 .. N 
    rng = rngs[n]
    T = length(betas) 
    for t in 2:T 
        state = @view states[:, n]
        buffer = @view buffers[:, n]
        log_increment = weigh(path, explorer, betas[t-1], betas[t], state)
        update_log_increment!(log_increments, t, n, log_increment)
        log_weights[n] += log_increment
        explore!(rng, explorer, path, state, buffer, betas[t])
    end
end 

# Default AIS weight update
weigh(path, _, prev_beta, cur_beta, state) = log_density(path, cur_beta, state) - log_density(path, prev_beta, state)

update_log_increment!(log_increments, t, n, log_increment) = log_increments[t, n] = log_increment
update_log_increment!(::Nothing, _, _, _) = nothing

@auto struct AIS 
    particles 
    timing 
    intensity
    barriers 
end

ais(path, T::Int; kwargs...) = ais(path, range(0, 1, length = T); kwargs)

function ais(path, schedule::AbstractVector; 
        backend::Backend = CPU(), 
        N::Int = backend isa CPU ? 2^10 : 2^14, 
        seed = 1,
        multi_threaded = true,
        compute_barriers = false, 
        explorer = RWMH(), 
        elt_type::Type{E} = Float32
        ) where {E}

    @assert multi_threaded || backend isa CPU
    
    T = length(schedule) 
    rngs = SplitRandomArray(N; backend, seed) 
    D = dimensionality(path)
    states = KernelAbstractions.zeros(backend, E, D, N)

    # initialization: iid sampling from reference
    iid_(backend, cpu_args(multi_threaded, N, backend)...)(rngs, path, states, ndrange = N) 
    KernelAbstractions.synchronize(backend)

    # parallel propagation 
    betas = copy_to_device(Array{E}(schedule), backend)
    buffers = KernelAbstractions.zeros(backend, E, D, N) 
    log_weights = KernelAbstractions.zeros(backend, E, N)
    log_increments = compute_barriers ? KernelAbstractions.zeros(backend, E, T, N) : nothing 
    prop_kernel = propagate_and_weigh_(backend, cpu_args(multi_threaded, N, backend)...)
    timing = @timed begin
        prop_kernel(rngs, path, explorer, states, buffers, log_weights, log_increments, betas, ndrange = N)
        KernelAbstractions.synchronize(backend)
    end 
    println("Ran T=$T, N=$N in $(timing.time) sec [$(timing.bytes) bytes allocated]")
    intensity_vector = compute_barriers ? ensure_to_cpu(intensity(log_increments)) : nothing 
    barriers = compute_barriers ? Pigeons.communication_barriers(intensity_vector, collect(schedule)) : nothing

    return AIS(Particles(states, log_weights), timing, intensity_vector, barriers)
end

# workaround counter intuitive behaviour of KA on CPUs
cpu_args(multi_threaded::Bool, N::Int, ::CPU) = multi_threaded ? 1 : N
# the above is not needed for GPUs
cpu_args(_, _, _) = ()