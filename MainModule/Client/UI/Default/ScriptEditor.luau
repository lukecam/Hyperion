client,service = nil,nil
return function(data, env)
	if env then
		setfenv(1, env)
	end

	local Save = nil
	local Run = nil
	local lineTextBoxes = {}
	local lineHighlights = {}
	local lineHeight = 20
	local lineNumberWidth = 26
	local currentFocusedLine = nil
local currentFocusedTextBox = nil
local currentFocusedLineNumber = nil

local UserInputService = game:GetService("UserInputService")

	local window = client.UI.Make("Window",{
		Title = `Editing - {data.Name}`;
		Name = "CommandBox";
		Icon = client.MatIcons.Code;
		Size  = {500, 300};
		MinSize = {300,250};
		OnClose = function()
			Save()
		end,
	})

	local Frame: ScrollingFrame = window:Add("ScrollingFrame",{
		Name = "Editor";
		Size = UDim2.new(1, -10, 1, -10);
		BackgroundTransparency = 1;
	})

	local LinesContainer = Frame:Add("Frame",{
		Name = "LinesContainer";
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
		BackgroundTransparency = 1;
	})

	local BackgroundButton = Frame:Add("TextButton",{
		Name = "BackgroundClick";
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
		BackgroundTransparency = 1;
		Text = "";
		ZIndex = 0;
	})

	BackgroundButton.MouseButton1Click:Connect(function()
		if #lineTextBoxes > 0 then
			lineTextBoxes[#lineTextBoxes]:CaptureFocus()
		end
		LinesContainer.ZIndex = 1
	end)

	local function getAllText()
		local texts = {}
		for i = 1, #lineTextBoxes do
			texts[i] = lineTextBoxes[i].Text
		end
		return table.concat(texts, "\n")
	end

	local function updateCanvasSize()
		Frame.CanvasSize = UDim2.new(0, 0, 0, #lineTextBoxes * lineHeight + 10)
	end

	local function createLine(lineNumber, text)
		local yPos = (lineNumber - 1) * lineHeight

		local lineFrame = LinesContainer:Add("Frame",{
			Name = `Line_{lineNumber}`;
			Size = UDim2.new(1, 0, 0, lineHeight);
			Position = UDim2.new(0, 0, 0, yPos);
			BackgroundColor3 = Color3.fromRGB(60, 60, 60);
			BackgroundTransparency = 1;
		})

		local lineNumberLabel = lineFrame:Add("TextLabel",{
			Name = "LineNumber";
			Size = UDim2.new(0, lineNumberWidth, 1, 0);
			Position = UDim2.new(0, 0, 0, 0);
			BackgroundTransparency = 1;
			Text = tostring(lineNumber);
			TextColor3 = Color3.fromRGB(128, 128, 128);
			TextXAlignment = Enum.TextXAlignment.Right;
			Font = Enum.Font.Code;
			TextSize = 12;
		})

		local textBox = lineFrame:Add("TextBox",{
			Name = "LineText";
			Size = UDim2.new(1, -lineNumberWidth - 5, 1, 0);
			Position = UDim2.new(0, lineNumberWidth + 5, 0, 0);
			BackgroundTransparency = 1;
			Text = (text or ""):gsub("[\r\n]", "");
			PlaceholderText = "";
			TextXAlignment = Enum.TextXAlignment.Left;
			ClearTextOnFocus = false;
			Font = Enum.Font.Code;
			TextSize = 14;
		})

		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			local newText = textBox.Text
			if string.find(newText, "\n") then
				local lines = string.split(newText, "\n")
				textBox.Text = lines[1] or ""
				local numNewLines = #lines - 1
				-- Shift existing lines down
				for i = #lineTextBoxes, lineNumber + 1, -1 do
					if lineTextBoxes[i] then
						local frame = lineTextBoxes[i].Parent
						frame.Position = UDim2.new(0, 0, 0, (i + numNewLines - 1) * lineHeight)
						frame.Name = `Line_{i + numNewLines}`
						frame:FindFirstChild("LineNumber").Text = tostring(i + numNewLines)
					end
					lineHighlights[i + numNewLines] = lineHighlights[i]
				end
				-- Create new lines
				for i = 2, #lines do
					createLine(lineNumber + i - 1, lines[i])
				end
				updateCanvasSize()
			end
		end)

		textBox.Focused:Connect(function()
			if currentFocusedLine and lineHighlights[currentFocusedLine] then
				lineHighlights[currentFocusedLine].BackgroundTransparency = 1
			end
			currentFocusedLine = lineNumber
			currentFocusedTextBox = textBox
			currentFocusedLineNumber = lineNumber
			lineFrame.BackgroundTransparency = 0.5
		end)

		textBox.FocusLost:Connect(function()
			if currentFocusedTextBox == textBox then
				currentFocusedTextBox = nil
				currentFocusedLineNumber = nil
			end
		end)

		textBox.FocusLost:Connect(function(enterPressed)
			lineFrame.BackgroundTransparency = 1
			if enterPressed then
				local currentText = textBox.Text:gsub("[\r\n]", "")
				local indent = currentText:match("^([\t ]+)") or ""
			-- Ensure indent is clean (only tabs and spaces)
			indent = indent:gsub("[^\t ]", "")
			if not currentText:match("^[\t ]") then
				indent = ""
			end

				local newLineNum = lineNumber + 1
				-- Shift existing lines down
				for i = #lineTextBoxes, newLineNum, -1 do
					if lineTextBoxes[i] then
						local frame = lineTextBoxes[i].Parent
						frame.Position = UDim2.new(0, 0, 0, i * lineHeight)
						frame.Name = `Line_{i + 1}`
						frame:FindFirstChild("LineNumber").Text = tostring(i + 1)
					end
					-- Shift highlights table
					lineHighlights[i + 1] = lineHighlights[i]
				end
				lineHighlights[newLineNum] = nil
				-- Create new line (createLine handles the table.insert)
				local newTextBox = createLine(newLineNum, indent)
				updateCanvasSize()
				task.wait(0.06)
				newTextBox:CaptureFocus()
			end
		end)

		table.insert(lineTextBoxes, lineNumber, textBox)
		lineHighlights[lineNumber] = lineFrame
		return textBox
	end

	local function initializeLines(scriptText)
		local lines = string.split(scriptText, "\n")
		for i, line in ipairs(lines) do
			createLine(i, line)
		end
		updateCanvasSize()
	end

	initializeLines(data.Script or [[print("Hello World")]])

	local SaveButton: TextButton = window:Add("TextButton",{
		Name = "Save";
		Text = "Save";
		Size = UDim2.new(0, 40, 0, 20);
		Position = UDim2.new(1, 0, 1, -25);
		AnchorPoint = Vector2.new(1, 1);
	})

	local RunButton: TextButton = window:Add("TextButton",{
		Name = "Run";
		Text = "Run";
		Size = UDim2.new(0, 40, 0, 20);
		Position = UDim2.new(1, 0, 1, 0);
		AnchorPoint = Vector2.new(1, 1);
	})

	Save = function()
		client.Remote.Send("SaveScript",{
			Name = data.Name;
			Text = getAllText()
		})
	end

	Run = function()
		client.Remote.Send("SaveScript",{
			Name = data.Name;
			Text = getAllText()
		})
		client.Remote.Send("RunScript",{data.Name})
	end

	SaveButton.MouseButton1Click:Connect(function()
		Save()
	end)

	RunButton.MouseButton1Click:Connect(function()
		Run()
	end)

	-- Handle backspace on empty lines globally
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Backspace and currentFocusedTextBox and currentFocusedTextBox.Text == "" and currentFocusedLineNumber and currentFocusedLineNumber > 1 then
			local lineNumber = currentFocusedLineNumber
			local textBox = currentFocusedTextBox

			-- Delete this line and shift everything up
			local frame = textBox.Parent
			frame:Destroy()
			table.remove(lineTextBoxes, lineNumber)
			lineHighlights[lineNumber] = nil
			currentFocusedTextBox = nil
			currentFocusedLineNumber = nil

			-- Shift all lines below up
			for i = lineNumber, #lineTextBoxes do
				if lineTextBoxes[i] then
					local shiftFrame = lineTextBoxes[i].Parent
					shiftFrame.Position = UDim2.new(0, 0, 0, (i - 1) * lineHeight)
					shiftFrame.Name = `Line_{i}`
					shiftFrame:FindFirstChild("LineNumber").Text = tostring(i)
				end
				lineHighlights[i] = lineHighlights[i + 1]
			end

			updateCanvasSize()

			-- Focus the previous line
			if lineTextBoxes[lineNumber - 1] then
				lineTextBoxes[lineNumber - 1]:CaptureFocus()
			end
		end
	end)

	window:Ready()
end
