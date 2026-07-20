local QState = {}
QState.__index = QState

function QState.new(n)
	local self = setmetatable({}, QState)
	self.n = n
	self.size = 2 ^ n
	self.reals = table.create(self.size, 0)
	self.imags = table.create(self.size, 0)
	self.reals[1] = 1
	return self
end

function QState:apply_h(q)
	local mask = 2 ^ q
	local inv_sqrt2 = 0.7071067811865476
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 0 then
			local j = i + mask
			local idx_i = i + 1
			local idx_j = j + 1
			local ar = self.reals[idx_i]
			local ai = self.imags[idx_i]
			local br = self.reals[idx_j]
			local bi = self.imags[idx_j]
			local t1r = ar + br
			local t1i = ai + bi
			local t2r = ar - br
			local t2i = ai - bi
			self.reals[idx_i] = t1r * inv_sqrt2
			self.imags[idx_i] = t1i * inv_sqrt2
			self.reals[idx_j] = t2r * inv_sqrt2
			self.imags[idx_j] = t2i * inv_sqrt2
		end
	end
end

function QState:apply_x(q)
	local mask = 2 ^ q
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 0 then
			local j = i + mask
			local idx_i = i + 1
			local idx_j = j + 1
			self.reals[idx_i], self.reals[idx_j] = self.reals[idx_j], self.reals[idx_i]
			self.imags[idx_i], self.imags[idx_j] = self.imags[idx_j], self.imags[idx_i]
		end
	end
end

function QState:apply_z(q)
	local mask = 2 ^ q
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 1 then
			local idx = i + 1
			self.reals[idx] = -self.reals[idx]
			self.imags[idx] = -self.imags[idx]
		end
	end
end

function QState:apply_y(q)
	local mask = 2 ^ q
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 0 then
			local j = i + mask
			local idx_i = i + 1
			local idx_j = j + 1
			local ar = self.reals[idx_i]
			local ai = self.imags[idx_i]
			local br = self.reals[idx_j]
			local bi = self.imags[idx_j]
			self.reals[idx_i] = bi
			self.imags[idx_i] = -br
			self.reals[idx_j] = -ai
			self.imags[idx_j] = ar
		end
	end
end

function QState:apply_s(q)
	local mask = 2 ^ q
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 1 then
			local idx = i + 1
			local re = self.reals[idx]
			local im = self.imags[idx]
			self.reals[idx] = -im
			self.imags[idx] = re
		end
	end
end

function QState:apply_t(q)
	local mask = 2 ^ q
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 1 then
			local idx = i + 1
			local re = self.reals[idx]
			local im = self.imags[idx]
			self.reals[idx] = (re - im) * 0.7071067811865476
			self.imags[idx] = (re + im) * 0.7071067811865476
		end
	end
end

function QState:apply_rx(q, angle)
	local mask = 2 ^ q
	local half = angle / 2
	local c = math.cos(half)
	local s = math.sin(half)
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 0 then
			local j = i + mask
			local idx_i = i + 1
			local idx_j = j + 1
			local ar = self.reals[idx_i]
			local ai = self.imags[idx_i]
			local br = self.reals[idx_j]
			local bi = self.imags[idx_j]
			self.reals[idx_i] = c*ar + s*bi
			self.imags[idx_i] = c*ai - s*br
			self.reals[idx_j] = c*br + s*ai
			self.imags[idx_j] = c*bi - s*ar
		end
	end
end

function QState:apply_ry(q, angle)
	local mask = 2 ^ q
	local half = angle / 2
	local c = math.cos(half)
	local s = math.sin(half)
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 0 then
			local j = i + mask
			local idx_i = i + 1
			local idx_j = j + 1
			local ar = self.reals[idx_i]
			local ai = self.imags[idx_i]
			local br = self.reals[idx_j]
			local bi = self.imags[idx_j]
			self.reals[idx_i] = c*ar - s*br
			self.imags[idx_i] = c*ai - s*bi
			self.reals[idx_j] = s*ar + c*br
			self.imags[idx_j] = s*ai + c*bi
		end
	end
