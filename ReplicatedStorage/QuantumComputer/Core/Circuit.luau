local QState = require(script.Parent.QState)

local Circuit = {}
Circuit.__index = Circuit

function Circuit.new(n)
	local self = setmetatable({}, Circuit)
	self.n = n
	self.gates = {}
	return self
end

function Circuit:add_gate(name, targets, params)
	params = params or {}
	table.insert(self.gates, {name = name, targets = targets, params = params})
end

function Circuit:add_qft(qubits)
	for i = #qubits, 1, -1 do
		local q = qubits[i]
		self:add_gate("H", {q})
		for j = i - 1, 1, -1 do
			local control = qubits[j]
			local angle = math.pi / (2 ^ (i - j))
			self:add_gate("CRZ", {control, q}, {angle})
		end
	end
	for i = 1, math.floor(#qubits / 2) do
		self:add_gate("SWAP", {qubits[i], qubits[#qubits - i + 1]})
	end
end

function Circuit:run()
	local qs = QState.new(self.n)
	for _, gate in ipairs(self.gates) do
		local name = gate.name
		local t = gate.targets
		local p = gate.params
		if name == "H" then
			qs:apply_h(t[1])
		elseif name == "X" then
			qs:apply_x(t[1])
		elseif name == "Y" then
			qs:apply_y(t[1])
		elseif name == "Z" then
			qs:apply_z(t[1])
		elseif name == "S" then
			qs:apply_s(t[1])
		elseif name == "T" then
			qs:apply_t(t[1])
		elseif name == "RX" then
			qs:apply_rx(t[1], p[1])
		elseif name == "RY" then
			qs:apply_ry(t[1], p[1])
		elseif name == "RZ" then
			qs:apply_rz(t[1], p[1])
		elseif name == "CNOT" then
			qs:apply_cnot(t[1], t[2])
		elseif name == "CZ" then
			qs:apply_cz(t[1], t[2])
		elseif name == "SWAP" then
			qs:apply_swap(t[1], t[2])
		elseif name == "CRZ" then
			qs:apply_crz(t[1], t[2], p[1])
		elseif name == "TOFFOLI" then
			qs:apply_toffoli(t[1], t[2], t[3])
		end
	end
	return qs
end

function Circuit:to_string()
	local lines = {}
	for i, gate in ipairs(self.gates) do
		local line = gate.name .. " " .. table.concat(gate.targets, ",")
		if #gate.params > 0 then
			line = line .. " (" .. string.format("%.4f", gate.params[1]) .. ")"
		end
		lines[i] = line
	end
	return table.concat(lines, "\n")
end

return Circuit
