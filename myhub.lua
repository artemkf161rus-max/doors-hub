local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local connections = {}
local function track(conn)
	table.insert(connections, conn)
	return conn
end

local ESP_RADIUS = 200

local gui = Instance.new("ScreenGui")
gui.Name = "MenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = playerGui

local function makeDraggable(frame, dragTarget, canDrag)
	local dragging, dragStart, startPos, dragInput
	local target = dragTarget or frame

	track(target.InputBegan:Connect(function(input)
		if canDrag and not canDrag() then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end))

	track(target.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	track(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if canDrag and not canDrag() then dragging = false return end
		if input == dragInput
			and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))
end

local buttonHolder = Instance.new("Frame")
buttonHolder.Name = "ButtonHolder"
buttonHolder.Size = UDim2.new(0, 320, 0, 40)
buttonHolder.Position = UDim2.new(0, 20, 0, 20)
buttonHolder.BackgroundTransparency = 1
buttonHolder.Active = true
buttonHolder.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = buttonHolder

local function createButton(text, order, color, width)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, width or 80, 0, 40)
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.Active = true
	btn.Parent = buttonHolder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(200, 150, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0
	stroke.Parent = btn

	return btn
end

local toggleButton = createButton("Toggle", 1, Color3.fromRGB(75, 0, 130), 80)
local lockButton   = createButton("Locked", 2, Color3.fromRGB(75, 0, 130), 90)
local unloadButton = createButton("Выгрузить", 3, Color3.fromRGB(150, 0, 0), 100)

local loadBox = Instance.new("TextLabel")
loadBox.Size = UDim2.new(0, 180, 0, 30)
loadBox.Position = UDim2.new(0, 20, 0, 70)
loadBox.BackgroundColor3 = Color3.fromRGB(75, 0, 130)
loadBox.BackgroundTransparency = 0
loadBox.BorderSizePixel = 0
loadBox.Text = "Загружено за 0.00 сек"
loadBox.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBox.Font = Enum.Font.GothamBold
loadBox.TextSize = 14
loadBox.Visible = true
loadBox.Active = false
loadBox.Parent = gui

local loadBoxCorner = Instance.new("UICorner")
loadBoxCorner.CornerRadius = UDim.new(0, 8)
loadBoxCorner.Parent = loadBox

local loadStroke = Instance.new("UIStroke")
loadStroke.Color = Color3.fromRGB(180, 100, 255)
loadStroke.Thickness = 2
loadStroke.Transparency = 0
loadStroke.Parent = loadBox

local elapsed = 0
local loadConn
loadConn = track(RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if loadBox and loadBox.Parent then
		loadBox.Text = string.format("Загружено за %.2f сек", elapsed)
	end
end))

task.delay(3, function()
	if loadConn then loadConn:Disconnect() end
	if loadBox and loadBox.Parent then
		local t = TweenService:Create(loadBox,
			TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1, TextTransparency = 1, Position = UDim2.new(0, 20, 0, 50) })
		t:Play()
		t.Completed:Connect(function()
			if loadBox then loadBox:Destroy() end
		end)
	end
end)

local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.Size = UDim2.new(0, 260, 0, 230)
menu.Position = UDim2.new(0, 20, 0, 80)
menu.BackgroundColor3 = Color3.fromRGB(45, 0, 80)
menu.BackgroundTransparency = 0
menu.BorderSizePixel = 0
menu.Visible = false
menu.Active = true
menu.Parent = gui

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(180, 100, 255)
menuStroke.Thickness = 2
menuStroke.Transparency = 0
menuStroke.Parent = menu

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = menu

local pages = {}

local function createPage()
	local p = Instance.new("Frame")
	p.Size = UDim2.new(1, 0, 1, -40)
	p.Position = UDim2.new(0, 0, 0, 0)
	p.BackgroundTransparency = 1
	p.Visible = false
	p.Parent = menu
	return p
end

pages[1] = createPage()
pages[2] = createPage()
pages[3] = createPage()

local pageNav = Instance.new("Frame")
pageNav.Name = "PageNav"
pageNav.Size = UDim2.new(1, -20, 0, 30)
pageNav.Position = UDim2.new(0, 10, 1, -35)
pageNav.BackgroundTransparency = 1
pageNav.Parent = menu

local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0, 60, 1, 0)
prevBtn.Position = UDim2.new(0, 0, 0, 0)
prevBtn.BackgroundColor3 = Color3.fromRGB(90, 0, 160)
prevBtn.BorderSizePixel = 0
prevBtn.Text = "◀"
prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prevBtn.Font = Enum.Font.GothamBold
prevBtn.TextSize = 18
prevBtn.AutoButtonColor = false
prevBtn.Parent = pageNav

local prevCorner = Instance.new("UICorner")
prevCorner.CornerRadius = UDim.new(0, 6)
prevCorner.Parent = prevBtn

local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.new(0, 60, 1, 0)
nextBtn.Position = UDim2.new(1, -60, 0, 0)
nextBtn.BackgroundColor3 = Color3.fromRGB(90, 0, 160)
nextBtn.BorderSizePixel = 0
nextBtn.Text = "▶"
nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextBtn.Font = Enum.Font.GothamBold
nextBtn.TextSize = 18
nextBtn.AutoButtonColor = false
nextBtn.Parent = pageNav

local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 6)
nextCorner.Parent = nextBtn

local pageLabel = Instance.new("TextLabel")
pageLabel.Size = UDim2.new(1, -140, 1, 0)
pageLabel.Position = UDim2.new(0, 70, 0, 0)
pageLabel.BackgroundTransparency = 1
pageLabel.Text = "1 / 3"
pageLabel.TextColor3 = Color3.fromRGB(220, 200, 255)
pageLabel.Font = Enum.Font.GothamBold
pageLabel.TextSize = 14
pageLabel.Parent = pageNav

local currentPage = 1
local totalPages = 3

local function showPage(n)
	if n < 1 then n = totalPages end
	if n > totalPages then n = 1 end
	currentPage = n

	for i, p in ipairs(pages) do
		p.Visible = (i == n)
	end
	pageLabel.Text = tostring(n) .. " / " .. tostring(totalPages)
