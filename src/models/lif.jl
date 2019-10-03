"""
    LIF

A leaky-integrate-fire neuron.

Fields:
- `voltage::VT`: membrane potential
- `spikes_in::Accumulator{IT, VT}`: a map of input spike times => current at each time stamp
- `last_spike::IT`: the last time this neuron processed a spike
- `τ_m::VT`: membrane time constant
- `v_reset::VT`: reset voltage potential
- `v_th::VT`: threshold voltage potential
- `R::VT`: resistive constant (typically = 1)
"""
mutable struct LIF{VT<:Real, IT<:Integer} <: AbstractNeuron{VT, IT}
    # required fields
    voltage::VT
    spikes_in::Accumulator{IT, VT}
    last_spike::IT

    # model specific fields
    τ_m::VT
    v_reset::VT
    v_th::VT
    R::VT
end

Base.show(io::IO, ::MIME"text/plain", neuron::LIF) =
    print(io, """LIF with $(length(neuron.spikes_in)) queued spikes:
                     voltage: $(neuron.voltage)
                     τ_m:     $(neuron.τ_m)
                     v_reset: $(neuron.v_reset)
                     v_th:    $(neuron.v_th)
                     R:       $(neuron.R)""")
Base.show(io::IO, neuron::LIF) =
    print(io, "LIF(τ_m: $(neuron.τ_m), v_reset: $(neuron.v_reset), v_th: $(neuron.v_th), R: $(neuron.R))")

"""
    LIF(τ_m, v_reset, v_th, R = 1.0)

Create a LIF neuron with zero initial voltage and empty spike queue.
"""
LIF(τ_m::Real, v_reset::Real, v_th::Real, R::Real = 1.0) =
    LIF{Float64, Int}(v_reset, Accumulator{Int, Float64}(), 1, τ_m, v_reset, v_th, R)


"""
    step!(neuron::LIF, dt::Real = 1.0)::Integer

Evaluate the differential equation between `neuron.last_spike` and the latest input spike.
Return time stamp if the neuron spiked and zero otherwise.
"""
function step!(neuron::LIF, dt::Real = 1.0)
    # pop the latest spike off the queue
    t = minimum(keys(neuron.spikes_in))
    current_in = DataStructures.reset!(neuron.spikes_in, t)

    # println("Processing time $(neuron.last_spike) to $t")

    # decay the voltage between last_spike and t
    # println("  v = $(neuron.voltage)")
    for i in neuron.last_spike:t
        neuron.voltage = neuron.voltage - neuron.voltage / neuron.τ_m
        # (:voltage ∈ neuron.record_fields && i < t) && push!(neuron.record[:voltage], neuron.voltage)
        # println("  v = $(neuron.voltage)")
    end

    # accumulate the input spike
    neuron.voltage += neuron.R / neuron.τ_m * current_in
    # println("  v (post spike) = $(neuron.voltage)")

    # choose whether to spike
    spiked = (neuron.voltage >= neuron.v_th)
    # println("  spiked? (v_th = $(neuron.v_th)) = $spiked")
    neuron.voltage = spiked ? neuron.v_reset : neuron.voltage
    # println("  v (post thresh) = $(neuron.voltage)")

    # update the last spike
    neuron.last_spike = t + 1

    return spiked ? t : 0
end

"""
    reset!(neuron::LIF)

Reset the neuron to its reset voltage and clear its input spike queue.
"""
function reset!(neuron::LIF)
    neuron.voltage = neuron.v_reset
    neuron.last_spike = 1
    for key in keys(neuron.spikes_in)
        reset!(neuron.spikes_in, key)
    end
end