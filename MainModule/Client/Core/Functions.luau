--# selene: allow(empty_loop)
client = nil
service = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local _G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local script = script
	local service = Vargs.Service
	local client = Vargs.Client
	local Anti, Core, Functions, Process, Remote, UI, Variables
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables;
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;

		Functions.Init = nil;
	end

	local function RunLast()
		Functions.RunLast = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.Functions = {
		Init = Init;
		RunLast = RunLast;
		Kill = client.Kill;

		ESPFaces = {"Front", "Back", "Top", "Bottom", "Left", "Right"};
		ESPify = function(obj, color)
			local Debris = service.Debris
			local New = service.New

			local LocalPlayer = service.UnWrap(service.Player)

			for i, part in obj:GetChildren() do
				if part:IsA("BasePart") then
					if part.Name == "Head" and not part:FindFirstChild("__HYPERION_NAMETAG") then
						local player = service.Players:GetPlayerFromCharacter(part.Parent)

						if player then
							local bb = New("BillboardGui", {
								Name = "__HYPERION_NAMETAG",
								AlwaysOnTop = true,
								StudsOffset = Vector3.new(0,2,0),
								Size = UDim2.new(0,100,0,40),
								Adornee = part,
							}, true)
							local taglabel = New("TextLabel", {
								BackgroundTransparency = 1,
								TextColor3 = Color3.new(1,1,1),
								TextStrokeTransparency = 0,
								Text = string.format("%s (@%s)\n> %s <", player.DisplayName, player.Name, "0"),
								Size = UDim2.new(1, 0, 1, 0),
								TextScaled = true,
								TextWrapped = true,
								Parent = bb
							}, true)

							bb.Parent = part

							if player ~= LocalPlayer then
								task.spawn(function()
									repeat
										if not part then
											break
										end

										local DIST = LocalPlayer:DistanceFromCharacter(part.CFrame.Position)
										taglabel.Text = string.format("%s (@%s)\n> %s <", player.DisplayName, player.Name, DIST and math.floor(DIST) or 'N/A')

										task.wait()
									until not part or not bb or not taglabel
								end)
							end
						end
					end

					for _, surface in Functions.ESPFaces do
						local gui = New("SurfaceGui", {
							AlwaysOnTop = true,
							ResetOnSpawn = false,
							Face = surface,
							Adornee = part,
						}, true)

						New("Frame", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundColor3 = color,
							Parent = gui,
						}, true)

						gui.Parent = part;
						local tempConnection;
						tempConnection = gui.AncestryChanged:Connect(function(obj, parent)
							if obj == gui and parent == nil then
								tempConnection:Disconnect()
								Debris:AddItem(gui,0)
								for i,v in Variables.ESPObjects do
									if v == gui then
										table.remove(Variables.ESPObjects, i)
										break;
									end
								end
							end
						end)

						Variables.ESPObjects[gui] = part;
					end
				end
			end
		end;

		CharacterESP = function(mode, target, color)
			color = color or Color3.new(1, 0, 0.917647)

			local Debris = service.Debris
			local UnWrap = service.UnWrap

			if Variables.ESPEvent then
				Variables.ESPEvent:Disconnect();
				Variables.ESPEvent = nil;
			end

			for obj in Variables.ESPObjects do
				if not mode or not target or (target and obj:IsDescendantOf(target)) then
					local __HYPERION_NAMETAG = obj.Parent and obj.Parent:FindFirstChild("__HYPERION_NAMETAG")
					if __HYPERION_NAMETAG then
						__HYPERION_NAMETAG:Destroy()
					end

					Debris:AddItem(obj,0)
					Variables.ESPObjects[obj] = nil;
				end
			end

			if mode == true then
				if not target then
					Variables.ESPEvent = workspace.ChildAdded:Connect(function(obj)
						task.wait()

						local human = obj.ClassName == "Model" and service.Players:GetPlayerFromCharacter(obj)

						if human then
							task.spawn(Functions.ESPify, UnWrap(obj), color);
						end
					end)

					for _, Player in service.Players:GetPlayers() do
						if Player.Character then
							task.spawn(Functions.ESPify, UnWrap(Player.Character), color);
						end
					end
				else
					Functions.ESPify(UnWrap(target), color);
				end
			end
		end;

		SetView = function(ob)
			local CurrentCamera = workspace.CurrentCamera

			if ob == "reset" and service.Player.Character then
				CurrentCamera.CameraType = Enum.CameraType.Custom
				CurrentCamera.CameraSubject = service.Player.Character:FindFirstChildOfClass("Humanoid")
				CurrentCamera.FieldOfView = 70
			else
				CurrentCamera.CameraSubject = ob
			end
		end;

		AddAlias = function(alias, command)
			Variables.Aliases[string.lower(alias)] = command;
			Remote.Get("UpdateAliases", Variables.Aliases)
			task.defer(UI.MakeGui, "Notification", {
				Time = 4;
				Icon = client.MatIcons["Add circle"];
				Title = "Notification";
				Message = string.format('Alias "%s" added', string.lower(alias));
			})
		end;

		RemoveAlias = function(alias)
			if Variables.Aliases[string.lower(alias)] then
				Variables.Aliases[string.lower(alias)] = nil;
				Remote.Get("UpdateAliases", Variables.Aliases)
				task.defer(UI.MakeGui, "Notification", {
					Time = 4;
					Icon = client.MatIcons.Delete;
					Title = "Notification";
					Message = string.format('Alias "%s" removed', string.lower(alias));
				})
			else
				task.defer(UI.MakeGui, "Notification", {
					Time = 3;
					Icon = client.MatIcons.Help;
					Title = "Error";
					Message = string.format('Alias "%s" not found', string.lower(alias));
				})
			end
		end;

		Playlist = function()
			return Remote.Get("Playlist")
		end;

		UpdatePlaylist = function(playlist)
			Remote.Get("UpdatePlaylist", playlist)
		end;

		-- Thanks to Tiffany352 for this base64 implementation!

		Base64Encode = function(str)
			local floor = math.floor
			local char = string.char
			local nOut = 0
			local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			local strLen = #str
			local out = table.create(math.ceil(strLen / 0.75))

			-- 3 octets become 4 hextets
			for i = 1, strLen - 2, 3 do
				local b1, b2, b3 = str:byte(i, i + 3)
				local word = b3 + b2 * 256 + b1 * 256 * 256

				local h4 = word % 64 + 1
				word = floor(word / 64)
				local h3 = word % 64 + 1
				word = floor(word / 64)
				local h2 = word % 64 + 1
				word = floor(word / 64)
				local h1 = word % 64 + 1

				out[nOut + 1] = alphabet:sub(h1, h1)
				out[nOut + 2] = alphabet:sub(h2, h2)
				out[nOut + 3] = alphabet:sub(h3, h3)
				out[nOut + 4] = alphabet:sub(h4, h4)
				nOut = nOut + 4
			end

			local remainder = strLen % 3

			if remainder == 2 then
				-- 16 input bits -> 3 hextets (2 full, 1 partial)
				local b1, b2 = str:byte(-2, -1)
				-- partial is 4 bits long, leaving 2 bits of zero padding ->
				-- offset = 4
				local word = b2 * 4 + b1 * 4 * 256

				local h3 = word % 64 + 1
				word = floor(word / 64)
				local h2 = word % 64 + 1
				word = floor(word / 64)
				local h1 = word % 64 + 1

				out[nOut + 1] = alphabet:sub(h1, h1)
				out[nOut + 2] = alphabet:sub(h2, h2)
				out[nOut + 3] = alphabet:sub(h3, h3)
				out[nOut + 4] = "="
			elseif remainder == 1 then
				-- 8 input bits -> 2 hextets (2 full, 1 partial)
				local b1 = str:byte(-1, -1)
				-- partial is 2 bits long, leaving 4 bits of zero padding ->
				-- offset = 16
				local word = b1 * 16

				local h2 = word % 64 + 1
				word = floor(word / 64)
				local h1 = word % 64 + 1

				out[nOut + 1] = alphabet:sub(h1, h1)
				out[nOut + 2] = alphabet:sub(h2, h2)
				out[nOut + 3] = "="
				out[nOut + 4] = "="
			end
			-- if the remainder is 0, then no work is needed

			return table.concat(out, "")
		end;

		Base64Decode = function(str)
			local floor = math.floor
			local char = string.char
			local nOut = 0
			local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			local strLen = #str
			local out = table.create(math.ceil(strLen * 0.75))
			local acc = 0
			local nAcc = 0

			local alphabetLut = {}
			for i = 1, #alphabet do
				alphabetLut[alphabet:sub(i, i)] = i - 1
			end

			-- 4 hextets become 3 octets
			for i = 1, strLen do
				local ch = str:sub(i, i)
				local byte = alphabetLut[ch]
				if byte then
					acc = acc * 64 + byte
					nAcc += 1
				end

				if nAcc == 4 then
					local b3 = acc % 256
					acc = floor(acc / 256)
					local b2 = acc % 256
					acc = floor(acc / 256)
					local b1 = acc % 256

					out[nOut + 1] = char(b1)
					out[nOut + 2] = char(b2)
					out[nOut + 3] = char(b3)
					nOut += 3
					nAcc = 0
					acc = 0
				end
			end

			if nAcc == 3 then
				-- 3 hextets -> 16 bit output
				acc *= 64
				acc = floor(acc / 256)
				local b2 = acc % 256
				acc = floor(acc / 256)
				local b1 = acc % 256

				out[nOut + 1] = char(b1)
				out[nOut + 2] = char(b2)
			elseif nAcc == 2 then
				-- 2 hextets -> 8 bit output
				acc *= 64
				acc = floor(acc / 256)
				acc *= 64
				acc = floor(acc / 256)
				local b1 = acc % 256

				out[nOut + 1] = char(b1)
			elseif nAcc == 1 then
				error("Base64 has invalid length")
			end

			return table.concat(out, "")
		end;

		GetGuiData = function(args)
			local props = {
				"AbsolutePosition";
				"AutomaticCanvasSize";
				"BottomImage";
				"AbsoluteSize";
				"AnchorPoint";
				"CornerRadius";
				"CanvasSize";
				"CanvasPosition";
				"ClassName";
				"ElasticBehavior";
				"Name";
				"Parent";
				"Archivable";
				"DisplayOrder";
				"SelectionImageObject";
				"Active";
				"BackgroundColor3";
				"BackgroundTransparency";
				"BorderColor3";
				"BorderSizePixel";
				"Position";
				"Rotation";
				"RichText";
				"Selectable";
				"HorizontalScrollBarPosition";
				"Size";
				"Enabled";
				"Active";
				"SizeConstraint";
				"Style";
				"ScrollBarThickness";
				"ScrollBarImageTransparency";
				"ScrollingEnabled";
				"ScrollingDirection";
				"ScrollBarImageColor";
				"Visible";
				"ZIndex";
				"ClipsDescendants";
				"Draggable";
				"NextSelectionDown";
				"NextSelectionLeft";
				"NextSelectionRight";
				"NextSelectionUp";
				"PlaceholderColor3";
				"PlaceholderText";
				"AutoButtonColor";
				"Modal";
				"MidImage";
				"Image";
				"ImageColor3";
				"ImageRectOffset";
				"ImageRectSize";
				"ImageTransparency";
				"ScaleType";
				"SliceCenter";
				"Text";
				"TopImage";
				"TextColor3";
				"TextDirection";
				"Font";
				"TextScaled";
				"TextSize";
				"TextStrokeColor3";
				"TextStrokeTransparency";
				"TextTransparency";
				"TextTuncate";
				"TextWrapped";
				"TextXAlignment";
				"TextYAlignment";
				"VerticalScrollBarInset";
				"VerticalScrollBarPosition";
				"AspectRatio";
				"AspectType";
				"DominantAxis";
				"Offset";
				"Transparency";
				"CellPadding";
				"CellSize";
				"Padding";
				"PaddingBottom";
				"PaddingLeft";
				"PaddingRight";
				"PaddingTop";
				"Animated";
				"Circular";
				"EasingDirection";
				"EasingStyle";
				"TweenTime";
				"FillDirection";
				"SortOrder";
				"VerticalAlignment";
				"GamepadInputEnabled";
				"ScrollWheelInputEnabled";
				"TouchInputEnabled";
				"Scale";
				"MaxSize";
				"MinSize";
				"ApplyStrokeMode";
				"Color";
				"LineJoinMode";
				"Thickness";
				"FillEmptySpaceColumns";
				"FillEmptySpaceRow";
				"MajorAxis";
				"HorizontalAlignment";
				"MaxTextSize";
				"MinTextSize";
				"GroupColor3";
				"GroupTransparency";
				"SelectionImageObject";
				"Looped";
				"Playing";
				"TimePosition";
				"Video";
				"Volume";
				"LayoutOrder";
				"Ambient";
				"LightColor";
				"LightDirection";
				"CurrentCamera";
				"AutomaticSize";
				"AutoLocalize";
				"RootLocalizationTable";
			};

			local classes = {
				"ScreenGui";
				"GuiMain";
				"Frame";
				"CanvasGroup";
				"TextButton";
				"TextLabel";
				"ImageButton";
				"ImageLabel";
				"ScrollingFrame";
				"TextBox";
				"BillboardGui";
				"SurfaceGui";
				"UICorner";
				"UIAspectRatioConstraint";
				"UIGradient";
				"UIGridLayout";
				"UIListLayout";
				"UIPadding";
				"UIPageLayout";
				"UIScale";
				"UISizeConstraint";
				"UIStroke";
				"UITableLayout";
				"UITextSizeConstraint";
				"VideoFrame";
				"ViewportFrame"
			}

			local guis = {
				Properties = {
					Name = "ViewGuis";
					ClassName = "Folder";
				};
				Children = {};
			}

			local add; add = function(tab,child)
				local good = false

				for _, v in classes do
					if child:IsA(v) then
						good = true
					end
				end

				if good then
					local new = {
						Properties = {};
						Children = {};
					}

					for _, v in props do
						pcall(function()
							new.Properties[v] = child[v]
						end)
					end

					for _, v in child:GetChildren() do
						add(new,v)
					end
					table.insert(tab.Children, new)
				end
			end
			for _, v in service.PlayerGui:GetChildren() do
				pcall(add, guis, v)
			end
			return guis
		end;

		LoadGuiData = function(data)
			local zIndex = -2^31 -- Signed 32 bit intiger
			local make; make = function(data, parent)
				local props = data.Properties
				local gui = props.ClassName ~= "ScreenGui" and service.New(props.ClassName)

				if gui then
					for k, v in props do
						pcall(function()
							gui[k] = v
						end)
					end
				end

				for _, v in data.Children do
					pcall(function()
						local g = make(v, gui or parent)
						if g then
							g.Parent = gui or parent
						end
					end)
				end

				return gui
			end

			local function normaliseIndex(gui)
				local remap, order = {}, {}
				local mapIndex; mapIndex = function(object)
					local index = object.Properties.ZIndex

					if type(index) == "number" then
						if not remap[index] then
							remap[index] = {object.Properties}
							table.insert(order, index)
						else
							table.insert(remap[index], object.Properties)
						end
					end

					for _, v in object.Children do
						pcall(mapIndex, v)
					end
				end

				pcall(mapIndex, gui)
				table.sort(order)

				for _, index in order do
					zIndex += 1

					for _, v in remap[index] do
						v.ZIndex = zIndex
					end
				end

				return gui
			end

			local GuiViewContainer = UI.Make("Window", {
				Name = "Player GUI View";
				Title = "Player GUI View";
				Icon = client.MatIcons["Grid view"];
				AllowMultiple = true;
				SizeLocked = false
			})

			table.sort(data.Children, function(t1, t2)
				local o1, o2 = t1.Properties.DisplayOrder, t2.Properties.DisplayOrder
				if o1 and o2 then
					return o1 < o2
				end

				return false
			end)

			Variables.GuiViewFolder = GuiViewContainer
			zIndex = GuiViewContainer.ZIndex or zIndex

			for _, v in data.Children do
				pcall(make, normaliseIndex(v), GuiViewContainer)
			end

			GuiViewContainer:Ready()
		end;

		UnLoadGuiData = function()
			if Variables.GuiViewFolder then
				Variables.GuiViewFolder:Destroy()
				Variables.GuiViewFolder = nil
			end
		end;

		GetParticleContainer = function(target)
			if target then
				for _, v in service.LocalContainer():GetChildren() do
					if v.Name == `{target:GetFullName()}PARTICLES` then
						local obj = v:FindFirstChild("_OBJECT")
						if obj.Value == target then
							return v
						end
					end
				end
			end
		end;

		NewParticle = function(target, class, properties)
			local effect, index;

			properties.Parent = target;
			properties.Enabled = Variables.ParticlesEnabled;

			effect = service.New(class, properties);
			index = service.HttpService:GenerateGUID(false);

			Variables.Particles[index] = effect;

			table.insert(Variables.Particles, effect);

			effect.Changed:Connect(function()
				if not effect or not effect.Parent or effect.Parent ~= target then
					pcall(function() effect:Destroy() end)
					Variables.Particles[index] = nil;
				end
			end)
		end;

		RemoveParticle = function(target, name)
			for i,effect in Variables.Particles do
				if effect.Parent == target and effect.Name == name then
					effect:Destroy();
					Variables.Particles[i] = nil;
				end
			end
		end;

		EnableParticles = function(enabled)
			for _, effect in Variables.Particles do
				if enabled then
					effect.Enabled = true
				else
					effect.Enabled = false
				end
			end
		end;

		NewLocal = function(class, props, parent)
			local success, obj = pcall(service.New, class, props)
			if success then
				if not parent or parent == "LocalContainer" then
					obj.Parent = service.LocalContainer()
				elseif parent == "Camera" then
					obj.Parent = workspace.CurrentCamera
				elseif parent == "PlayerGui" then
					obj.Parent = service.PlayerGui
				end
			end
		end;

		MakeLocal = function(object,parent,clone)
			if object then
				local object = object
				if clone then object = object:Clone() end
				if not parent or parent == "LocalContainer" then
					object.Parent = service.LocalContainer()
				elseif parent == "Camera" then
					object.Parent = workspace.CurrentCamera
				elseif parent == "PlayerGui" then
					object.Parent = service.PlayerGui
				end
			end
		end;

		MoveLocal = function(object,parent,newParent)
			local par
			if not parent or parent == "LocalContainer" then
				par = service.LocalContainer()
			elseif parent == "Camera" then
				par = workspace.CurrentCamera
			elseif parent == "PlayerGui" then
				par = service.PlayerGui
			end
			for _, obj in par:GetChildren() do
				if obj.Name == object or obj == obj then
					obj.Parent = newParent
				end
			end
		end;

		RemoveLocal = function(object,parent,match)
			local par
			if not parent or parent == "LocalContainer" then
				par = service.LocalContainer()
			elseif parent == "Camera" then
				par = workspace.CurrentCamera
			elseif parent == "PlayerGui" then
				par = service.PlayerGui
			end

			for _, obj in par:GetChildren() do
				if match and string.match(obj.Name,object) or obj.Name == object or object == obj then
					obj:Destroy()
				end
			end
		end;

		ClearAllInstances = function()
			local objects = service.GetHyperionObjects()
			for i in objects do
				i:Destroy()
			end
			table.clear(objects)
		end;

		PlayAnimation = function(animId)
			if animId == 0 then return end

			local char = service.Player.Character
			local human = char and char:FindFirstChildOfClass("Humanoid")
			local animator = human and human:FindFirstChildOfClass("Animator") or human and human:WaitForChild("Animator", 9e9)
			if not animator then return end

			for _, v in animator:GetPlayingAnimationTracks() do v:Stop() end
			local anim = service.New('Animation', {
				AnimationId = `rbxassetid://{animId}`,
				Name = "HYPERION_Animation"
			})
			local track = animator:LoadAnimation(anim)
			track:Play()
		end;

		StopAnimation = function()
			local char = service.Player.Character
			local human = char and char:FindFirstChildOfClass("Humanoid")
			local animator = human and human:FindFirstChildOfClass("Animator") or human and human:WaitForChild("Animator", 9e9)
			if not animator then return end
			for _, v in animator:GetPlayingAnimationTracks() do
				if v.Name == "HYPERION_Animation" then v:Stop() end
			end
		end;

		SetLighting = function(prop, value)
			if service.CheckProperty(service.Lighting, prop) ~= nil then
				local success = pcall(function()
					service.Lighting[prop] = value
				end)
				if success then
					Variables.LightingSettings[prop] = value
				end
			end
		end;

		ChatMessage = function(msg,color,font,size)
			local tab = {}

			tab.Text = msg

			if color then
				tab.Color = color
			end

			if font then
				tab.Font = font
			end

			if size then
				tab.Size = size
			end

			service.StarterGui:SetCore("ChatMakeSystemMessage",tab)

			if Functions.SendToChat then
				Functions.SendToChat({Name = "::Hyperion::"},msg,"Private")
			end
		end;

		DisplaySystemMessageInTextChat = function(channel: TextChannel?, message, meta)
			if service.TextChatService then
				if not channel then
					--// we wanna get the default channel because the new ChatSystem sucks
					--// Please fix it Roblox
					--// we need less strict ways to filter & receive messages
					if service.TextChatService:FindFirstChild("TextChannels") and service.TextChatService.TextChannels:FindFirstChild("RBXSystem") then
						channel = service.TextChatService.TextChannels.RBXSystem
					end
				end
				if channel then
					channel:DisplaySystemMessage(message, meta)
				end
			end
		end;

		SetCamProperty = function(prop,value)
			local cam = workspace.CurrentCamera
			if cam[prop] then
				cam[prop] = value
			end
		end;

		SetFPS = function(fps)
			service.StopLoop("SetFPS")
			local fps = tonumber(fps)

			if fps then
				service.StartLoop("SetFPS",0.1,function()
					local osclock = os.clock()
					repeat while osclock + 1/fps > os.clock() do end
						task.wait()
						osclock = os.clock()
					until service.IsLooped("SetFPS") == false
				end)
			end
		end;

		RestoreFPS = function()
			service.StopLoop("SetFPS")
		end;

		CustomKick = function()
			service.TweenService:Create(service.New("BlurEffect", {
				Parent = service.Lighting; Size = 10;
			}), TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = 30}):Play()

			service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

			for _, v in service.PlayerGui:GetChildren() do
				if v.Name ~= "RobloxPromptGui" then
					pcall(v.Destroy, v)
				end
			end

			task.wait(0.6)
			Functions.HardCrash()
		end;

		KillClient = function()
			client.Kill("KillClient called")
		end;

		KeyCodeToName = function(keyVal)
			local keyCode = Enum.KeyCode:FromValue(tonumber(keyVal))

			if keyCode then
				local name = service.UserInputService:GetStringForKeyCode(keyCode)

				if service.Trim(name) == "" or Variables.KeycodeNames[keyCode] == name then
					return keyCode.Name
				else
					return name
				end
			else
				return "UNKNOWN"
			end
		end;

		KeyBindListener = function(keybinds)
			if not Variables then task.wait() end;
			local timer = 0
			local data = (not keybinds) and Remote.Get("PlayerData");

			Variables.KeyBinds = keybinds or data and data.Keybinds or {}

			service.UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
				if gameProcessedEvent then return end
				local key = tostring(input.KeyCode.Value)

				if Variables.KeybindsEnabled and key and Variables.KeyBinds[key] and not Variables.WaitingForBind then
					local isAdmin = Remote.Get("CheckAdmin")
					if time() - timer > 5 or isAdmin then
						Remote.Send('ProcessCommand',Variables.KeyBinds[key],false,true)
						UI.Make("Hint",{
							Message = `[Ran] Key: {Functions.KeyCodeToName(key)} | Command: {Variables.KeyBinds[key]}`
						})
					end
					timer = time()
				end
			end)
		end;

		AddKeyBind = function(key, command)
			local key = tostring(key);
			Variables.KeyBinds[tostring(key)] = command
			Remote.Get("UpdateKeybinds",Variables.KeyBinds)
			UI.Make("Hint",{
				Message = `Bound key "{Functions.KeyCodeToName(key)}" to command: {command}`
			})
		end;

		RemoveKeyBind = function(key)
			local key = tostring(key);

			if Variables.KeyBinds[tostring(key)] ~= nil then
				Variables.KeyBinds[tostring(key)] = nil
				Remote.Get("UpdateKeybinds",Variables.KeyBinds)
				Routine(function()
					UI.Make("Hint",{
						Message = `Removed key "{Functions.KeyCodeToName(key)}" from keybinds`
					})
				end)
			end
		end;

		BrickBlur = function(on, trans, color)
			local exists = service.LocalContainer():FindFirstChild("HYPERION_WINDOW_FUNC_BLUR")
			if exists then exists:Destroy() end
			if on then
				local pa = Instance.new("Part",workspace.CurrentCamera)
				pa.Name = "HYPERION_WINDOW_FUNC_BLUR"
				pa.Material = "Neon"
				pa.BrickColor = color or BrickColor.Black()
				pa.Transparency = trans or 0.5
				pa.CanCollide = false
				pa.Anchored = true
				pa.Size = Vector3.new(100,100,0)
				while pa and pa.Parent and task.wait(1/40) do
					pa.CFrame = workspace.CurrentCamera.CFrame*CFrame.new(0,0,-2.5)*CFrame.Angles(12.6,0,0)
				end
			else
				for _, v in workspace.CurrentCamera:GetChildren() do
					if v.Name == "HYPERION_WINDOW_FUNC_BLUR" then
						v:Destroy()
					end
				end
			end
		end;

		PlayAudio = function(audioId, volume, pitch, looped)
			if Variables.localSounds[tostring(audioId)] then Variables.localSounds[tostring(audioId)]:Stop() Variables.localSounds[tostring(audioId)]:Destroy() Variables.localSounds[tostring(audioId)]=nil end
			local sound = service.New("Sound")
			sound.SoundId = `rbxassetid://{audioId}`
			if looped then sound.Looped = true end
			if volume then sound.Volume = volume end
			if pitch then sound.Pitch = pitch end
			sound.Name = `HYPERION_LOCAL_SOUND {audioId}`
			sound.Parent = service.LocalContainer()
			Variables.localSounds[tostring(audioId)] = sound
			sound:Play()
			task.wait(1)
			if sound.IsPlaying == true then
				sound.Ended:Wait()
			end
			sound:Destroy()
			Variables.localSounds[tostring(audioId)] = nil
		end;

		StopAudio = function(audioId)
			if Variables.localSounds[tostring(audioId)] then
				Variables.localSounds[tostring(audioId)]:Stop()
				Variables.localSounds[tostring(audioId)]:Destroy()
				Variables.localSounds[tostring(audioId)] = nil
			elseif audioId == "all" then
				for i, v in Variables.localSounds do
					v:Stop()
					v:Destroy()
					Variables.localSounds[i] = nil
				end
			end
		end;

		FadeAudio = function(audioId,inVol,pitch,looped,incWait)
			if not inVol then
				local sound = Variables.localSounds[tostring(audioId)]
				if sound then
					for i = sound.Volume,0,-0.01 do
						sound.Volume = i
						task.wait(incWait or 0.1)
					end
					Functions.StopAudio(audioId)
				end
			else
				Functions.StopAudio(audioId)
				Functions.PlayAudio(audioId,0,pitch,looped)
				local sound = Variables.localSounds[tostring(audioId)]
				if sound then
					for i = 0,inVol,0.01 do
						sound.Volume = i
						task.wait(incWait or 0.1)
					end
				end
			end
		end;

		KillAllLocalAudio = function()
			for i,v in Variables.localSounds do
				v:Stop()
				v:Destroy()
				table.remove(Variables.localSounds,i)
			end
		end;

		RemoveGuis = function()
			for _, v in service.PlayerGui:GetChildren() do
				if not UI.Get(v) then
					v:Destroy()
				end
			end
		end;

		Unfly = function()
			local Humanoid: Humanoid = service.Player.Character and service.Player.Character:FindFirstChildOfClass("Humanoid")
			if Humanoid then
				Humanoid.PlatformStand = false
			end
		end;

		SetCoreGuiEnabled = function(element,enabled)
			service.StarterGui:SetCoreGuiEnabled(element,enabled)
		end;

		SetCore = function(...)
			service.StarterGui:SetCore(...)
		end;

		InspectPlayerFromUserId = function(...)
			service.GuiService:InspectPlayerFromUserId(...)
		end;

		IsValidTexture = function(id)
			local id = tonumber(id)
			local ran, info = pcall(function() return service.MarketPlace:GetProductInfo(id) end)

			if ran and info and info.AssetTypeId == 1 then
				return true;
			else
				return false;
			end
		end;

		GetTexture = function(id)
			local id = tonumber(id);
			if id and Functions.IsValidTexture(id) then
				return id;
			else
				return 6825455804;
			end
		end;

		SHA256 = function(...)
			return require(client.Shared.HashLib).SHA256(...)
		end;

		GetFriendsOnline = function(maxFriends)
			return service.Players.LocalPlayer:GetFriendsOnline(maxFriends)
		end;

		GetUserInputServiceData = function(args)
			local data = {}
			local props = {
				"AccelerometerEnabled";
				"GamepadEnabled";
				"GyroscopeEnabled";
				"KeyboardEnabled";
				"MouseDeltaSensitivity";
				"MouseEnabled";
				"OnScreenKeyboardVisible";
				"TouchEnabled";
				"VREnabled";
			}
			for _, p in props do
				data[p] = service.UserInputService[p]
			end
			data["Resolution"] = math.floor(workspace.CurrentCamera.ViewportSize.X).." x "..math.floor(workspace.CurrentCamera.ViewportSize.Y)
			return data
		end;

		PromptJoinGroup = function(groupId)
			xpcall(function()
				service.GroupService:PromptJoinAsync(groupId)
			end, function(err)
				warn(err)
			end)
		end;
	};
end
