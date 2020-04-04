using .Synapse: evalsynapses, AbstractSynapse

struct Neuron{ST<:AbstractArray{<:AbstractSynapse}, BT<:AbstractCell, TT}
    synapses::ST
    body::BT
    threshold::TT
end
Neuron(synapse::ST, body::BT, threshold::TT) where {ST<:AbstractSynapse, BT<:AbstractCell, TT} =
    Neuron(StructArray([synapse]), body, threshold)
Neuron{ST}(body::BT, threshold::TT) where {ST<:AbstractSynapse, BT<:AbstractCell, TT} =
    Neuron(StructArray{ST}(undef, 0), body, threshold)

function connect!(neuron::Neuron, synapse::AbstractSynapse)
    push!(neuron.synapses, synapse)

    return neuron
end

isactive(neuron::Neuron, t::Integer; dt::Real = 1.0) = isactive(neuron.body, t; dt = dt) ||
                                                       Threshold.isactive(neuron.threshold, t; dt = dt) ||
                                                       any(s -> Synapse.isactive(s, t; dt = dt), neuron.synapses)

excite!(neuron::Neuron, spike::Integer) = map(s -> Synapse.excite!(s, spike), neuron.synapses)
excite!(neuron::Neuron, spikes::Array{<:Integer}) = map(s -> Synapse.excite!(s, spikes), neuron.synapses)
function excite!(neuron::Neuron, input, T::Integer; dt::Real = 1.0)
    spikes = filter!(x -> x != 0, [input(t; dt = dt) for t = 1:T])
    excite!(neuron, spikes)

    return spikes
end

function (neuron::Neuron)(t::Integer; dt::Real = 1.0)
    I = sum(evalsynapses(neuron.synapses, t; dt = dt))
    excite!(neuron.body, I)
    spike = neuron.threshold(t, neuron.body(t; dt = dt); dt = dt)
    (spike > 0) && spike!(neuron.body, t; dt = dt)

    return spike
end

"""
    simulate!(neuron::AbstractNeuron)

Fields:
- `neuron::AbstractNeuron`: the neuron to simulate
- `T::Integer`: number of time steps to simulate
- `dt::Real`: the length ofsimulation time step
- `cb::Function`: a callback function that is called after event evaluation
- `dense::Bool`: set to `true` to evaluate every time step even in the absence of events
"""
function simulate!(neuron::Neuron, T::Integer; dt::Real = 1.0, cb = () -> (), dense = false)
    spikes = Int[]

    # step! neuron until queue is empty
    cb()
    for t = 1:T
        if dense || isactive(neuron, t; dt = dt)
            push!(spikes, neuron(t; dt = dt))
            cb()
        end
    end

    return filter!(x -> x != 0, spikes)
end