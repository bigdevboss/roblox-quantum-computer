local module = {}

function module.get_circuit()
	local Circuit = require(script.Parent.Parent.Core.Circuit)
	local circuit = Circuit.new(3)
	circuit:add_gate("H", {1})
	circuit:add_gate("CNOT", {1, 2})
	circuit:add_gate("CNOT", {0, 1})
	circuit:add_gate("H", {0})
	return circuit
end

return module
