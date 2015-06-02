
# one layer of a multilayer perceptron (neural net)
# w and b are both length nout, which is the number of neurons.  ninᵢ == noutᵢ₋₁
type Layer
	nin::Int
	nout::Int

	nodes::Vector{Perceptron}

	# # w & dw include an extra row at the bottom corresponding to the bias (b & db)
	# w::MatF  # w[i,j] == wᵢⱼ corresponds to the weight of input i contributing to output j
	# dw::MatF  # change in w
	# activation::Activation

	# x::VecF	# input vector (output from previous layer)
	δ::VecF	# a vector of partial derivatives: {∂E/∂Σᵢ} also known as "sensitivities"
	# Σ::VecF	# weighted sum of inputs and bias:  Σⱼ = dot(x, col(w,j)) + b[j]
end

Base.print(io::IO, l::Layer) = print(io, "Layer{$(l.nin)=>$(l.nout), w=$(vec(l.w)), dw=$(vec(l.dw)), x=$(l.x), δ=$(l.δ), Σ=$(l.Σ)}")



# function initializeWeights(nin::Int, nj::Int)
# 	w = ((rand(nin, nj) - 0.5) * 2.0) * sqrt(6.0 / (nin + nj))
# 	w[end,:] = 0.0  # bias row
# 	w
# end

initialWeights(nin::Int, nout::Int) = vcat((rand(nin) - 0.5) * 2.0 * sqrt(6.0 / (nin + nout)), 0.0)


function buildLayer(nin::Int, nout::Int, activation::Activation = SigmoidActivation())
	nodes = [Perceptron(nin, initialWeights(nin, nout), activation) for j in 1:nout]
	Layer(nin, nout,
				# initializeWeights(nin+1, nout), zeros(nin+1,nout),  # w, dw
				nodes,
				# activation,
				# zeros(nin+1),	# x
				zeros(nout) 	# δ
				# zeros(nout)		# Σ
				)
end


# activate(layer::Layer) = map(layer.activation.A, layer.Σ)
# activateprime(layer::Layer) = map(layer.activation.dA, layer.Σ)


# takes input vector, and computes Σⱼ = wⱼ'x + bⱼ  and  Oⱼ = A(Σⱼ)
function feedforward!(layer::Layer, inputs::VecF)
	x = vcat(inputs, 1.0)  # add bias to the end
	Float64[feedforward!(node, x) for node in layer.nodes]
	# layer.x = vcat(inputs, 1.0)  # add bias to the end
	# layer.Σ = layer.w' * layer.x
	# activate(layer)
end

δ(layer::Layer, j::Int) = layer.nodes[j].δ
δ(layer::Layer) = Float64[δ(layer, j) for j in 1:layer.nout]

function hiddenδ!(layer::Layer, nextlayer::Layer)
	for j in 1:layer.nout
		weightedNextδ = dot(δ(nextlayer), Float64[node.w[j] for node in nextlayer.nodes])
		# layer.δ[j] = hiddenδ(layer.nodes[j], weightedNextδ)
		hiddenδ!(layer.nodes[j], weightedNextδ)
	end
end

function finalδ!(layer::Layer, errors::VecF)
	# layer.δ = map(finalδ, layer.nodes, errors)
	for j in 1:layer.nout
		finalδ!(layer.nodes[j], errors[j])
	end
end

function update!(layer::Layer, η::Float64, μ::Float64)
	for node in layer.nodes
		# update!(node, layer.δ, η, μ)
		update!(node, η, μ)
	end
end

# # given next layer's δ, compute this hidden layer's δ  (this is the recursive calculation based on the chain rule)
# function hiddenδ!(layer::Layer, nextδ::VecF, nextw::MatF)
# 	layer.δ = activateprime(layer) .* (nextw * nextδ)[1:end-1]
# 	layer.δ, layer.w
# end

# # compute the δ for the final layer... uses errors
# function finalδ!(layer::Layer, errors::VecF)
# 	layer.δ = -errors .* activateprime(layer)
# 	layer.δ, layer.w
# end

# function update!(layer::Layer, η::Float64, μ::Float64)
# 	dw = -η * layer.x * layer.δ' + μ * layer.dw
# 	layer.w += dw
# 	layer.dw = dw
# end