end

track(prevBtn.MouseButton1Click:Connect(function()
	showPage(currentPage - 1)
end))

track(nextBtn.MouseButton1Click:Connect(function()
	showPage(currentPage + 1)
end))

local function makeLabel(parent, text, y)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 0, 20)
	lbl.Position = UDim2.new(0, 10, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(220, 200, 255)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Active = false
	lbl.Parent = parent
	return lbl
end

local function makeSwitch(parent, y)
	local bg = Instance.new("TextButton")
	bg.Size = UDim2.new(0, 50, 0, 24)
	bg.Position = UDim2.new(1, -60, 0, y - 2)
	bg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	bg.BorderSizePixel = 0
	bg.Text = ""
	bg.AutoButtonColor = false
	bg.Active = true
	bg.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = bg

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.Position = UDim2.new(0, 3, 0.5, -9)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = bg

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	return bg, knob
end

local function switchOn(bg, knob)
	TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(120, 0, 200) }):Play()
	TweenService:Create(knob, TweenInfo.new(0.2), { Position = UDim2.new(0, 29, 0.5, -9) }):Play()
end

local function switchOff(bg, knob)
	TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(60, 60, 60) }):Play()
	TweenService:Create(knob, TweenInfo.new(0.2), { Position = UDim2.new(0, 3, 0.5, -9) }):Play()
end

local featureEnabled = false
local espEnabled = false
local toolEspEnabled = false
local promptEspEnabled = false
local instantPromptEnabled = false
local monsterEspEnabled = false
local fullbrightEnabled = false
local notifierEnabled = false
local antiLagEnabled = false

local FAKE_SPEED = 15.0
local REAL_SPEED = 21.0
local JUMP_POWER = 50

local spoofing = false
local bv
local speedLoop

local oldIndex
local hookOk = false
local hookSuccess = pcall(function()
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if spoofing and self:IsA("Humanoid") and self:IsDescendantOf(player.Character) then
			if key == "WalkSpeed" then
				return FAKE_SPEED
			elseif key == "JumpPower" then
				return JUMP_POWER
			end
		end
		return oldIndex(self, key)
	end))
	hookOk = true
end)

makeLabel(pages[1], "WALKSPEED", 10)
local switchBg, switchKnob = makeSwitch(pages[1], 8)

local wsValue = Instance.new("TextLabel")
wsValue.Size = UDim2.new(1, -20, 0, 18)
wsValue.Position = UDim2.new(0, 10, 0, 36)
wsValue.BackgroundTransparency = 1
wsValue.Text = "REAL 21.0 / FAKE 15.0"
wsValue.TextColor3 = Color3.fromRGB(255, 255, 255)
wsValue.Font = Enum.Font.GothamBold
wsValue.TextSize = 13
wsValue.TextXAlignment = Enum.TextXAlignment.Left
wsValue.Active = false
wsValue.Parent = pages[1]

local spoofStatus = Instance.new("TextLabel")
spoofStatus.Size = UDim2.new(1, -20, 0, 18)
spoofStatus.Position = UDim2.new(0, 10, 0, 60)
spoofStatus.BackgroundTransparency = 1
spoofStatus.Text = "Spoof: " .. (hookOk and "READY" or "NOT SUPPORTED")
spoofStatus.TextColor3 = hookOk and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
spoofStatus.Font = Enum.Font.GothamBold
spoofStatus.TextSize = 12
spoofStatus.TextXAlignment = Enum.TextXAlignment.Left
spoofStatus.Active = false
spoofStatus.Parent = pages[1]

local function updateSwitchLook()
	if featureEnabled then switchOn(switchBg, switchKnob) else switchOff(switchBg, switchKnob) end
end
updateSwitchLook()

local function cleanupSpeed()
	spoofing = false
	if speedLoop then speedLoop:Disconnect() speedLoop = nil end
	if bv and bv.Parent then bv:Destroy() end
	bv = nil

	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 15 end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then root.CustomPhysicalProperties = nil end
	end
end

local function applySpeed()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	spoofing = true
	hum.WalkSpeed = 15

	if not bv or not bv.Parent then
		bv = Instance.new("BodyVelocity")
		bv.Name = "SpeedSpoof"
		bv.MaxForce = Vector3.new(1e5, 0, 1e5)
		bv.P = 1e5
		bv.Parent = root
	end

	root.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)

	if not speedLoop then
		speedLoop = RunService.Heartbeat:Connect(function()
			if not featureEnabled then return end
			local c = player.Character
			if not c then return end
			local h = c:FindFirstChildOfClass("Humanoid")
			if not h or not bv or not bv.Parent then return end
			local md = h.MoveDirection
			if md.Magnitude > 0 then
				bv.Velocity = md * REAL_SPEED
			else
				bv.Velocity = Vector3.zero
			end
		end)
	end
end

track(switchBg.MouseButton1Click:Connect(function()
	featureEnabled = not featureEnabled
	updateSwitchLook()
	if featureEnabled then
		applySpeed()
	else
		cleanupSpeed()
	end
end))

track(player.CharacterAdded:Connect(function()
	task.wait(1)
	if featureEnabled then
		cleanupSpeed()
		featureEnabled = true
		applySpeed()
	end
end))

makeLabel(pages[2], "ESP PLAYERS", 10)
local espSwitchBg, espSwitchKnob = makeSwitch(pages[2], 8)
makeLabel(pages[2], "ESP TOOLS", 45)
local toolEspSwitchBg, toolEspSwitchKnob = makeSwitch(pages[2], 43)
makeLabel(pages[2], "ESP PROMPTS", 80)
local promptEspSwitchBg, promptEspSwitchKnob = makeSwitch(pages[2], 78)
makeLabel(pages[2], "ESP MONSTERS", 115)
local monSwitchBg, monSwitchKnob = makeSwitch(pages[2], 113)

