using SpikingNN
using Plots

# SRM0 params
η₀ = 5.0
τᵣ = 1.0
v_th = 2.0

# Input spike train params
rate = 0.01
T = 20
∂t = 0.01
n = convert(Int, ceil(T / ∂t))

srm = Neuron(Synapse.Delta(q = 2), SRM0(η₀, τᵣ), Threshold.Poisson(60.0, 0.016, 0.002))
input = ConstantRate(rate)
spikes = excite!(srm, input, n)

# callback to record voltages
voltages = Float64[]
record = function ()
    push!(voltages, getvoltage(srm.body))
end

# simulate
@time output = simulate!(srm, n; dt = ∂t, cb = record, dense = true)

# plot raster plot
raster_plot = rasterplot(∂t .* spikes, ∂t .* output, label = ["Input", "Output"], xlabel = "Time (sec)",
                title = "Raster Plot (\\delta response)")
xlims!(0, T)

# plot dense voltage recording
plot(∂t .* collect(0:n), voltages,
    title = "SRM Membrane Potential with Varying Presynaptic Responses", xlabel = "Time (sec)", ylabel = "Potential (V)", label = "\\delta response")

# resimulate using presynaptic response
reset!(srm.body)
srm = Neuron(Synapse.Alpha(), srm.body, srm.threshold)
voltages = Float64[]
excite!(srm, spikes)
@time simulate!(srm, n; dt = ∂t, cb = record, dense = true)

# plot voltages with response function
voltage_plot = plot!(∂t .* collect(0:n), voltages, label = "\\alpha response")
xlims!(0, T)

plot(raster_plot, voltage_plot, layout = grid(2, 1), xticks = 0:T)