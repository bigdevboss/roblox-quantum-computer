local module = {}

local function deutsch_circuit(oracle_type)
	local Circuit = require(script.Parent.Parent.Core.Circuit)
	local circuit = Circuit.new(2)
	circuit:add_gate("X", {1})
	circuit:add_gate("H", {0})
	circuit:add_gate("H", {1})
	if oracle_type == "balanced" then
		circuit:add_gate("CNOT", {0, 1})
	end
	circuit:add_gate("H", {0})
	return circuit
end

function module.get_circuit(oracle_type)
	return deutsch_circuit(oracle_type)
end

return module