makeLabel(pages[3], "INSTANT PROMPT", 10)
local instSwitchBg, instSwitchKnob = makeSwitch(pages[3], 8)
makeLabel(pages[3], "FULLBRIGHT", 45)
local fbSwitchBg, fbSwitchKnob = makeSwitch(pages[3], 43)
makeLabel(pages[3], "RUSH NOTIFIER", 80)
local notifSwitchBg, notifSwitchKnob = makeSwitch(pages[3], 78)
makeLabel(pages[3], "ANTI-LAG", 115)
local lagSwitchBg, lagSwitchKnob = makeSwitch(pages[3], 113)

showPage(1)

local espObjects = {}

local function createESP(targetPlayer)
	if targetPlayer == player then return end
	if espObjects[targetPlayer] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = nil
	highlight.Parent = targetPlayer.Character or targetPlayer

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_Billboard"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = targetPlayer.Character or targetPlayer

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = targetPlayer.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = billboard

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(1, 0, 0, 16)
	hpLabel.Position = UDim2.new(0, 0, 0, 20)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "HP: 100"
	hpLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	hpLabel.TextStrokeTransparency = 0
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextSize = 12
	hpLabel.Parent = billboard

	espObjects[targetPlayer] = {
		highlight = highlight,
		billboard = billboard,
		hpLabel = hpLabel,
	}
end

local function removeESP(targetPlayer)
	local data = espObjects[targetPlayer]
	if data then
		if data.highlight then data.highlight:Destroy() end
		if data.billboard then data.billboard:Destroy() end
		espObjects[targetPlayer] = nil
	end
end

local function clearAllESP()
	for p, _ in pairs(espObjects) do
		removeESP(p)
	end
end

track(RunService.RenderStepped:Connect(function()
	if not espEnabled then return end

	local myChar = player.Character
	local myPos
	if myChar then
		local root = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChildWhichIsA("BasePart")
		myPos = root and root.Position
	end

	for targetPlayer, data in pairs(espObjects) do
		local char = targetPlayer.Character
		local charPos
		if char then
			local h = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
			charPos = h and h.Position
		end

		local inRange = true
		if myPos and charPos then
			inRange = (charPos - myPos).Magnitude <= ESP_RADIUS
		end

		if char and data.highlight and inRange then
			data.highlight.Enabled = true
			data.highlight.Adornee = char
			if data.billboard then
				data.billboard.Enabled = true
				data.billboard.Adornee = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and data.hpLabel then
				data.hpLabel.Text = string.format("HP: %d", math.floor(hum.Health))
				local ratio = hum.Health / hum.MaxHealth
				data.hpLabel.TextColor3 = Color3.fromRGB(
					math.floor(255 * (1 - ratio)),
					math.floor(255 * ratio),
					0
				)
			end
		else
			if data.highlight then data.highlight.Enabled = false end
			if data.billboard then data.billboard.Enabled = false end
		end
	end
end))

local function watchCharacter(p)
	track(p.CharacterAdded:Connect(function()
		if espEnabled then
			removeESP(p)
			task.wait(0.5)
			createESP(p)
		end
	end))
end

for _, p in ipairs(Players:GetPlayers()) do watchCharacter(p) end
track(Players.PlayerAdded:Connect(function(p)
	watchCharacter(p)
	if espEnabled then createESP(p) end
end))
track(Players.PlayerRemoving:Connect(function(p)
	removeESP(p)
end))

track(espSwitchBg.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled

	if espEnabled then
		switchOn(espSwitchBg, espSwitchKnob)
		for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
	else
		switchOff(espSwitchBg, espSwitchKnob)
		clearAllESP()
	end
end))

local toolEspObjects = {}

local function createToolGhost(tool)
	local ghostParts = {}
	local ghostFolder = Instance.new("Folder")
	ghostFolder.Name = "ESP_GhostFolder"
	ghostFolder.Parent = workspace

	for _, part in ipairs(tool:GetDescendants()) do
		if part:IsA("BasePart") then
			local ghost = part:Clone()
			ghost.Name = "ESP_Ghost"
			ghost.Anchored = true
			ghost.CanCollide = false
			ghost.CanQuery = false
			ghost.CanTouch = false
			ghost.Massless = true
			ghost.Transparency = 0.35
			ghost.Material = Enum.Material.Neon
			ghost.Color = Color3.fromRGB(0, 200, 255)

			for _, child in ipairs(ghost:GetChildren()) do
				if child:IsA("Script") or child:IsA("LocalScript")
					or child:IsA("Tool") or child:IsA("ProximityPrompt") then
					child:Destroy()
				end
			end

			ghost.Parent = ghostFolder

			local link = Instance.new("ObjectValue")
			link.Name = "ESP_Link"
			link.Value = part
			link.Parent = ghost

			table.insert(ghostParts, ghost)
		end
	end

	return ghostParts, ghostFolder
end

local function removeToolGhost(ghostParts, ghostFolder)
	for _, ghost in ipairs(ghostParts) do
		if ghost and ghost.Parent then ghost:Destroy() end
	end
	if ghostFolder and ghostFolder.Parent then
		ghostFolder:Destroy()
	end
end