end

function QState:apply_rz(q, angle)
	local mask = 2 ^ q
	local half = angle / 2
	local c = math.cos(half)
	local s = math.sin(half)
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 0 then
			local idx_i = i + 1
			local re = self.reals[idx_i]
			local im = self.imags[idx_i]
			self.reals[idx_i] = re*c + im*s
			self.imags[idx_i] = im*c - re*s
		else
			local idx_j = i + 1
			local re = self.reals[idx_j]
			local im = self.imags[idx_j]
			self.reals[idx_j] = re*c - im*s
			self.imags[idx_j] = im*c + re*s
		end
	end
end

function QState:apply_cnot(control, target)
	local cmask = 2 ^ control
	local tmask = 2 ^ target
	for i = 0, self.size - 1 do
		if math.floor(i / cmask) % 2 == 1 then
			if math.floor(i / tmask) % 2 == 0 then
				local j = i + tmask
				local idx_i = i + 1
				local idx_j = j + 1
				self.reals[idx_i], self.reals[idx_j] = self.reals[idx_j], self.reals[idx_i]
				self.imags[idx_i], self.imags[idx_j] = self.imags[idx_j], self.imags[idx_i]
			end
		end
	end
end

function QState:apply_cz(control, target)
	local cmask = 2 ^ control
	local tmask = 2 ^ target
	for i = 0, self.size - 1 do
		if math.floor(i / cmask) % 2 == 1 and math.floor(i / tmask) % 2 == 1 then
			local idx = i + 1
			self.reals[idx] = -self.reals[idx]
			self.imags[idx] = -self.imags[idx]
		end
	end
end

function QState:apply_swap(q1, q2)
	local mask1 = 2 ^ q1
	local mask2 = 2 ^ q2
	for i = 0, self.size - 1 do
		local b1 = math.floor(i / mask1) % 2
		local b2 = math.floor(i / mask2) % 2
		if b1 == 0 and b2 == 1 then
			local j = i - mask2 + mask1
			local idx_i = i + 1
			local idx_j = j + 1
			self.reals[idx_i], self.reals[idx_j] = self.reals[idx_j], self.reals[idx_i]
			self.imags[idx_i], self.imags[idx_j] = self.imags[idx_j], self.imags[idx_i]
		end
	end
end

function QState:apply_crz(control, target, angle)
	local cmask = 2 ^ control
	local tmask = 2 ^ target
	local half = angle / 2
	local c = math.cos(half)
	local s = math.sin(half)
	for i = 0, self.size - 1 do
		if math.floor(i / cmask) % 2 == 1 and math.floor(i / tmask) % 2 == 1 then
			local idx = i + 1
			local re = self.reals[idx]
			local im = self.imags[idx]
			self.reals[idx] = re*c - im*s
			self.imags[idx] = im*c + re*s
		end
	end
end

function QState:apply_toffoli(control1, control2, target)
	local cmask1 = 2 ^ control1
	local cmask2 = 2 ^ control2
	local tmask = 2 ^ target
	for i = 0, self.size - 1 do
		local c1 = math.floor(i / cmask1) % 2
		local c2 = math.floor(i / cmask2) % 2
		if c1 == 1 and c2 == 1 then
			local t = math.floor(i / tmask) % 2
			if t == 0 then
				local j = i + tmask
				local idx_i = i + 1
				local idx_j = j + 1
				self.reals[idx_i], self.reals[idx_j] = self.reals[idx_j], self.reals[idx_i]
				self.imags[idx_i], self.imags[idx_j] = self.imags[idx_j], self.imags[idx_i]
			end
		end
	end
end

