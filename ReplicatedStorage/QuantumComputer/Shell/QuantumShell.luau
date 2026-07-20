local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local QuantumComputer = ReplicatedStorage:WaitForChild("QuantumComputer")
local Core = QuantumComputer:WaitForChild("Core")
local QState = require(Core.QState)
local Circuit = require(Core.Circuit)
local ShellGUI = require(QuantumComputer.Shell.ShellGUI)
local Examples = QuantumComputer.Examples

local module = {}

function module.start()
	local gui = ShellGUI.create(playerGui)

	local currentCircuit = nil
	local currentState = nil

	local function printError(msg)
		gui.printLine(msg, Color3.fromRGB(255, 80, 80))
	end

	local function setCircuit(circuit)
		currentCircuit = circuit
		currentState = nil
		gui.printLine("[+] Circuit loaded. " .. #circuit.gates .. " gates.")
	end

	local commands = {}

	commands["help"] = function()
		gui.printLine("Quantum Shell Commands:")
		gui.printLine("qubits <n>             - init new circuit (max 20)")
		gui.printLine("init <zero|plus>       - set initial state")
		gui.printLine("gate <name> <targs>    - add gate (H,X,Y,Z,S,T,SDG,TDG,RX,RY,RZ,U3,CNOT,CZ,CH,CY,SWAP,CRZ,TOFFOLI,CSWAP,CCZ,MCX)")
		gui.printLine("   U3: gate u3 q theta phi lambda")
		gui.printLine("   MCX: gate mcx c1 c2 ... target (last is target)")
		gui.printLine("qft <qubits>           - add QFT (e.g. qft 0,1,2)")
		gui.printLine("list                   - show circuit")
		gui.printLine("run                    - execute circuit")
		gui.printLine("state                  - print state vector")
		gui.printLine("probs                  - probabilities")
		gui.printLine("measure [qubit]        - measure qubit or all")
		gui.printLine("bloch <qubit>          - Bloch sphere visualization")
		gui.printLine("load <example>         - teleport / deutsch_constant / deutsch_balanced")
		gui.printLine("clear                  - clear terminal")
		gui.printLine("reset                  - reset state to |0...0>")
		gui.printLine("bench <n> <type> [iter]- benchmark (ghz, qft, hadamard, measure)")
		gui.printLine("Use ';' to separate multiple commands.")
	end

	commands["qubits"] = function(args)
		local n = tonumber(args)
		if not n or n < 1 or n > 20 then
			printError("[-] Invalid qubit count (1-20).")
			return
		end
		currentCircuit = Circuit.new(n)
		currentState = nil
		gui.printLine("[+] New circuit with " .. n .. " qubits.")
	end

	commands["init"] = function(args)
		if not currentCircuit then
			printError("[-] No circuit. Use 'qubits' first.")
			return
		end
		currentCircuit = Circuit.new(currentCircuit.n)
		if args == "plus" then
			for q = 0, currentCircuit.n - 1 do
				currentCircuit:add_gate("H", {q})
			end
			gui.printLine("[+] Initialized to |+>^n.")
		else
			gui.printLine("[+] Initialized to |0>^n.")
		end
	end

	commands["gate"] = function(args)
		if not currentCircuit then
			printError("[-] No circuit. Use 'qubits' first.")
			return
		end
		local parts = {}
		for part in args:gmatch("%S+") do
			table.insert(parts, part)
		end
		local name = parts[1] and parts[1]:upper()
		if not name then
			printError("[-] Gate name required.")
			return
		end
		local targets = {}
		local params = {}
		local i = 2
		while i <= #parts and tonumber(parts[i]) do
			table.insert(targets, tonumber(parts[i]))
			i = i + 1
		end
		while i <= #parts and tonumber(parts[i]) do
			table.insert(params, tonumber(parts[i]))
			i = i + 1
		end

		if name == "CNOT" or name == "CZ" or name == "CH" or name == "CY" or name == "SWAP" or name == "CRZ" then
			if name == "CRZ" then
				if #targets ~= 2 or #params ~= 1 then
					printError("[-] CRZ requires 2 targets and 1 angle.")
					return
				end
			else
				if #targets ~= 2 then
					printError("[-] " .. name .. " requires 2 targets.")
					return
				end
			end
			currentCircuit:add_gate(name, targets, params)
		elseif name == "TOFFOLI" or name == "CSWAP" or name == "CCZ" then
			if #targets ~= 3 then
				printError("[-] " .. name .. " requires 3 targets.")
				return
			end
			currentCircuit:add_gate(name, targets, params)
		elseif name == "MCX" then
			if #targets < 2 then
				printError("[-] MCX requires at least 2 targets (controls + target).")
				return
			end
			currentCircuit:add_gate(name, targets)
		elseif name == "U3" then
			if #targets ~= 1 or #params ~= 3 then
				printError("[-] U3 requires 1 target and 3 angles (theta, phi, lambda).")
				return
			end
			currentCircuit:add_gate(name, targets, params)
		elseif name == "RX" or name == "RY" or name == "RZ" then
			if #targets ~= 1 or #params ~= 1 then
				printError("[-] " .. name .. " requires 1 target and 1 angle.")
				return
			end
			currentCircuit:add_gate(name, targets, params)
		else
			if #targets ~= 1 then
				printError("[-] Single-qubit gate requires 1 target.")
				return
			end
			currentCircuit:add_gate(name, targets)
		end
		gui.printLine("[+] Added " .. name .. " " .. table.concat(targets, ",") .. (#params>0 and " ("..table.concat(params, ",")..")" or ""))
	end

	commands["qft"] = function(args)
		if not currentCircuit then
			printError("[-] No circuit.")
			return
		end
		local qubits = {}
		for part in args:gmatch("%d+") do
			table.insert(qubits, tonumber(part))
		end
		if #qubits == 0 then
			printError("[-] Specify qubit indices.")
			return
		end
		currentCircuit:add_qft(qubits)
		gui.printLine("[+] QFT added on qubits " .. table.concat(qubits, ","))
	end

	commands["list"] = function()
		if not currentCircuit or #currentCircuit.gates == 0 then
			gui.printLine("No gates.")
		else
			gui.printLine("Circuit:")
			gui.printLine(currentCircuit:to_string())
		end
	end

	commands["run"] = function()
		if not currentCircuit then
			printError("[-] No circuit.")
			return
		end
		currentState = currentCircuit:run()
		gui.printLine("[+] Circuit executed.")
	end

	commands["state"] = function()
		if not currentState then
			printError("[-] No state. Run circuit first.")
			return
		end
		local str = currentState:to_string()
		if str == "" then str = "(all zero)" end
		gui.printMultiline(str)
	end

	commands["probs"] = function()
		if not currentState then
			printError("[-] No state.")
			return
		end
		local probs = currentState:get_probabilities()
		local lines = {}
		for i = 0, currentState.size - 1 do
			local prob = probs[i+1]
			if prob > 1e-10 then
				local bitstring = ""
				for q = currentState.n - 1, 0, -1 do
					bitstring = bitstring .. math.floor(i / (2^q)) % 2
				end
				table.insert(lines, "|" .. bitstring .. ">: " .. string.format("%.4f%%", prob*100))
			end
		end
		gui.printMultiline(table.concat(lines, "\n"))
	end

	commands["measure"] = function(args)
		if not currentState then
			printError("[-] No state.")
			return
		end
		if args == "" then
			local result = currentState:measure_all()
			gui.printLine("Measured: |" .. result .. ">")
		else
			local q = tonumber(args)
			if not q then
				printError("[-] Invalid qubit index.")
				return
			end
			local bit = currentState:measure(q)
			gui.printLine("Qubit " .. q .. " measured: " .. bit)
		end
	end

	commands["bloch"] = function(args)
		local q = tonumber(args)
		if not q then
			printError("[-] Usage: bloch <qubit>")
			return
		end
		if not currentState then
			printError("[-] No state.")
			return
		end
		if q >= currentState.n then
			printError("[-] Qubit index out of range.")
			return
		end
		local x, y, z = currentState:get_bloch_coords(q)
		if not x then
			printError("[-] Cannot determine Bloch vector.")
			return
		end
		gui.printLine(string.format("Bloch vector: (%.4f, %.4f, %.4f)", x, y, z))
		local workspace = game:GetService("Workspace")
		local blochModel = workspace:FindFirstChild("BlochSphere")
		if blochModel then
			blochModel:Destroy()
		end
		blochModel = Instance.new("Model")
		blochModel.Name = "BlochSphere"
		local sphere = Instance.new("Part")
		sphere.Shape = Enum.PartType.Ball
		sphere.Size = Vector3.new(4, 4, 4)
		sphere.Transparency = 0.5
		sphere.Material = Enum.Material.Glass
		sphere.Anchored = true
		sphere.Position = Vector3.new(0, 4, 0)
		sphere.Color = Color3.fromRGB(100, 100, 255)
		sphere.Parent = blochModel
		local arrow = Instance.new("Part")
		arrow.Size = Vector3.new(0.2, 0.2, 2)
		arrow.Anchored = true
		arrow.Color = Color3.fromRGB(255, 0, 0)
		arrow.Material = Enum.Material.Neon
		arrow.Position = Vector3.new(0, 4, 0) + Vector3.new(x, y, z) * 2
		arrow.CFrame = CFrame.lookAt(Vector3.new(0, 4, 0), Vector3.new(0, 4, 0) + Vector3.new(x, y, z))
		arrow.Parent = blochModel
		blochModel.Parent = workspace
		gui.printLine("[+] Bloch sphere visualized.")
	end

	commands["load"] = function(args)
		local exampleName = args:match("%S+")
		if not exampleName then
			printError("[-] Specify example: teleport, deutsch_constant, deutsch_balanced")
			return
		end
		if exampleName == "teleport" then
			local circuit = Examples.Teleport.get_circuit()
			setCircuit(circuit)
		elseif exampleName == "deutsch_constant" then
			local circuit = Examples.DeutschJozsa.get_circuit("constant")
			setCircuit(circuit)
		elseif exampleName == "deutsch_balanced" then
			local circuit = Examples.DeutschJozsa.get_circuit("balanced")
			setCircuit(circuit)
		else
			printError("[-] Unknown example.")
		end
	end

	commands["clear"] = function()
		for _, child in ipairs(gui.screenGui:GetDescendants()) do
			if child:IsA("ScrollingFrame") then
				for _, line in ipairs(child:GetChildren()) do
					if line:IsA("TextLabel") then
						line:Destroy()
					end
				end
				break
			end
		end
	end

	commands["reset"] = function()
		if not currentCircuit then
			printError("[-] No circuit.")
			return
		end
		currentState = nil
		gui.printLine("[+] State reset to initial.")
	end

	commands["bench"] = function(args)
		local parts = {}
		for part in args:gmatch("%S+") do
			table.insert(parts, part)
		end
		local n = tonumber(parts[1])
		local testType = parts[2] and parts[2]:lower() or "ghz"
		local iterations = tonumber(parts[3]) or 100

		if not n or n < 1 or n > 20 then
			printError("[-] Invalid qubit count (1-20).")
			return
		end
		if iterations < 1 or iterations > 1000000 then
			printError("[-] Iterations must be between 1 and 1,000,000.")
			return
		end

		local circuit = Circuit.new(n)
		if testType == "ghz" then
			circuit:add_gate("H", {0})
			for q = 0, n - 2 do
				circuit:add_gate("CNOT", {q, q + 1})
			end
		elseif testType == "qft" then
			local qubits = {}
			for q = 0, n - 1 do
				table.insert(qubits, q)
			end
			circuit:add_qft(qubits)
		elseif testType == "hadamard" then
			for q = 0, n - 1 do
				circuit:add_gate("H", {q})
			end
		elseif testType == "measure" then
			circuit:add_gate("H", {0})
			for q = 0, n - 2 do
				circuit:add_gate("CNOT", {q, q + 1})
			end
		else
			printError("[-] Unknown test type. Use: ghz, qft, hadamard, measure")
			return
		end

		gui.printLine("[Benchmark] " .. n .. " qubits, " .. testType .. ", " .. iterations .. " iterations")

		local start = os.clock()
		if testType == "measure" then
			local state = circuit:run()
			local probs = state:get_probabilities()
			local cum = {}
			local total = 0
			for i = 1, #probs do
				total = total + probs[i]
				cum[i] = total
			end
			for _ = 1, iterations do
				local r = math.random()
				local outcome = 1
				while outcome <= #cum and r > cum[outcome] do
					outcome = outcome + 1
				end
			end
		else
			for _ = 1, iterations do
				circuit:run()
			end
		end
		local elapsed = os.clock() - start

		local avg = (elapsed / iterations) * 1000
		gui.printLine(string.format("[Benchmark] Total: %.4f sec, Avg: %.4f ms per run", elapsed, avg))
	end

	gui.onCommand(function(raw)
		local executed = false
		for subcommand in raw:gmatch("[^;]+") do
			local trimmed = subcommand:match("^%s*(.-)%s*$")
			if trimmed ~= "" then
				if executed then
					gui.printLine("~# " .. trimmed)
				end
				local cmd, args = trimmed:match("^(%S+)%s*(.*)")
				if not cmd then
					cmd = trimmed:lower()
					args = ""
				else
					cmd = cmd:lower()
				end
				if commands[cmd] then
					commands[cmd](args)
				else
					printError("? " .. cmd)
				end
				executed = true
			end
		end
	end)

	gui.printLine("Quantum Shell v5.1. Type 'help'. Max qubits: 20")
end

return module