local function createToolESP(tool)
	if toolEspObjects[tool] then return end
	if not tool:IsA("Tool") then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ToolESP_Highlight"
	highlight.FillColor = Color3.fromRGB(0, 200, 255)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.4
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = tool
	highlight.Parent = tool

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ToolESP_Billboard"
	billboard.Size = UDim2.new(0, 180, 0, 22)
	billboard.StudsOffset = Vector3.new(0, 1.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = tool

	local attachPart = tool:FindFirstChildWhichIsA("BasePart")
	billboard.Adornee = attachPart or tool

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = tool.Name
	nameLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = billboard

	local ghostParts, ghostFolder = {}, nil
	if tool.Parent == workspace then
		ghostParts, ghostFolder = createToolGhost(tool)
	end

	toolEspObjects[tool] = {
		highlight = highlight,
		billboard = billboard,
		nameLabel = nameLabel,
		ghostParts = ghostParts,
		ghostFolder = ghostFolder,
	}
end

local function removeToolESP(tool)
	local data = toolEspObjects[tool]
	if data then
		if data.highlight then data.highlight:Destroy() end
		if data.billboard then data.billboard:Destroy() end
		if data.ghostParts then removeToolGhost(data.ghostParts, data.ghostFolder) end
		toolEspObjects[tool] = nil
	end
end

local function clearAllToolESP()
	for tool, _ in pairs(toolEspObjects) do
		removeToolESP(tool)
	end
end

local function refreshToolESP(tool)
	if not tool:IsA("Tool") then return end
	local data = toolEspObjects[tool]
	if not data then return end

	if tool.Parent == workspace then
		if not data.ghostParts or #data.ghostParts == 0 then
			local ghostParts, ghostFolder = createToolGhost(tool)
			data.ghostParts = ghostParts
			data.ghostFolder = ghostFolder
		end
	else
		if data.ghostParts and #data.ghostParts > 0 then
			removeToolGhost(data.ghostParts, data.ghostFolder)
			data.ghostParts = {}
			data.ghostFolder = nil
		end
	end
end

local function scanToolsAndApply()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Tool") then
			if toolEspEnabled then createToolESP(obj) else removeToolESP(obj) end
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			for _, obj in ipairs(char:GetChildren()) do
				if obj:IsA("Tool") then
					if toolEspEnabled then createToolESP(obj) else removeToolESP(obj) end
				end
			end
		end
		local backpack = p:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, obj in ipairs(backpack:GetChildren()) do
				if obj:IsA("Tool") then
					if toolEspEnabled then createToolESP(obj) else removeToolESP(obj) end
				end
			end
		end
	end
end

track(workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Tool") and toolEspEnabled then
		task.wait(0.1)
		createToolESP(obj)
		task.defer(refreshToolESP, obj)
	end
end))

local function hookToolAncestry(tool)
	track(tool.AncestryChanged:Connect(function()
		if toolEspEnabled then
			task.defer(refreshToolESP, tool)
		end
	end))
end

for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("Tool") then hookToolAncestry(obj) end
end

track(workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Tool") then
		hookToolAncestry(obj)
	end
end))

track(Players.PlayerAdded:Connect(function(p)
	track(p.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			track(child.ChildAdded:Connect(function(item)
				if item:IsA("Tool") and toolEspEnabled then
					createToolESP(item)
				end
			end))
			track(child.ChildRemoved:Connect(function(item)
				if item:IsA("Tool") then removeToolESP(item) end
			end))
		end
	end))
	track(p.CharacterAdded:Connect(function(char)
		track(char.ChildAdded:Connect(function(item)
			if item:IsA("Tool") and toolEspEnabled then
				createToolESP(item)
			end
		end))
		track(char.ChildRemoved:Connect(function(item)
			if item:IsA("Tool") then removeToolESP(item) end
		end))
	end))
end))

track(toolEspSwitchBg.MouseButton1Click:Connect(function()
	toolEspEnabled = not toolEspEnabled

	if toolEspEnabled then
		switchOn(toolEspSwitchBg, toolEspSwitchKnob)
		scanToolsAndApply()
	else
		switchOff(toolEspSwitchBg, toolEspSwitchKnob)
		clearAllToolESP()
	end
end))

track(RunService.RenderStepped:Connect(function()
	if not toolEspEnabled then return end

	local myChar = player.Character
	local myPos
	if myChar then
		local root = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChildWhichIsA("BasePart")
		myPos = root and root.Position
	end

	for tool, data in pairs(toolEspObjects) do
		if not tool.Parent then
			removeToolESP(tool)
		else
			local attach = tool:FindFirstChildWhichIsA("BasePart")
			local toolPos = attach and attach.Position

			local inRange = true
			if myPos and toolPos then
				inRange = (toolPos - myPos).Magnitude <= ESP_RADIUS
			end

			if data.highlight then
				data.highlight.Enabled = inRange
			end
			if data.billboard then
				data.billboard.Enabled = inRange
			end
			if data.ghostParts then
				for _, ghost in ipairs(data.ghostParts) do
					if ghost and ghost.Parent then
						ghost.Transparency = inRange and 0.35 or 1
					end
				end
			end

			if data.billboard then
				data.billboard.Adornee = attach or tool
			end
			if data.highlight then
				data.highlight.Adornee = tool
			end
			if data.nameLabel then
				data.nameLabel.Text = tool.Name
			end

			if data.ghostParts and inRange then
				for _, ghost in ipairs(data.ghostParts) do
					if ghost and ghost.Parent then
						local link = ghost:FindFirstChild("ESP_Link")
						local original = link and link.Value
						if original and original.Parent then
							ghost.CFrame = original.CFrame
							ghost.Size = original.Size
						else
							ghost:Destroy()
						end
					end
				end
			end
		end
	end
end))

local promptEspObjects = {}

local PROMPT_BLACKLIST = {
	Painting = true,
	Drawer = true,
	Toilet = true,
	Regal = true,
	HidePrompt = true,
	Hide = true,
}

local PROMPT_BLUELIST = {
	Key = true,
}

local function isBlacklisted(target)
	if not target then return false end
	local name = target.Name
	if PROMPT_BLACKLIST[name] then return true end
	for blocked, _ in pairs(PROMPT_BLACKLIST) do
		if string.find(string.lower(name), string.lower(blocked), 1, true) then
			return true
		end
	end
	return false
end