function QState:measure(q)
	local mask = 2 ^ q
	local prob0 = 0
	for i = 0, self.size - 1 do
		if math.floor(i / mask) % 2 == 0 then
			local idx = i + 1
			prob0 = prob0 + self.reals[idx] * self.reals[idx] + self.imags[idx] * self.imags[idx]
		end
	end
	local r = math.random()
	local result
	if r < prob0 then
		result = 0
		local norm = 1 / math.sqrt(prob0)
		for i = 0, self.size - 1 do
			if math.floor(i / mask) % 2 == 1 then
				local idx = i + 1
				self.reals[idx] = 0
				self.imags[idx] = 0
			else
				local idx = i + 1
				self.reals[idx] = self.reals[idx] * norm
				self.imags[idx] = self.imags[idx] * norm
			end
		end
	else
		result = 1
		local prob1 = 1 - prob0
		local norm = 1 / math.sqrt(prob1)
		for i = 0, self.size - 1 do
			if math.floor(i / mask) % 2 == 0 then
				local idx = i + 1
				self.reals[idx] = 0
				self.imags[idx] = 0
			else
				local idx = i + 1
				self.reals[idx] = self.reals[idx] * norm
				self.imags[idx] = self.imags[idx] * norm
			end
		end
	end
	return result
end

function QState:measure_all()
	local remaining = self:clone()
	local result = {}
	for q = self.n - 1, 0, -1 do
		result[#result + 1] = remaining:measure(q)
	end
	return table.concat(result)
end

function QState:clone()
	local new = setmetatable({}, QState)
	new.n = self.n
	new.size = self.size
	new.reals = table.create(self.size, 0)
	new.imags = table.create(self.size, 0)
	for i = 1, self.size do
		new.reals[i] = self.reals[i]
		new.imags[i] = self.imags[i]
	end
	return new
end

function QState:get_probabilities()
	local probs = table.create(self.size, 0)
	for i = 1, self.size do
		probs[i] = self.reals[i] * self.reals[i] + self.imags[i] * self.imags[i]
	end
	return probs
end

function QState:to_string()
	local parts = {}
	for i = 0, self.size - 1 do
		local idx = i + 1
		local prob = self.reals[idx] * self.reals[idx] + self.imags[idx] * self.imags[idx]
		if prob > 1e-10 then
			local bitstring = ""
			for q = self.n - 1, 0, -1 do
				bitstring = bitstring .. math.floor(i / (2^q)) % 2
			end
			local re = self.reals[idx]
			local im = self.imags[idx]
			local re_str = string.format("%.4f", re)
			local im_str = string.format("%.4f", im)
			parts[#parts + 1] = "|" .. bitstring .. ">: " .. re_str .. (im >= 0 and "+" or "") .. im_str .. "i"
		end
	end
	return table.concat(parts, "\n")
end

function QState:get_bloch_coords(q)
	local mask = 2 ^ q
	local a0r, a0i = 0, 0
	local a1r, a1i = 0, 0
	for i = 0, self.size - 1 do
		local idx = i + 1
		if math.floor(i / mask) % 2 == 0 then
			a0r = a0r + self.reals[idx]
			a0i = a0i + self.imags[idx]
		else
			a1r = a1r + self.reals[idx]
			a1i = a1i + self.imags[idx]
		end
	end
	local prob0 = a0r*a0r + a0i*a0i
	local prob1 = a1r*a1r + a1i*a1i
	local eps = 1e-10
	if prob0 < eps and prob1 < eps then
		return nil
	end
	if prob0 < eps then
		return 0, 0, -1
	end
	if prob1 < eps then
		return 0, 0, 1
	end
	local theta = 2 * math.acos(math.sqrt(prob0))
	local phi = math.atan2(a1i, a1r) - math.atan2(a0i, a0r)
	local x = math.sin(theta) * math.cos(phi)
	local y = math.sin(theta) * math.sin(phi)
	local z = math.cos(theta)
	return x, y, z
end

return QState
