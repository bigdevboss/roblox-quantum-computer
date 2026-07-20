local module = {}

function module.create(parent)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuantumShellGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = parent

	local toggleButton = Instance.new("ImageButton")
	toggleButton.Size = UDim2.new(0, 32, 0, 32)
	toggleButton.Position = UDim2.new(1, -40, 0, 10)
	toggleButton.AnchorPoint = Vector2.new(1, 0)
	toggleButton.BackgroundTransparency = 1
	toggleButton.Image = "rbxassetid://121100706765759"
	toggleButton.ZIndex = 10
	toggleButton.Parent = screenGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 600, 0, 360)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -180)
	mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	mainFrame.BorderSizePixel = 1
	mainFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.Visible = true
	mainFrame.Parent = screenGui

	local outputFrame = Instance.new("Frame")
	outputFrame.Size = UDim2.new(1, 0, 1, -24)
	outputFrame.Position = UDim2.new(0, 0, 0, 0)
	outputFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	outputFrame.BorderSizePixel = 0
	outputFrame.Parent = mainFrame

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -6, 1, -4)
	scrollFrame.Position = UDim2.new(0, 3, 0, 2)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.Parent = outputFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 0)
	listLayout.Parent = scrollFrame

	local inputFrame = Instance.new("Frame")
	inputFrame.Size = UDim2.new(1, 0, 0, 20)
	inputFrame.Position = UDim2.new(0, 0, 1, -20)
	inputFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	inputFrame.BorderSizePixel = 1
	inputFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
	inputFrame.Parent = mainFrame

	local prefixLabel = Instance.new("TextLabel")
	prefixLabel.Size = UDim2.new(0, 30, 1, 0)
	prefixLabel.Position = UDim2.new(0, 6, 0, 0)
	prefixLabel.BackgroundTransparency = 1
	prefixLabel.Font = Enum.Font.RobotoMono
	prefixLabel.Text = "~#"
	prefixLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	prefixLabel.TextSize = 13
	prefixLabel.TextXAlignment = Enum.TextXAlignment.Left
	prefixLabel.Parent = inputFrame

	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(1, -40, 1, 0)
	inputBox.Position = UDim2.new(0, 36, 0, 0)
	inputBox.BackgroundTransparency = 1
	inputBox.Font = Enum.Font.RobotoMono
	inputBox.Text = ""
	inputBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	inputBox.TextSize = 13
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.PlaceholderText = ""
	inputBox.ClearTextOnFocus = false
	inputBox.Parent = inputFrame

	local cursor = Instance.new("Frame")
	cursor.Size = UDim2.new(0, 8, 0, 14)
	cursor.Position = UDim2.new(0, 1, 0, 3)
	cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cursor.BorderSizePixel = 0
	cursor.Visible = false
	cursor.Parent = inputBox

	local blinkCounter = 0
	game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		blinkCounter = blinkCounter + deltaTime
		if blinkCounter >= 0.6 then
			blinkCounter = 0
			cursor.Visible = not cursor.Visible
		end
	end)

	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		cursor.Position = UDim2.new(0, inputBox.TextBounds.X + 1, 0, 3)
	end)

	inputBox.Focused:Connect(function()
		cursor.Visible = true
		blinkCounter = 0
	end)
	inputBox.FocusLost:Connect(function()
		cursor.Visible = false
	end)

	local function addLine(text, color)
		local line = Instance.new("TextLabel")
		line.Size = UDim2.new(1, -10, 0, 0)
		line.BackgroundTransparency = 1
		line.Font = Enum.Font.RobotoMono
		line.Text = text
		line.TextColor3 = color or Color3.fromRGB(220, 220, 220)
		line.TextSize = 13
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.TextYAlignment = Enum.TextYAlignment.Top
		line.TextWrapped = true
		line.AutomaticSize = Enum.AutomaticSize.Y
		line.Selectable = true
		line.Parent = scrollFrame
		return line
	end

	local function printLine(text, color)
		addLine(text, color)
		task.spawn(function()
			game:GetService("RunService").RenderStepped:Wait()
			scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
		end)
	end

	local function printMultiline(text, color)
		for line in text:gmatch("[^\r\n]+") do
			addLine(line, color)
		end
		task.spawn(function()
			game:GetService("RunService").RenderStepped:Wait()
			scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
		end)
	end

	local commandHistory = {}
	local historyIndex = 0
	local commandCallback = nil

	local function onCommand(callback)
		commandCallback = callback
	end

	local draggingTerminal = false
	local terminalDragStart = nil
	local terminalStartPos = nil

	mainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and mainFrame.Visible then
			draggingTerminal = true
			terminalDragStart = input.Position
			terminalStartPos = mainFrame.Position
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if draggingTerminal and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - terminalDragStart
			mainFrame.Position = UDim2.new(
				terminalStartPos.X.Scale,
				terminalStartPos.X.Offset + delta.X,
				terminalStartPos.Y.Scale,
				terminalStartPos.Y.Offset + delta.Y
			)
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingTerminal = false
		end
	end)

	local draggingToggle = false
	local toggleDragStart = nil
	local toggleStartPos = nil

	toggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingToggle = true
			toggleDragStart = input.Position
			toggleStartPos = toggleButton.Position
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if draggingToggle and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - toggleDragStart
			toggleButton.Position = UDim2.new(
				toggleStartPos.X.Scale,
				toggleStartPos.X.Offset + delta.X,
				toggleStartPos.Y.Scale,
				toggleStartPos.Y.Offset + delta.Y
			)
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingToggle = false
		end
	end)

	toggleButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = not mainFrame.Visible
		if mainFrame.Visible then
			inputBox:CaptureFocus()
		end
	end)

	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local raw = inputBox.Text:match("^%s*(.-)%s*$")
			if raw ~= "" then
				table.insert(commandHistory, raw)
				historyIndex = #commandHistory
				printLine("~# " .. raw)
				if commandCallback then
					commandCallback(raw)
				end
			end
			inputBox.Text = ""
		end
	end)

	inputBox.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Up then
			if historyIndex > 0 then
				inputBox.Text = commandHistory[historyIndex]
				historyIndex = math.max(0, historyIndex - 1)
			end
		elseif input.KeyCode == Enum.KeyCode.Down then
			if historyIndex < #commandHistory then
				historyIndex = historyIndex + 1
				inputBox.Text = commandHistory[historyIndex]
			else
				inputBox.Text = ""
				historyIndex = #commandHistory
			end
		end
	end)

	task.wait(0.3)
	inputBox:CaptureFocus()

	return {
		printLine = printLine,
		printMultiline = printMultiline,
		onCommand = onCommand,
		screenGui = screenGui,
	}
end

return module