local function isBlueListed(target)
	if not target then return false end
	local name = string.lower(target.Name)
	for blue, _ in pairs(PROMPT_BLUELIST) do
		if string.sub(name, 1, #blue) == string.lower(blue) then
			return true
		end
	end
	return false
end

local function getPromptTarget(prompt)
	local parent = prompt.Parent
	if not parent then return nil end
	if parent:IsA("Model") then
		return parent
	elseif parent:IsA("BasePart") then
		local model = parent:FindFirstAncestorOfClass("Model")
		return model or parent
	end
	return nil
end

local function getTargetPosition(target)
	if target:IsA("Model") then
		if target.PrimaryPart then return target.PrimaryPart.Position end
		local part = target:FindFirstChildWhichIsA("BasePart")
		return part and part.Position or nil
	elseif target:IsA("BasePart") then
		return target.Position
	end
	return nil
end

local function createPromptESP(prompt)
	local target = getPromptTarget(prompt)
	if not target then return end
	if promptEspObjects[target] then return end
	if target == player.Character then return end
	if isBlacklisted(target) then return end

	local isBlue = isBlueListed(target)
	local fillColor = isBlue and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 200, 0)
	local textColor = isBlue and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 220, 0)

	local highlight = Instance.new("Highlight")
	highlight.Name = "PromptESP_Highlight"
	highlight.FillColor = fillColor
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = target
	highlight.Parent = target

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PromptESP_Billboard"
	billboard.Size = UDim2.new(0, 220, 0, 58)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true

	local attachPart
	if target:IsA("Model") then
		attachPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	elseif target:IsA("BasePart") then
		attachPart = target
	end
	billboard.Adornee = attachPart or target
	billboard.Parent = attachPart or target

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = target.Name
	nameLabel.TextColor3 = textColor
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = billboard

	local promptLabel = Instance.new("TextLabel")
	promptLabel.Size = UDim2.new(1, 0, 0, 16)
	promptLabel.Position = UDim2.new(0, 0, 0, 18)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Text = prompt.ActionText ~= "" and prompt.ActionText or "Interact"
	promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptLabel.TextStrokeTransparency = 0
	promptLabel.Font = Enum.Font.Gotham
	promptLabel.TextSize = 12
	promptLabel.Parent = billboard

	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(1, 0, 0, 16)
	distLabel.Position = UDim2.new(0, 0, 0, 34)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = "[0 studs]"
	distLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	distLabel.TextStrokeTransparency = 0
	distLabel.Font = Enum.Font.GothamBold
	distLabel.TextSize = 12
	distLabel.Parent = billboard

	promptEspObjects[target] = {
		highlight = highlight,
		billboard = billboard,
		nameLabel = nameLabel,
		promptLabel = promptLabel,
		distLabel = distLabel,
		prompt = prompt,
	}
end

local function removePromptESP(target)
	local data = promptEspObjects[target]
	if data then
		if data.highlight then data.highlight:Destroy() end
		if data.billboard then data.billboard:Destroy() end
		promptEspObjects[target] = nil
	end
end

local function clearAllPromptESP()
	for target, _ in pairs(promptEspObjects) do
		removePromptESP(target)
	end
end

local function scanPromptsAndApply()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			local target = getPromptTarget(obj)
			if target then
				if promptEspEnabled and not isBlacklisted(target) then
					createPromptESP(obj)
				else
					removePromptESP(target)
				end
			end
		end
	end
end

track(workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ProximityPrompt") then
		task.wait(0.1)
		if promptEspEnabled then
			local target = getPromptTarget(obj)
			if target and not isBlacklisted(target) then
				createPromptESP(obj)
			end
		end
	end
end))

track(workspace.DescendantRemoving:Connect(function(obj)
	if obj:IsA("ProximityPrompt") then
		local target = getPromptTarget(obj)
		if target and promptEspObjects[target] then
			removePromptESP(target)
		end
	end
end))

track(promptEspSwitchBg.MouseButton1Click:Connect(function()
	promptEspEnabled = not promptEspEnabled

	if promptEspEnabled then
		switchOn(promptEspSwitchBg, promptEspSwitchKnob)
		scanPromptsAndApply()
	else
		switchOff(promptEspSwitchBg, promptEspSwitchKnob)
		clearAllPromptESP()
	end
end))

track(RunService.RenderStepped:Connect(function()
	if not promptEspEnabled then return end

	local char = player.Character
	local myPos
	if char then
		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
		myPos = root and root.Position
	end

	for target, data in pairs(promptEspObjects) do
		if not target.Parent then
			removePromptESP(target)
		else
			local targetPos = getTargetPosition(target)
			local inRange = true
			if myPos and targetPos then
				inRange = (targetPos - myPos).Magnitude <= ESP_RADIUS
			end

			if data.highlight then
				data.highlight.Enabled = inRange
			end
			if data.billboard then
				data.billboard.Enabled = inRange
			end

			local attachPart
			if target:IsA("Model") then
				attachPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
			elseif target:IsA("BasePart") then
				attachPart = target
			end
			if data.billboard then
				data.billboard.Adornee = attachPart or target
			end
			if data.highlight then
				data.highlight.Adornee = target
			end
			if data.nameLabel then
				data.nameLabel.Text = target.Name
			end
			if data.promptLabel and data.prompt and data.prompt.Parent then
				data.promptLabel.Text = data.prompt.ActionText ~= "" and data.prompt.ActionText or "Interact"
			end

			if data.distLabel and myPos and targetPos then
				data.distLabel.Text = string.format("[%.0f studs]", (targetPos - myPos).Magnitude)
			end
		end
	end
end))

local savedPrompts = {}

local function makePromptInstant(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	if savedPrompts[prompt] then return end

	savedPrompts[prompt] = {
		HoldDuration = prompt.HoldDuration,
		MaxActivationDistance = prompt.MaxActivationDistance,
		RequiresLineOfSight = prompt.RequiresLineOfSight,
		ClickablePrompt = prompt.ClickablePrompt,
	}

	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
end

local function restorePrompt(prompt)
	local saved = savedPrompts[prompt]
	if not saved then return end
	if prompt and prompt.Parent then
		prompt.HoldDuration = saved.HoldDuration
		prompt.MaxActivationDistance = saved.MaxActivationDistance
		prompt.RequiresLineOfSight = saved.RequiresLineOfSight
		prompt.ClickablePrompt = saved.ClickablePrompt
	end
	savedPrompts[prompt] = nil
end

local function applyInstantToAll()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			if instantPromptEnabled then
				makePromptInstant(obj)
			else
				restorePrompt(obj)
			end
		end
	end
end

track(workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ProximityPrompt") and instantPromptEnabled then
		task.wait(0.1)
		makePromptInstant(obj)
	end
end))

track(workspace.DescendantRemoving:Connect(function(obj)
	if obj:IsA("ProximityPrompt") and savedPrompts[obj] then
		savedPrompts[obj] = nil
	end
end))

track(instSwitchBg.MouseButton1Click:Connect(function()
	instantPromptEnabled = not instantPromptEnabled

	if instantPromptEnabled then
		switchOn(instSwitchBg, instSwitchKnob)
	else
		switchOff(instSwitchBg, instSwitchKnob)
	end
	applyInstantToAll()
end))

local function restoreAllPrompts()
	for prompt, _ in pairs(savedPrompts) do
		restorePrompt(prompt)
	end
	savedPrompts = {}
end

local monsterEspObjects = {}

local MONSTER_PREFIXES = { "Rush", "Ambush", "Eyes", "Figure", "Seek", "Hide", "Glitch", "Jack" }

local MONSTER_BLACKLIST = {
	FigureAttach = true,
	FigureRig = true,
	FigureArm = true,
	FigureLeg = true,
	FigureHead = true,
	FigureTorso = true,
	FigureBody = true,
	Attachment = true,
	Attachments = true,
	Hitbox = true,
	HitBox = true,
	Rig = true,
	RootPart = true,
	Root = true,
	HidePrompt = true,
	HidePrompts = true,
	Prompt = true,
	Prompts = true,
	Trigger = true,
	Triggers = true,
	Detector = true,
	Sensor = true,
	Collision = true,
	Collider = true,
	Region = true,
	Zone = true,
	Area = true,
	Marker = true,
	Point = true,
	Spawn = true,
	Spawner = true,
	Anchor = true,
	Base = true,
	Stand = true,
	Stand1 = true,
	Stand2 = true,
	Stand3 = true,
	Stand4 = true,
	Stand5 = true,
	Stand6 = true,
	Stand7 = true,
	Stand8 = true,
}

local function isBlacklistedMonster(target)
	if not target then return false end
	local name = string.lower(target.Name)
	for blocked, _ in pairs(MONSTER_BLACKLIST) do
		if string.find(name, string.lower(blocked), 1, true) then
			return true
		end
	end
	return false
end

local function isPlayerCharacter(target)
	if not target or not target:IsA("Model") then return false end
	local p = Players:GetPlayerFromCharacter(target)
	return p ~= nil
end

local function isMonster(target)
	if not target then return false end
	if isBlacklistedMonster(target) then return false end
	local name = string.lower(target.Name)
	for _, prefix in ipairs(MONSTER_PREFIXES) do
		if string.sub(name, 1, #prefix) == string.lower(prefix) then
			return true
		end
	end
	return false
end

local function isRig(target)
	if not target or not target:IsA("Model") then return false end
	if isPlayerCharacter(target) then return false end
	if isMonster(target) then return false end
	if isBlacklistedMonster(target) then return false end
	if not target:FindFirstChildOfClass("Humanoid") then return false end
	if not target:FindFirstChild("HumanoidRootPart") then return false end
	return true
end

local function shouldESPMonster(target)
	if isPlayerCharacter(target) then return false end
	if isBlacklistedMonster(target) then return false end
	return isMonster(target) or isRig(target)
end

local function getMonsterPosition(target)
	if target:IsA("Model") then
		if target.PrimaryPart then return target.PrimaryPart.Position end
		local part = target:FindFirstChildWhichIsA("BasePart")
		return part and part.Position or nil
	elseif target:IsA("BasePart") then
		return target.Position
	end
	return nil
end

local function getMonsterColor(target)
	if isMonster(target) then
		return Color3.fromRGB(255, 0, 0),
		       Color3.fromRGB(255, 100, 100),
		       Color3.fromRGB(255, 50, 50)
	else
		return Color3.fromRGB(255, 140, 0),
		       Color3.fromRGB(255, 200, 100),
		       Color3.fromRGB(255, 180, 60)
	end
end

local function createMonsterESP(target)
	if monsterEspObjects[target] then return end
	if not shouldESPMonster(target) then return end

	local fillColor, outlineColor, textColor = getMonsterColor(target)

	local highlight = Instance.new("Highlight")
	highlight.Name = "MonsterESP_Highlight"
	highlight.FillColor = fillColor
	highlight.OutlineColor = outlineColor
	highlight.FillTransparency = 0.4
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = target
	highlight.Parent = target

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MonsterESP_Billboard"
	billboard.Size = UDim2.new(0, 220, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true

	local attachPart
	if target:IsA("Model") then
		attachPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	elseif target:IsA("BasePart") then
		attachPart = target
	end
	billboard.Adornee = attachPart or target
	billboard.Parent = attachPart or target

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = (isMonster(target) and "⚠ " or "[Rig] ") .. target.Name .. (isMonster(target) and " ⚠" or "")
	nameLabel.TextColor3 = textColor
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.Parent = billboard

	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(1, 0, 0, 16)
	distLabel.Position = UDim2.new(0, 0, 0, 20)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = "[0 studs]"
	distLabel.TextColor3 = Color3.fromRGB(255, 220, 180)
	distLabel.TextStrokeTransparency = 0
	distLabel.Font = Enum.Font.GothamBold
	distLabel.TextSize = 12
	distLabel.Parent = billboard

	monsterEspObjects[target] = {
		highlight = highlight,
		billboard = billboard,
		nameLabel = nameLabel,
		distLabel = distLabel,
	}
end

local function removeMonsterESP(target)
	local data = monsterEspObjects[target]
	if data then
		if data.highlight then data.highlight:Destroy() end
		if data.billboard then data.billboard:Destroy() end
		monsterEspObjects[target] = nil
	end
end

local function clearAllMonsterESP()
	for target, _ in pairs(monsterEspObjects) do
		removeMonsterESP(target)
	end
end

local function scanMonstersAndApply()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if shouldESPMonster(obj) then
			if monsterEspEnabled then
				createMonsterESP(obj)
			else
				removeMonsterESP(obj)
			end
		end
	end
end

track(workspace.DescendantAdded:Connect(function(obj)
	if monsterEspEnabled and shouldESPMonster(obj) then
		task.wait(0.1)
		createMonsterESP(obj)
	end

	if monsterEspEnabled and obj:IsA("Humanoid") then
		local parent = obj.Parent
		if parent and parent:IsA("Model") and shouldESPMonster(parent) then
			task.wait(0.1)
			createMonsterESP(parent)
		end
	end
end))

track(workspace.DescendantRemoving:Connect(function(obj)
	if monsterEspObjects[obj] then
		removeMonsterESP(obj)
	end
	if obj:IsA("Humanoid") and obj.Parent and monsterEspObjects[obj.Parent] then
		removeMonsterESP(obj.Parent)
	end
end))

track(monSwitchBg.MouseButton1Click:Connect(function()
	monsterEspEnabled = not monsterEspEnabled

	if monsterEspEnabled then
		switchOn(monSwitchBg, monSwitchKnob)
		scanMonstersAndApply()
	else
		switchOff(monSwitchBg, monSwitchKnob)
		clearAllMonsterESP()
	end
end))

track(RunService.RenderStepped:Connect(function()
	if not monsterEspEnabled then return end

	local char = player.Character
	local myPos
	if char then
		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
		myPos = root and root.Position
	end

	for target, data in pairs(monsterEspObjects) do
		if not target.Parent then
			removeMonsterESP(target)
		else
			local attachPart
			if target:IsA("Model") then
				attachPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
			elseif target:IsA("BasePart") then
				attachPart = target
			end
			if data.billboard then
				data.billboard.Adornee = attachPart or target
			end
			if data.highlight then
				data.highlight.Adornee = target
			end
			if data.nameLabel then
				if isMonster(target) then
					data.nameLabel.Text = "⚠ " .. target.Name .. " ⚠"
				else
					data.nameLabel.Text = "[Rig] " .. target.Name
				end
			end
			if data.distLabel and myPos then
				local tPos = getMonsterPosition(target)
				if tPos then
					data.distLabel.Text = string.format("[%.0f studs]", (tPos - myPos).Magnitude)
				end
			end
		end
	end
end))

local savedLighting = {}

local function applyFullbright()
	if not savedLighting.saved then
		savedLighting.Ambient = Lighting.Ambient
		savedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
		savedLighting.Brightness = Lighting.Brightness
		savedLighting.ClockTime = Lighting.ClockTime
		savedLighting.GlobalShadows = Lighting.GlobalShadows
		savedLighting.FogEnd = Lighting.FogEnd
		savedLighting.FogStart = Lighting.FogStart
		savedLighting.saved = true
	end

	if fullbrightEnabled then
		Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
		Lighting.Brightness = 3
		Lighting.ClockTime = 12
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 100000
		Lighting.FogStart = 0
	else
		Lighting.Ambient = savedLighting.Ambient
		Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
		Lighting.Brightness = savedLighting.Brightness
		Lighting.ClockTime = savedLighting.ClockTime
		Lighting.GlobalShadows = savedLighting.GlobalShadows
		Lighting.FogEnd = savedLighting.FogEnd
		Lighting.FogStart = savedLighting.FogStart
	end
end

track(fbSwitchBg.MouseButton1Click:Connect(function()
	fullbrightEnabled = not fullbrightEnabled

	if fullbrightEnabled then
		switchOn(fbSwitchBg, fbSwitchKnob)
	else
		switchOff(fbSwitchBg, fbSwitchKnob)
	end
	applyFullbright()
end))

local function restoreFullbright()
	if savedLighting.saved then
		Lighting.Ambient = savedLighting.Ambient
		Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
		Lighting.Brightness = savedLighting.Brightness
		Lighting.ClockTime = savedLighting.ClockTime
		Lighting.GlobalShadows = savedLighting.GlobalShadows
		Lighting.FogEnd = savedLighting.FogEnd
		Lighting.FogStart = savedLighting.FogStart
		savedLighting = {}
	end
end

local notifiedMonsters = {}

local MONSTER_NOTIFY_LIST = {
	Rush = true,
	Ambush = true,
	Eyes = true,
	Figure = true,
	Seek = true,
	Hide = true,
	Glitch = true,
	Jack = true,
}

local function isNotifyMonster(target)
	if not target then return false end
	if isBlacklistedMonster(target) then return false end
	local name = target.Name
	if MONSTER_NOTIFY_LIST[name] then return true end
	for mn, _ in pairs(MONSTER_NOTIFY_LIST) do
		if string.sub(string.lower(name), 1, #mn) == string.lower(mn) then
			return true
		end
	end
	return false
end

local notifGui = Instance.new("ScreenGui")
notifGui.Name = "RushNotifier"
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
notifGui.DisplayOrder = 998
notifGui.Parent = playerGui

local function showNotification(monsterName)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 320, 0, 80)
	frame.Position = UDim2.new(0.5, -160, 0, -100)
	frame.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	frame.BorderSizePixel = 0
	frame.Parent = notifGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 100, 100)
	stroke.Thickness = 3
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "⚠ МОНСТР СПАВНИЛСЯ ⚠"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.Parent = frame

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0, 26)
	nameLbl.Position = UDim2.new(0, 0, 0, 42)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = monsterName
	nameLbl.TextColor3 = Color3.fromRGB(255, 220, 100)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 22
	nameLbl.Parent = frame

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://4896323111"
	sound.Volume = 2
	sound.Parent = frame
	sound:Play()

	TweenService:Create(frame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -160, 0, 40) }):Play()

	task.delay(3, function()
		local t = TweenService:Create(frame,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, -160, 0, -100), BackgroundTransparency = 1 })
		t:Play()
		for _, obj in ipairs(frame:GetDescendants()) do
			if obj:IsA("TextLabel") then
				TweenService:Create(obj, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			elseif obj:IsA("UIStroke") then
				TweenService:Create(obj, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			end
		end
		t.Completed:Connect(function()
			frame:Destroy()
		end)
	end)
end

track(workspace.DescendantAdded:Connect(function(obj)
	if not notifierEnabled then return end
	if isNotifyMonster(obj) then
		if not notifiedMonsters[obj] then
			notifiedMonsters[obj] = true
			showNotification(obj.Name)
			task.delay(15, function()
				notifiedMonsters[obj] = nil
			end)
		end
	end
end))

track(notifSwitchBg.MouseButton1Click:Connect(function()
	notifierEnabled = not notifierEnabled

	if notifierEnabled then
		switchOn(notifSwitchBg, notifSwitchKnob)
	else
		switchOff(notifSwitchBg, notifSwitchKnob)
		notifiedMonsters = {}
	end
end))

local savedAntiLag = {}

local function isScreechSound(obj)
	if not obj.Parent then return false end
	local parentName = string.lower(obj.Parent.Name)
	return string.find(parentName, "screech", 1, true) ~= nil
end

local function applyAntiLag()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture") then
			if not savedAntiLag[obj] then
				savedAntiLag[obj] = {
					Material = obj:IsA("BasePart") and obj.Material or nil,
					TextureID = obj:IsA("Decal") and obj.Texture or (obj:IsA("Texture") and obj.Texture or nil),
					Transparency = obj:IsA("BasePart") and obj.Transparency or nil,
				}
			end

			if obj:IsA("BasePart") then
				obj.Material = Enum.Material.SmoothPlastic
				obj.Reflectance = 0
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				obj.Transparency = 1
			end
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail")
			or obj:IsA("Smoke") or obj:IsA("Fire")
			or obj:IsA("Sparkles") or obj:IsA("Beam") then
			obj.Enabled = false
		elseif obj:IsA("Sound") then
			if isScreechSound(obj) then
				obj.Volume = 1
			else
				obj.Volume = 0
			end
		end
	end
end

local function restoreAntiLag()
	for obj, data in pairs(savedAntiLag) do
		if obj and obj.Parent then
			if obj:IsA("BasePart") and data.Material then
				obj.Material = data.Material
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				obj.Transparency = 0
			elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail")
				or obj:IsA("Smoke") or obj:IsA("Fire")
				or obj:IsA("Sparkles") or obj:IsA("Beam") then
				obj.Enabled = true
			elseif obj:IsA("Sound") then
				obj.Volume = 1
			end
		end
	end
	savedAntiLag = {}
end

track(workspace.DescendantAdded:Connect(function(obj)
	if not antiLagEnabled then return end
	task.wait(0.1)
	if obj:IsA("BasePart") then
		obj.Material = Enum.Material.SmoothPlastic
		obj.Reflectance = 0
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		obj.Transparency = 1
	elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail")
		or obj:IsA("Smoke") or obj:IsA("Fire")
		or obj:IsA("Sparkles") or obj:IsA("Beam") then
		obj.Enabled = false
	elseif obj:IsA("Sound") then
		if isScreechSound(obj) then
			obj.Volume = 1
		else
			obj.Volume = 0
		end
	end
end))

track(lagSwitchBg.MouseButton1Click:Connect(function()
	antiLagEnabled = not antiLagEnabled

	if antiLagEnabled then
		switchOn(lagSwitchBg, lagSwitchKnob)
		applyAntiLag()
	else
		switchOff(lagSwitchBg, lagSwitchKnob)
		restoreAntiLag()
	end
end))

local menuOpen = false
track(toggleButton.MouseButton1Click:Connect(function()
	menuOpen = not menuOpen
	if menuOpen then
		menu.Visible = true
		menu.Position = UDim2.new(
			buttonHolder.Position.X.Scale,
			buttonHolder.Position.X.Offset,
			buttonHolder.Position.Y.Scale,
			buttonHolder.Position.Y.Offset + 50
		)
	else
		menu.Visible = false
	end
end))

local isLocked = false
local function updateLockLook()
	if isLocked then
		lockButton.Text = "Locked"
		lockButton.BackgroundColor3 = Color3.fromRGB(75, 0, 130)
	else
		lockButton.Text = "Unlocked"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 0, 200)
	end
end
updateLockLook()

track(lockButton.MouseButton1Click:Connect(function()
	isLocked = not isLocked
	updateLockLook()
end))

makeDraggable(buttonHolder, toggleButton, function() return not isLocked end)
makeDraggable(buttonHolder, lockButton, function() return not isLocked end)
makeDraggable(buttonHolder, unloadButton, function() return not isLocked end)
makeDraggable(menu, menu, function() return not isLocked end)

track(unloadButton.MouseButton1Click:Connect(function()
	for _, conn in ipairs(connections) do
		pcall(function() conn:Disconnect() end)
	end
	connections = {}

	pcall(function() cleanupSpeed() end)
	pcall(function() clearAllESP() end)
	pcall(function() clearAllToolESP() end)
	pcall(function() clearAllPromptESP() end)
	pcall(function() clearAllMonsterESP() end)
	pcall(function() restoreAllPrompts() end)
	pcall(function() restoreFullbright() end)
	pcall(function() restoreAntiLag() end)

	if notifGui and notifGui.Parent then notifGui:Destroy() end

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "ESP_GhostFolder" then obj:Destroy() end
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "ESP_Ghost" then obj:Destroy() end
	end

	for _, obj in ipairs(workspace:GetDescendants()) do
		local n = obj.Name
		if n == "ESP_Highlight" or n == "ESP_Billboard"
			or n == "ToolESP_Highlight" or n == "ToolESP_Billboard"
			or n == "PromptESP_Highlight" or n == "PromptESP_Billboard"
			or n == "MonsterESP_Highlight" or n == "MonsterESP_Billboard" then
			obj:Destroy()
		end
	end

	if gui and gui.Parent then
		gui:Destroy()
	end
end))

print("[MENU] Loaded. hookmetamethod:", hookOk and "OK" or "NOT SUPPORTED", "| ESP_RADIUS:", ESP_RADIUS)
