local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ProximityPromptService=game:GetService("ProximityPromptService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

local ESP_RADIUS=200
local DOOR_COLOR=Color3.fromRGB(80,255,80)
local LEVER_COLOR=Color3.fromRGB(80,255,80)
local isLocked=false

local gui=Instance.new("ScreenGui")
gui.Name="MenuUI"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=999
gui.Parent=playerGui

local function makeDraggable(frame,dragTarget,canDrag)
	local dragging,dragStart,startPos,dragInput
	local target=dragTarget or frame
	target.InputBegan:Connect(function(input)
		if canDrag and not canDrag() then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true dragStart=input.Position startPos=frame.Position
			input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
		end
	end)
	target.InputChanged:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if canDrag and not canDrag() then dragging=false return end
		if input==dragInput and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local delta=input.Position-dragStart
			frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
		end
	end)
end

local buttonHolder=Instance.new("Frame")
buttonHolder.Size=UDim2.new(0,320,0,40)
buttonHolder.Position=UDim2.new(0,20,0,20)
buttonHolder.BackgroundTransparency=1
buttonHolder.Active=true
buttonHolder.Parent=gui
local layout=Instance.new("UIListLayout")
layout.FillDirection=Enum.FillDirection.Horizontal
layout.Padding=UDim.new(0,10)
layout.Parent=buttonHolder

local function makeBtn(text,order,color,width)
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,width or 80,0,40)
	b.BackgroundColor3=color
	b.BorderSizePixel=0
	b.Text=text
	b.TextColor3=Color3.fromRGB(255,255,255)
	b.Font=Enum.Font.GothamBold
	b.TextSize=13
	b.LayoutOrder=order
	b.AutoButtonColor=false
	b.Active=true
	b.Parent=buttonHolder
	local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=b
	local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(200,150,255) s.Thickness=2 s.Parent=b
	return b
end

local toggleButton=makeBtn("Toggle",1,Color3.fromRGB(75,0,130),80)
local lockButton=makeBtn("Locked",2,Color3.fromRGB(75,0,130),90)
local unloadButton=makeBtn("Выгрузить",3,Color3.fromRGB(150,0,0),100)

local menu=Instance.new("Frame")
menu.Size=UDim2.new(0,280,0,300)
menu.Position=UDim2.new(0,20,0,80)
menu.BackgroundColor3=Color3.fromRGB(45,0,80)
menu.BorderSizePixel=0
menu.Visible=false
menu.Active=true
menu.Parent=gui
local mc=Instance.new("UICorner") mc.CornerRadius=UDim.new(0,10) mc.Parent=menu
local mst=Instance.new("UIStroke") mst.Color=Color3.fromRGB(180,100,255) mst.Thickness=2 mst.Parent=menu

local pages={}
for i=1,3 do
	local p=Instance.new("Frame")
	p.Size=UDim2.new(1,0,1,-40)
	p.BackgroundTransparency=1
	p.Visible=false
	p.Parent=menu
	pages[i]=p
end

local pageNav=Instance.new("Frame")
pageNav.Size=UDim2.new(1,-20,0,30)
pageNav.Position=UDim2.new(0,10,1,-35)
pageNav.BackgroundTransparency=1
pageNav.Parent=menu

local prevBtn=Instance.new("TextButton")
prevBtn.Size=UDim2.new(0,60,1,0)
prevBtn.BackgroundColor3=Color3.fromRGB(90,0,160)
prevBtn.BorderSizePixel=0
prevBtn.Text="◀"
prevBtn.TextColor3=Color3.fromRGB(255,255,255)
prevBtn.Font=Enum.Font.GothamBold
prevBtn.TextSize=18
prevBtn.AutoButtonColor=false
prevBtn.Parent=pageNav
local pc=Instance.new("UICorner") pc.CornerRadius=UDim.new(0,6) pc.Parent=prevBtn

local nextBtn=Instance.new("TextButton")
nextBtn.Size=UDim2.new(0,60,1,0)
nextBtn.Position=UDim2.new(1,-60,0,0)
nextBtn.BackgroundColor3=Color3.fromRGB(90,0,160)
nextBtn.BorderSizePixel=0
nextBtn.Text="▶"
nextBtn.TextColor3=Color3.fromRGB(255,255,255)
nextBtn.Font=Enum.Font.GothamBold
nextBtn.TextSize=18
nextBtn.AutoButtonColor=false
nextBtn.Parent=pageNav
local nc=Instance.new("UICorner") nc.CornerRadius=UDim.new(0,6) nc.Parent=nextBtn

local pageLabel=Instance.new("TextLabel")
pageLabel.Size=UDim2.new(1,-140,1,0)
pageLabel.Position=UDim2.new(0,70,0,0)
pageLabel.BackgroundTransparency=1
pageLabel.Text="1 / 3"
pageLabel.TextColor3=Color3.fromRGB(220,200,255)
pageLabel.Font=Enum.Font.GothamBold
pageLabel.TextSize=14
pageLabel.Parent=pageNav

local currentPage=1
local function showPage(n)
	if n<1 then n=3 end
	if n>3 then n=1 end
	currentPage=n
	for i,p in ipairs(pages) do p.Visible=(i==n) end
	pageLabel.Text=n.." / 3"
end
prevBtn.MouseButton1Click:Connect(function() showPage(currentPage-1) end)
nextBtn.MouseButton1Click:Connect(function() showPage(currentPage+1) end)

local function makeLabel(parent,text,y)
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(1,-20,0,16)
	l.Position=UDim2.new(0,10,0,y)
	l.BackgroundTransparency=1
	l.Text=text
	l.TextColor3=Color3.fromRGB(220,200,255)
	l.Font=Enum.Font.GothamBold
	l.TextSize=11
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.Parent=parent
	return l
end

local function makeSwitch(parent,y)
	local bg=Instance.new("TextButton")
	bg.Size=UDim2.new(0,40,0,20)
	bg.Position=UDim2.new(1,-50,0,y-2)
	bg.BackgroundColor3=Color3.fromRGB(60,60,60)
	bg.BorderSizePixel=0
	bg.Text=""
	bg.AutoButtonColor=false
	bg.Parent=parent
	local c=Instance.new("UICorner") c.CornerRadius=UDim.new(1,0) c.Parent=bg
	local knob=Instance.new("Frame")
	knob.Size=UDim2.new(0,14,0,14)
	knob.Position=UDim2.new(0,3,0.5,-7)
	knob.BackgroundColor3=Color3.fromRGB(255,255,255)
	knob.BorderSizePixel=0
	knob.Parent=bg
	local kc=Instance.new("UICorner") kc.CornerRadius=UDim.new(1,0) kc.Parent=knob
	return bg,knob
end

local function sOn(bg,knob)
	TweenService:Create(bg,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(120,0,200)}):Play()
	TweenService:Create(knob,TweenInfo.new(0.2),{Position=UDim2.new(0,23,0.5,-7)}):Play()
end

local function sOff(bg,knob)
	TweenService:Create(bg,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(60,60,60)}):Play()
	TweenService:Create(knob,TweenInfo.new(0.2),{Position=UDim2.new(0,3,0.5,-7)}):Play()
end

local function makeSlider(parent,y,min,max,def,onChange)
	local sb=Instance.new("Frame")
	sb.Size=UDim2.new(1,-20,0,8)
	sb.Position=UDim2.new(0,10,0,y)
	sb.BackgroundColor3=Color3.fromRGB(30,0,55)
	sb.BorderSizePixel=0
	sb.Active=true
	sb.Parent=parent
	local sc=Instance.new("UICorner") sc.CornerRadius=UDim.new(1,0) sc.Parent=sb
	local fill=Instance.new("Frame")
	fill.Size=UDim2.new((def-min)/(max-min),0,1,0)
	fill.BackgroundColor3=Color3.fromRGB(180,100,255)
	fill.BorderSizePixel=0
	fill.Parent=sb
	local fc=Instance.new("UICorner") fc.CornerRadius=UDim.new(1,0) fc.Parent=fill
	local knob=Instance.new("Frame")
	knob.Size=UDim2.new(0,14,0,14)
	knob.Position=UDim2.new((def-min)/(max-min),0,0.5,0)
	knob.AnchorPoint=Vector2.new(0,0.5)
	knob.BackgroundColor3=Color3.fromRGB(255,255,255)
	knob.BorderSizePixel=0
	knob.ZIndex=2
	knob.Parent=sb
	local kc=Instance.new("UICorner") kc.CornerRadius=UDim.new(1,0) kc.Parent=knob
	local dragging=false
	local function setV(v)
		v=math.clamp(v,min,max)
		local a=(v-min)/(max-min)
		fill.Size=UDim2.new(a,0,1,0)
		knob.Position=UDim2.new(a,0,0.5,0)
		if onChange then onChange(v) end
	end
	sb.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			local p=input.Position.X-sb.AbsolutePosition.X
			setV(min+math.clamp(p/sb.AbsoluteSize.X,0,1)*(max-min))
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local p=input.Position.X-sb.AbsolutePosition.X
			setV(min+math.clamp(p/sb.AbsoluteSize.X,0,1)*(max-min))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)
	return setV
end

local REAL_SPEED=16
local spoofing=false
local bv
local speedLoop
local oldIndex
local hookOk=false
pcall(function()
	oldIndex=hookmetamethod(game,"__index",newcclosure(function(self,key)
		if spoofing and key=="WalkSpeed" and self:IsA("Humanoid") and self:IsDescendantOf(player.Character) then
			return 15
		end
		return oldIndex(self,key)
	end))
	hookOk=true
end)

makeLabel(pages[1],"WALKSPEED (16-150)",2)
local wsVal=Instance.new("TextLabel")
wsVal.Size=UDim2.new(1,-20,0,14)
wsVal.Position=UDim2.new(0,10,0,18)
wsVal.BackgroundTransparency=1
wsVal.Text="REAL 16 / FAKE 15"
wsVal.TextColor3=Color3.fromRGB(255,255,255)
wsVal.Font=Enum.Font.GothamBold
wsVal.TextSize=10
wsVal.TextXAlignment=Enum.TextXAlignment.Left
wsVal.Parent=pages[1]

makeSlider(pages[1],36,16,150,REAL_SPEED,function(v)
	REAL_SPEED=math.floor(v+0.5)
	wsVal.Text="REAL "..REAL_SPEED.." / FAKE 15"
end)

local spSt=Instance.new("TextLabel")
spSt.Size=UDim2.new(1,-20,0,12)
spSt.Position=UDim2.new(0,10,0,50)
spSt.BackgroundTransparency=1
spSt.Text="Spoof: "..(hookOk and "READY" or "NOT SUPPORTED")
spSt.TextColor3=hookOk and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
spSt.Font=Enum.Font.GothamBold
spSt.TextSize=9
spSt.TextXAlignment=Enum.TextXAlignment.Left
spSt.Parent=pages[1]

makeLabel(pages[1],"ENABLE SPEED",66)
local sBg,sKnob=makeSwitch(pages[1],64)

makeLabel(pages[1],"FOV ENABLE",86)
local fovBg,fovKnob=makeSwitch(pages[1],84)

local fovVal=Instance.new("TextLabel")
fovVal.Size=UDim2.new(1,-20,0,12)
fovVal.Position=UDim2.new(0,10,0,104)
fovVal.BackgroundTransparency=1
fovVal.Text="FOV: 70"
fovVal.TextColor3=Color3.fromRGB(255,255,255)
fovVal.Font=Enum.Font.GothamBold
fovVal.TextSize=10
fovVal.TextXAlignment=Enum.TextXAlignment.Left
fovVal.Parent=pages[1]

local currentFOV=70
makeSlider(pages[1],120,1,120,70,function(v)
	currentFOV=math.floor(v)
	fovVal.Text="FOV: "..currentFOV
end)

makeLabel(pages[1],"FULLBRIGHT",138)
local fbBg,fbKnob=makeSwitch(pages[1],136)

local codeBtn=Instance.new("TextButton")
codeBtn.Size=UDim2.new(1,-20,0,26)
codeBtn.Position=UDim2.new(0,10,0,160)
codeBtn.BackgroundColor3=Color3.fromRGB(90,0,160)
codeBtn.BorderSizePixel=0
codeBtn.Text="Показать код библиотеки"
codeBtn.TextColor3=Color3.fromRGB(255,255,255)
codeBtn.Font=Enum.Font.GothamBold
codeBtn.TextSize=11
codeBtn.AutoButtonColor=false
codeBtn.Parent=pages[1]
local cbc=Instance.new("UICorner") cbc.CornerRadius=UDim.new(0,6) cbc.Parent=codeBtn

local function GetLibraryCode()
	local char=player.Character
	if not char then return "_____" end
	local paper=char:FindFirstChild("LibraryHintPaper")
		or char:FindFirstChild("LibraryHintPaperHard")
		or player.Backpack:FindFirstChild("LibraryHintPaper")
		or player.Backpack:FindFirstChild("LibraryHintPaperHard")
	if paper and paper:FindFirstChild("UI") then
		local code={"_","_","_","_","_"}
		local permUI=playerGui:FindFirstChild("PermUI")
		local hints=permUI and permUI:FindFirstChild("Hints")
		if hints then
			local hintChildren=hints:GetChildren()
			local uiChildren=paper.UI:GetChildren()
			for _,hint in ipairs(hintChildren) do
				for _,uiChild in ipairs(uiChildren) do
					if hint:IsA("ImageLabel") and uiChild:IsA("ImageLabel")
						and hint.ImageRectOffset==uiChild.ImageRectOffset
						and code[tonumber(uiChild.Name)] then
						code[tonumber(uiChild.Name)]=hint.TextLabel.Text
					end
				end
			end
		end
		return table.concat(code)
	end
	return "_____"
end

codeBtn.MouseButton1Click:Connect(function()
	local code=GetLibraryCode()
	print("[LIBRARY CODE]",code)
	codeBtn.Text="Код: "..code
	task.delay(5,function() codeBtn.Text="Показать код библиотеки" end)
end)

makeLabel(pages[2],"ESP PLAYERS",2)
local espBg,espKnob=makeSwitch(pages[2],0)
makeLabel(pages[2],"ESP TOOLS",22)
local toolBg,toolKnob=makeSwitch(pages[2],20)
makeLabel(pages[2],"ESP PROMPTS",42)
local promptBg,promptKnob=makeSwitch(pages[2],40)
makeLabel(pages[2],"ESP MONSTERS",62)
local monBg,monKnob=makeSwitch(pages[2],60)
makeLabel(pages[2],"INSTANT PROMPT",82)
local instBg,instKnob=makeSwitch(pages[2],80)

makeLabel(pages[3],"ANTICHEAT BYPASS",2)
local bypBg,bypKnob=makeSwitch(pages[3],0)

local bypHint=Instance.new("TextLabel")
bypHint.Size=UDim2.new(1,-20,0,12)
bypHint.Position=UDim2.new(0,10,0,18)
bypHint.BackgroundTransparency=1
bypHint.Text="Климб лестницу"
bypHint.TextColor3=Color3.fromRGB(180,180,180)
bypHint.Font=Enum.Font.Gotham
bypHint.TextSize=9
bypHint.TextXAlignment=Enum.TextXAlignment.Left
bypHint.Parent=pages[3]

makeLabel(pages[3],"DOOR REACH",34)
local doorBg,doorKnob=makeSwitch(pages[3],32)

makeLabel(pages[3],"ENTITY NOTIFY",54)
local notifyBg,notifyKnob=makeSwitch(pages[3],52)

makeLabel(pages[3],"ANTI-LAG",74)
local lagBg,lagKnob=makeSwitch(pages[3],72)

makeLabel(pages[3],"INFINITE ITEMS",94)
local infBg,infKnob=makeSwitch(pages[3],92)

local infHint=Instance.new("TextLabel")
infHint.Size=UDim2.new(1,-20,0,12)
infHint.Position=UDim2.new(0,10,0,112)
infHint.BackgroundTransparency=1
infHint.Text="Lockpick, Skeleton Key, Shears, Multitool"
infHint.TextColor3=Color3.fromRGB(150,150,150)
infHint.Font=Enum.Font.Gotham
infHint.TextSize=9
infHint.TextXAlignment=Enum.TextXAlignment.Left
infHint.Parent=pages[3]

showPage(1)

local speedEnabled=false
local fovEnabled=false
local fbEnabled=false
local espEnabled=false
local toolEnabled=false
local promptEnabled=false
local monsterEnabled=false
local instantEnabled=false
local bypassEnabled=false
local doorEnabled=false
local notifyEnabled=false
local lagEnabled=false
local infiniteItemsEnabled=false

local function cleanupSpeed()
	spoofing=false
	if speedLoop then speedLoop:Disconnect() speedLoop=nil end
	if bv and bv.Parent then bv:Destroy() end
	bv=nil
	local char=player.Character
	if char then
		local hum=char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed=15 end
		local root=char:FindFirstChild("HumanoidRootPart")
		if root then root.CustomPhysicalProperties=nil end
	end
end

local function applySpeed()
	local char=player.Character
	if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	local hum=char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	spoofing=true
	hum.WalkSpeed=15
	if not bv or not bv.Parent then
		bv=Instance.new("BodyVelocity")
		bv.MaxForce=Vector3.new(1e5,0,1e5)
		bv.P=1e5
		bv.Parent=root
	end
	root.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.3,0.5,1,1)
	if not speedLoop then
		speedLoop=RunService.Heartbeat:Connect(function()
			if not speedEnabled then return end
			local c=player.Character
			if not c then return end
			local h=c:FindFirstChildOfClass("Humanoid")
			if not h or not bv or not bv.Parent then return end
			local md=h.MoveDirection
			if md.Magnitude>0 then bv.Velocity=md*REAL_SPEED
			else bv.Velocity=Vector3.zero end
		end)
	end
end

sBg.MouseButton1Click:Connect(function()
	speedEnabled=not speedEnabled
	if speedEnabled then sOn(sBg,sKnob) applySpeed() else sOff(sBg,sKnob) cleanupSpeed() end
end)

local fovLoop
fovBg.MouseButton1Click:Connect(function()
	fovEnabled=not fovEnabled
	if fovEnabled then
		sOn(fovBg,fovKnob)
		local cam=workspace.CurrentCamera
		if cam then cam.FieldOfView=currentFOV end
		if not fovLoop then
			fovLoop=RunService.RenderStepped:Connect(function()
				if not fovEnabled then return end
				local c=workspace.CurrentCamera
				if c and c.FieldOfView~=currentFOV then c.FieldOfView=currentFOV end
			end)
		end
	else
		sOff(fovBg,fovKnob)
		if fovLoop then fovLoop:Disconnect() fovLoop=nil end
		local cam=workspace.CurrentCamera
		if cam then cam.FieldOfView=70 end
	end
end)

local savedLight={}
fbBg.MouseButton1Click:Connect(function()
	fbEnabled=not fbEnabled
	if fbEnabled then
		sOn(fbBg,fbKnob)
		if not savedLight.saved then
			savedLight.Ambient=Lighting.Ambient
			savedLight.OutdoorAmbient=Lighting.OutdoorAmbient
			savedLight.Brightness=Lighting.Brightness
			savedLight.ClockTime=Lighting.ClockTime
			savedLight.GlobalShadows=Lighting.GlobalShadows
			savedLight.FogEnd=Lighting.FogEnd
			savedLight.saved=true
		end
		Lighting.Ambient=Color3.fromRGB(178,178,178)
		Lighting.OutdoorAmbient=Color3.fromRGB(178,178,178)
		Lighting.Brightness=3
		Lighting.ClockTime=12
		Lighting.GlobalShadows=false
		Lighting.FogEnd=100000
	else
		sOff(fbBg,fbKnob)
		if savedLight.saved then
			Lighting.Ambient=savedLight.Ambient
			Lighting.OutdoorAmbient=savedLight.OutdoorAmbient
			Lighting.Brightness=savedLight.Brightness
			Lighting.ClockTime=savedLight.ClockTime
			Lighting.GlobalShadows=savedLight.GlobalShadows
			Lighting.FogEnd=savedLight.FogEnd
			savedLight={}
		end
	end
end)

local espObjects={}
local function createESP(tp)
	if tp==player or espObjects[tp] then return end
	local hl=Instance.new("Highlight")
	hl.FillColor=Color3.fromRGB(255,0,0)
	hl.OutlineColor=Color3.fromRGB(255,255,255)
	hl.FillTransparency=0.5
	hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent=tp.Character or tp
	local bb=Instance.new("BillboardGui")
	bb.Size=UDim2.new(0,200,0,30)
	bb.StudsOffset=Vector3.new(0,3,0)
	bb.AlwaysOnTop=true
	bb.Parent=tp.Character or tp
	local nl=Instance.new("TextLabel")
	nl.Size=UDim2.new(1,0,0,20)
	nl.BackgroundTransparency=1
	nl.Text=tp.Name
	nl.TextColor3=Color3.fromRGB(255,255,255)
	nl.TextStrokeTransparency=0
	nl.Font=Enum.Font.GothamBold
	nl.TextSize=14
	nl.Parent=bb
	espObjects[tp]={highlight=hl,billboard=bb}
end
local function removeESP(tp)
	local d=espObjects[tp]
	if d then
		if d.highlight then d.highlight:Destroy() end
		if d.billboard then d.billboard:Destroy() end
		espObjects[tp]=nil
	end
end
local function clearAllESP()
	for p,_ in pairs(espObjects) do removeESP(p) end
end

RunService.RenderStepped:Connect(function()
	if not espEnabled then return end
	local myChar=player.Character
	local myPos
	if myChar then
		local r=myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChildWhichIsA("BasePart")
		myPos=r and r.Position
	end
	for tp,data in pairs(espObjects) do
		local char=tp.Character
		local charPos
		if char then
			local h=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
			charPos=h and h.Position
		end
		local inRange=true
		if myPos and charPos then inRange=(charPos-myPos).Magnitude<=ESP_RADIUS end
		if char and data.highlight and inRange then
			data.highlight.Enabled=true
			data.highlight.Adornee=char
			if data.billboard then
				data.billboard.Enabled=true
				data.billboard.Adornee=char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
			end
		else
			if data.highlight then data.highlight.Enabled=false end
			if data.billboard then data.billboard.Enabled=false end
		end
	end
end)

local function watchChar(p)
	p.CharacterAdded:Connect(function()
		if espEnabled then removeESP(p) task.wait(0.5) createESP(p) end
	end)
end
for _,p in ipairs(Players:GetPlayers()) do watchChar(p) end
Players.PlayerAdded:Connect(function(p) watchChar(p) if espEnabled then createESP(p) end end)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

espBg.MouseButton1Click:Connect(function()
	espEnabled=not espEnabled
	if espEnabled then sOn(espBg,espKnob) for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
	else sOff(espBg,espKnob) clearAllESP() end
end)

local toolEspObjects={}
local function createToolESP(tool)
	if toolEspObjects[tool] or not tool:IsA("Tool") then return end
	local isDoor=tool.Name:sub(1,4)=="Door"
	local isLever=tool.Name:sub(1,5)=="Lever" or tool.Name=="LeverToGate"
	local hlColor
	local textColor
	if isDoor then
		hlColor=DOOR_COLOR
		textColor=DOOR_COLOR
	elseif isLever then
		hlColor=LEVER_COLOR
		textColor=LEVER_COLOR
	else
		hlColor=Color3.fromRGB(0,200,255)
		textColor=Color3.fromRGB(0,220,255)
	end
	local hl=Instance.new("Highlight")
	hl.FillColor=hlColor
	hl.OutlineColor=Color3.fromRGB(255,255,255)
	hl.FillTransparency=0.4
	hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee=tool
	hl.Parent=tool
	local bb=Instance.new("BillboardGui")
	bb.Size=UDim2.new(0,180,0,22)
	bb.StudsOffset=Vector3.new(0,1.5,0)
	bb.AlwaysOnTop=true
	bb.Parent=tool
	local ap=tool:FindFirstChildWhichIsA("BasePart")
	bb.Adornee=ap or tool
	local nl=Instance.new("TextLabel")
	nl.Size=UDim2.new(1,0,1,0)
	nl.BackgroundTransparency=1
	nl.Text=tool.Name
	nl.TextColor3=textColor
	nl.TextStrokeTransparency=0
	nl.Font=Enum.Font.GothamBold
	nl.TextSize=14
	nl.Parent=bb
	toolEspObjects[tool]={highlight=hl,billboard=bb,nameLabel=nl}
end
local function removeToolESP(tool)
	local d=toolEspObjects[tool]
	if d then
		if d.highlight then d.highlight:Destroy() end
		if d.billboard then d.billboard:Destroy() end
		toolEspObjects[tool]=nil
	end
end
local function clearAllToolESP()
	for t,_ in pairs(toolEspObjects) do removeToolESP(t) end
end
local function scanTools()
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Tool") then
			if toolEnabled then createToolESP(obj) else removeToolESP(obj) end
		end
	end
	for _,p in ipairs(Players:GetPlayers()) do
		local char=p.Character
		if char then
			for _,obj in ipairs(char:GetChildren()) do
				if obj:IsA("Tool") then if toolEnabled then createToolESP(obj) else removeToolESP(obj) end end
			end
		end
		local bp=p:FindFirstChildOfClass("Backpack")
		if bp then
			for _,obj in ipairs(bp:GetChildren()) do
				if obj:IsA("Tool") then if toolEnabled then createToolESP(obj) else removeToolESP(obj) end end
			end
		end
	end
end
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Tool") and toolEnabled then task.wait(0.1) createToolESP(obj) end
end)
toolBg.MouseButton1Click:Connect(function()
	toolEnabled=not toolEnabled
	if toolEnabled then sOn(toolBg,toolKnob) scanTools() else sOff(toolBg,toolKnob) clearAllToolESP() end
end)

RunService.RenderStepped:Connect(function()
	if not toolEnabled then return end
	local myChar=player.Character
	local myPos
	if myChar then
		local r=myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChildWhichIsA("BasePart")
		myPos=r and r.Position
	end
	for tool,data in pairs(toolEspObjects) do
		if not tool.Parent then removeToolESP(tool)
		else
			local ap=tool:FindFirstChildWhichIsA("BasePart")
			local toolPos=ap and ap.Position
			local inRange=true
			if myPos and toolPos then inRange=(toolPos-myPos).Magnitude<=ESP_RADIUS end
			if data.highlight then data.highlight.Enabled=inRange end
			if data.billboard then data.billboard.Enabled=inRange end
			if data.billboard then data.billboard.Adornee=ap or tool end
			if data.highlight then data.highlight.Adornee=tool end
			if data.nameLabel then data.nameLabel.Text=tool.Name end
		end
	end
end)

local PROMPT_BLACKLIST={Painting=true,Drawer=true,Toilet=true,Regal=true,HidePrompt=true,Hide=true}
local PROMPT_BLUELIST={Key=true}

local function isBlacklisted(target)
	if not target then return false end
	local name=target.Name
	if PROMPT_BLACKLIST[name] then return true end
	for blocked,_ in pairs(PROMPT_BLACKLIST) do
		if string.find(string.lower(name),string.lower(blocked),1,true) then return true end
	end
	return false
end

local function isBlueListed(target)
	if not target then return false end
	local name=string.lower(target.Name)
	for blue,_ in pairs(PROMPT_BLUELIST) do
		if string.sub(name,1,#blue)==string.lower(blue) then return true end
	end
	return false
end

local function getPromptTarget(prompt)
	local parent=prompt.Parent
	if not parent then return nil end
	if parent:IsA("Model") then return parent
	elseif parent:IsA("BasePart") then
		local model=parent:FindFirstAncestorOfClass("Model")
		return model or parent
	end
	return nil
end

local promptEspObjects={}
local function createPromptESP(prompt)
	local target=getPromptTarget(prompt)
	if not target or promptEspObjects[target] then return end
	if target==player.Character or isBlacklisted(target) then return end
	local isDoor=target.Name:sub(1,4)=="Door"
	local isLever=target.Name:sub(1,5)=="Lever" or target.Name=="LeverToGate"
	local isBlue=isBlueListed(target)
	local fc,tc
	if isDoor then
		fc=DOOR_COLOR
		tc=DOOR_COLOR
	elseif isLever then
		fc=LEVER_COLOR
		tc=LEVER_COLOR
	elseif isBlue then
		fc=Color3.fromRGB(0,150,255)
		tc=Color3.fromRGB(0,200,255)
	else
		fc=Color3.fromRGB(255,200,0)
		tc=Color3.fromRGB(255,220,0)
	end
	local hl=Instance.new("Highlight")
	hl.FillColor=fc
	hl.OutlineColor=Color3.fromRGB(255,255,255)
	hl.FillTransparency=0.5
	hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee=target
	hl.Parent=target
	local bb=Instance.new("BillboardGui")
	bb.Size=UDim2.new(0,220,0,58)
	bb.StudsOffset=Vector3.new(0,2.5,0)
	bb.AlwaysOnTop=true
	local ap
	if target:IsA("Model") then ap=target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	elseif target:IsA("BasePart") then ap=target end
	bb.Adornee=ap or target
	bb.Parent=ap or target
	local nl=Instance.new("TextLabel")
	nl.Size=UDim2.new(1,0,0,18)
	nl.BackgroundTransparency=1
	nl.Text=target.Name
	nl.TextColor3=tc
	nl.TextStrokeTransparency=0
	nl.Font=Enum.Font.GothamBold
	nl.TextSize=14
	nl.Parent=bb
	local pl=Instance.new("TextLabel")
	pl.Size=UDim2.new(1,0,0,16)
	pl.Position=UDim2.new(0,0,0,18)
	pl.BackgroundTransparency=1
	pl.Text=prompt.ActionText~="" and prompt.ActionText or "Interact"
	pl.TextColor3=Color3.fromRGB(255,255,255)
	pl.TextStrokeTransparency=0
	pl.Font=Enum.Font.Gotham
	pl.TextSize=12
	pl.Parent=bb
	local dl=Instance.new("TextLabel")
	dl.Size=UDim2.new(1,0,0,16)
	dl.Position=UDim2.new(0,0,0,34)
	dl.BackgroundTransparency=1
	dl.Text="[0 studs]"
	dl.TextColor3=Color3.fromRGB(180,255,180)
	dl.TextStrokeTransparency=0
	dl.Font=Enum.Font.GothamBold
	dl.TextSize=12
	dl.Parent=bb
	promptEspObjects[target]={highlight=hl,billboard=bb,nameLabel=nl,promptLabel=pl,distLabel=dl,prompt=prompt}
end
local function removePromptESP(target)
	local d=promptEspObjects[target]
	if d then
		if d.highlight then d.highlight:Destroy() end
		if d.billboard then d.billboard:Destroy() end
		promptEspObjects[target]=nil
	end
end
local function clearAllPromptESP()
	for t,_ in pairs(promptEspObjects) do removePromptESP(t) end
end
local function scanPrompts()
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			local target=getPromptTarget(obj)
			if target then
				if promptEnabled and not isBlacklisted(target) then createPromptESP(obj)
				else removePromptESP(target) end
			end
		end
	end
end
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ProximityPrompt") and promptEnabled then
		task.wait(0.1)
		local target=getPromptTarget(obj)
		if target and not isBlacklisted(target) then createPromptESP(obj) end
	end
end)
promptBg.MouseButton1Click:Connect(function()
	promptEnabled=not promptEnabled
	if promptEnabled then sOn(promptBg,promptKnob) scanPrompts() else sOff(promptBg,promptKnob) clearAllPromptESP() end
end)

RunService.RenderStepped:Connect(function()
	if not promptEnabled then return end
	local char=player.Character
	local myPos
	if char then
		local r=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
		myPos=r and r.Position
	end
	for target,data in pairs(promptEspObjects) do
		if not target.Parent then removePromptESP(target)
		else
			local ap
			if target:IsA("Model") then ap=target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
			elseif target:IsA("BasePart") then ap=target end
			local inRange=true
			if myPos and ap then inRange=(ap.Position-myPos).Magnitude<=ESP_RADIUS end
			if data.billboard then data.billboard.Enabled=inRange data.billboard.Adornee=ap or target end
			if data.highlight then data.highlight.Enabled=inRange data.highlight.Adornee=target end
			if data.nameLabel then data.nameLabel.Text=target.Name end
			if data.promptLabel and data.prompt and data.prompt.Parent then
				data.promptLabel.Text=data.prompt.ActionText~="" and data.prompt.ActionText or "Interact"
			end
			if data.distLabel and myPos and ap then
				data.distLabel.Text=string.format("[%.0f studs]",(ap.Position-myPos).Magnitude)
			end
		end
	end
end)

local savedPrompts={}
local function makePromptInstant(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	if savedPrompts[prompt] then return end
	savedPrompts[prompt]={HoldDuration=prompt.HoldDuration,MaxActivationDistance=prompt.MaxActivationDistance,RequiresLineOfSight=prompt.RequiresLineOfSight,ClickablePrompt=prompt.ClickablePrompt}
	prompt.HoldDuration=0
	prompt.RequiresLineOfSight=false
	prompt.ClickablePrompt=true
end
local function restorePrompt(prompt)
	local s=savedPrompts[prompt]
	if not s then return end
	if prompt and prompt.Parent then
		prompt.HoldDuration=s.HoldDuration
		prompt.MaxActivationDistance=s.MaxActivationDistance
		prompt.RequiresLineOfSight=s.RequiresLineOfSight
		prompt.ClickablePrompt=s.ClickablePrompt
	end
	savedPrompts[prompt]=nil
end
local function applyInstant()
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			if instantEnabled then makePromptInstant(obj) else restorePrompt(obj) end
		end
	end
end
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ProximityPrompt") and instantEnabled then task.wait(0.1) makePromptInstant(obj) end
end)
instBg.MouseButton1Click:Connect(function()
	instantEnabled=not instantEnabled
	if instantEnabled then sOn(instBg,instKnob) else sOff(instBg,instKnob) end
	applyInstant()
end)

local MONSTER_PREFIXES={"Rush","Ambush","Eyes","Figure","Seek","Hide","Glitch","Jack"}
local MONSTER_BLACKLIST={SeekArms=true,FigureAttach=true,FigureRig=true,FigureArm=true,FigureLeg=true,FigureHead=true,FigureTorso=true,FigureBody=true,Attachment=true,Attachments=true,Hitbox=true,HitBox=true,Rig=true,RootPart=true,Root=true,HidePrompt=true,HidePrompts=true,Prompt=true,Prompts=true,Trigger=true,Triggers=true,Detector=true,Sensor=true,Collision=true,Collider=true,Region=true,Zone=true,Area=true,Marker=true,Point=true,Spawn=true,Spawner=true,Anchor=true,Base=true,Stand=true,Stand1=true,Stand2=true,Stand3=true,Stand4=true,Stand5=true,Stand6=true,Stand7=true,Stand8=true}
local function isBlackMonster(t)
	if not t then return false end
	local n=string.lower(t.Name)
	for b,_ in pairs(MONSTER_BLACKLIST) do
		if string.find(n,string.lower(b),1,true) then return true end
	end
	return false
end
local function isPlayerChar(t)
	if not t or not t:IsA("Model") then return false end
	return Players:GetPlayerFromCharacter(t)~=nil
end
local function isMonster(t)
	if not t or isBlackMonster(t) then return false end
	local n=string.lower(t.Name)
	for _,p in ipairs(MONSTER_PREFIXES) do
		if string.sub(n,1,#p)==string.lower(p) then return true end
	end
	return false
end
local function isRig(t)
	if not t or not t:IsA("Model") then return false end
	if isPlayerChar(t) or isMonster(t) or isBlackMonster(t) then return false end
	if not t:FindFirstChildOfClass("Humanoid") then return false end
	if not t:FindFirstChild("HumanoidRootPart") then return false end
	return true
end
local function shouldMonster(t)
	if isPlayerChar(t) or isBlackMonster(t) then return false end
	return isMonster(t) or isRig(t)
end

local monsterEspObjects={}
local function createMonsterESP(target)
	if monsterEspObjects[target] or not shouldMonster(target) then return end
	local fc,oc,tc
	if isMonster(target) then
		fc=Color3.fromRGB(255,0,0)
		oc=Color3.fromRGB(255,100,100)
		tc=Color3.fromRGB(255,50,50)
	else
		fc=Color3.fromRGB(255,140,0)
		oc=Color3.fromRGB(255,200,100)
		tc=Color3.fromRGB(255,180,60)
	end
	local hl=Instance.new("Highlight")
	hl.FillColor=fc
	hl.OutlineColor=oc
	hl.FillTransparency=0.4
	hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee=target
	hl.Parent=target
	local bb=Instance.new("BillboardGui")
	bb.Size=UDim2.new(0,220,0,40)
	bb.StudsOffset=Vector3.new(0,3,0)
	bb.AlwaysOnTop=true
	local ap
	if target:IsA("Model") then ap=target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	elseif target:IsA("BasePart") then ap=target end
	bb.Adornee=ap or target
	bb.Parent=ap or target
	local nl=Instance.new("TextLabel")
	nl.Size=UDim2.new(1,0,0,20)
	nl.BackgroundTransparency=1
	nl.Text=(isMonster(target) and "⚠ " or "[Rig] ")..target.Name..(isMonster(target) and " ⚠" or "")
	nl.TextColor3=tc
	nl.TextStrokeTransparency=0
	nl.Font=Enum.Font.GothamBold
	nl.TextSize=16
	nl.Parent=bb
	local dl=Instance.new("TextLabel")
	dl.Size=UDim2.new(1,0,0,16)
	dl.Position=UDim2.new(0,0,0,20)
	dl.BackgroundTransparency=1
	dl.Text="[0 studs]"
	dl.TextColor3=Color3.fromRGB(255,220,180)
	dl.TextStrokeTransparency=0
	dl.Font=Enum.Font.GothamBold
	dl.TextSize=12
	dl.Parent=bb
	monsterEspObjects[target]={highlight=hl,billboard=bb,nameLabel=nl,distLabel=dl}
end
local function removeMonsterESP(target)
	local d=monsterEspObjects[target]
	if d then
		if d.highlight then d.highlight:Destroy() end
		if d.billboard then d.billboard:Destroy() end
		monsterEspObjects[target]=nil
	end
end
local function clearAllMonsterESP()
	for t,_ in pairs(monsterEspObjects) do removeMonsterESP(t) end
end
local function scanMonsters()
	for _,obj in ipairs(workspace:GetDescendants()) do
		if shouldMonster(obj) then
			if monsterEnabled then createMonsterESP(obj) else removeMonsterESP(obj) end
		end
	end
end
workspace.DescendantAdded:Connect(function(obj)
	if monsterEnabled and shouldMonster(obj) then task.wait(0.1) createMonsterESP(obj) end
end)
monBg.MouseButton1Click:Connect(function()
	monsterEnabled=not monsterEnabled
	if monsterEnabled then sOn(monBg,monKnob) scanMonsters() else sOff(monBg,monKnob) clearAllMonsterESP() end
end)
RunService.RenderStepped:Connect(function()
	if not monsterEnabled then return end
	local char=player.Character
	local myPos
	if char then
		local r=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
		myPos=r and r.Position
	end
	for target,data in pairs(monsterEspObjects) do
		if not target.Parent then removeMonsterESP(target)
		else
			local ap
			if target:IsA("Model") then ap=target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
			elseif target:IsA("BasePart") then ap=target end
			if data.billboard then data.billboard.Adornee=ap or target end
			if data.highlight then data.highlight.Adornee=target end
			if data.distLabel and myPos and ap then
				data.distLabel.Text=string.format("[%.0f studs]",(ap.Position-myPos).Magnitude)
			end
		end
	end
end)

local anticheatDisabled=false
local function setupBypass(char)
	if not char then char=player.Character end
	if not char then return end
	local remotes=ReplicatedStorage:FindFirstChild("RemotesFolder")
	if not remotes then return end
	local climbLadder=remotes:FindFirstChild("ClimbLadder")
	char:GetAttributeChangedSignal("Climbing"):Connect(function()
		if char:GetAttribute("Climbing")==true and bypassEnabled then
			task.wait(0.25)
			if char:GetAttribute("Climbing")==true then
				char:SetAttribute("Climbing",false)
				if climbLadder then pcall(function() climbLadder:FireServer() end) end
				anticheatDisabled=true
				print("[BYPASS] Anticheat disabled")
			end
		end
	end)
end

local remotes=ReplicatedStorage:WaitForChild("RemotesFolder",10)
if remotes then
	local cutscene=remotes:FindFirstChild("Cutscene")
	if cutscene then
		cutscene.OnClientEvent:Connect(function(name)
			if anticheatDisabled and not tostring(name):find("SewerSeek") then anticheatDisabled=false end
		end)
	end
	local enemy=remotes:FindFirstChild("UseEnemyModule")
	if enemy then
		enemy.OnClientEvent:Connect(function(m)
			if m=="Void" or m=="Glitch" then anticheatDisabled=false end
		end)
	end
end

bypBg.MouseButton1Click:Connect(function()
	bypassEnabled=not bypassEnabled
	if bypassEnabled then
		sOn(bypBg,bypKnob)
		if player.Character then setupBypass(player.Character) end
		print("[BYPASS] Enabled - climb a ladder")
	else
		sOff(bypBg,bypKnob)
		anticheatDisabled=false
	end
end)

local doorLoop
doorBg.MouseButton1Click:Connect(function()
	doorEnabled=not doorEnabled
	if doorEnabled then
		sOn(doorBg,doorKnob)
		if not doorLoop then
			doorLoop=RunService.Heartbeat:Connect(function()
				if not doorEnabled then return end
				local char=player.Character
				if not char or not char:FindFirstChild("HumanoidRootPart") then return end
				local myPos=char.HumanoidRootPart.Position
				for _,obj in ipairs(workspace:GetDescendants()) do
					if obj.Name=="ClientOpen" and obj:IsA("RemoteEvent") then
						local door=obj.Parent
						if door and door:FindFirstChild("Door") then
							if (door.Door.Position-myPos).Magnitude<75 then pcall(function() obj:FireServer() end) end
						end
					end
				end
			end)
		end
	else
		sOff(doorBg,doorKnob)
		if doorLoop then doorLoop:Disconnect() doorLoop=nil end
	end
end)

local notifGui=Instance.new("ScreenGui")
notifGui.Name="EntityNotifier"
notifGui.ResetOnSpawn=false
notifGui.IgnoreGuiInset=true
notifGui.DisplayOrder=998
notifGui.Parent=playerGui

local ENTITY_LIST={["RushMoving"]="Rush",["AmbushMoving"]="Ambush",["Eyes"]="Eyes",["Lookman"]="Eyes",["BackdoorRush"]="Blitz",["BackdoorLookman"]="Lookman",["A60"]="A-60",["A120"]="A-120",["GloombatSwarm"]="Gloombat Swarm",["GlitchRush"]="RNIUSHCG==",["GlitchAmbush"]="AR0xMBUSH",["MonumentEntity"]="Monument",["JeffTheKiller"]="Jeff the Killer",["FrozenAmbush"]="Frozen Ambush",["SallyMoving"]="Sally",["Groundskeeper"]="Groundskeeper"}
local notified={}

local function showNotification(name)
	local frame=Instance.new("Frame")
	frame.Size=UDim2.new(0,320,0,70)
	frame.Position=UDim2.new(0.5,-160,0,-100)
	frame.BackgroundColor3=Color3.fromRGB(150,0,0)
	frame.BorderSizePixel=0
	frame.Parent=notifGui
	local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,12) c.Parent=frame
	local st=Instance.new("UIStroke") st.Color=Color3.fromRGB(255,100,100) st.Thickness=3 st.Parent=frame
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,0,0,26)
	title.Position=UDim2.new(0,0,0,8)
	title.BackgroundTransparency=1
	title.Text="⚠ МОНСТР ⚠"
	title.TextColor3=Color3.fromRGB(255,255,255)
	title.Font=Enum.Font.GothamBold
	title.TextSize=18
	title.Parent=frame
	local nl=Instance.new("TextLabel")
	nl.Size=UDim2.new(1,0,0,24)
	nl.Position=UDim2.new(0,0,0,36)
	nl.BackgroundTransparency=1
	nl.Text=name
	nl.TextColor3=Color3.fromRGB(255,220,100)
	nl.Font=Enum.Font.GothamBold
	nl.TextSize=20
	nl.Parent=frame
	local s=Instance.new("Sound")
	s.SoundId="rbxassetid://4896323111"
	s.Volume=2
	s.Parent=frame
	s:Play()
	TweenService:Create(frame,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-160,0,40)}):Play()
	task.delay(3,function()
		local t=TweenService:Create(frame,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(0.5,-160,0,-100),BackgroundTransparency=1})
		t:Play()
		for _,obj in ipairs(frame:GetDescendants()) do
			if obj:IsA("TextLabel") then TweenService:Create(obj,TweenInfo.new(0.4),{TextTransparency=1}):Play()
			elseif obj:IsA("UIStroke") then TweenService:Create(obj,TweenInfo.new(0.4),{Transparency=1}):Play() end
		end
		t.Completed:Connect(function() frame:Destroy() end)
	end)
end
workspace.DescendantAdded:Connect(function(obj)
	if not notifyEnabled then return end
	local alias=ENTITY_LIST[obj.Name]
	if alias and not notified[obj] then
		notified[obj]=true
		showNotification(alias)
		task.delay(15,function() notified[obj]=nil end)
	end
end)
notifyBg.MouseButton1Click:Connect(function()
	notifyEnabled=not notifyEnabled
	if notifyEnabled then sOn(notifyBg,notifyKnob) else sOff(notifyBg,notifyKnob) notified={} end
end)

local savedAntiLag={}
local function isScreechSound(obj)
	if not obj.Parent then return false end
	local pn=string.lower(obj.Parent.Name)
	return string.find(pn,"screech",1,true)~=nil
end
local function applyAntiLag()
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture") then
			if not savedAntiLag[obj] then savedAntiLag[obj]={Material=obj:IsA("BasePart") and obj.Material or nil} end
			if obj:IsA("BasePart") then obj.Material=Enum.Material.SmoothPlastic obj.Reflectance=0
			elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency=1 end
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
			obj.Enabled=false
		elseif obj:IsA("Sound") then
			if isScreechSound(obj) then obj.Volume=1 else obj.Volume=0 end
		end
	end
end
local function restoreAntiLag()
	for obj,data in pairs(savedAntiLag) do
		if obj and obj.Parent and obj:IsA("BasePart") and data.Material then obj.Material=data.Material end
	end
	savedAntiLag={}
end
lagBg.MouseButton1Click:Connect(function()
	lagEnabled=not lagEnabled
	if lagEnabled then sOn(lagBg,lagKnob) applyAntiLag() else sOff(lagBg,lagKnob) restoreAntiLag() end
end)

local ITEM_NAMES={["Lockpick"]="Lockpicks",["SkeletonKey"]="Skeleton Key",["Shears"]="Shears",["Multitool"]="Multitool"}

local function firePrompt(prompt)
	if not prompt then return end
	pcall(function() fireproximityprompt(prompt) end)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if not infiniteItemsEnabled then return end
	if not remotes then return end
	local drops=workspace:FindFirstChild("Drops")
	if not drops then return end
	local dropRemote=remotes:FindFirstChild("DropItem")
	if not dropRemote then return end
	
	local char=player.Character
	if not char then return end
	
	local anyTool=char:FindFirstChildOfClass("Tool")
	if not anyTool then return end
	
	local toolData=ITEM_NAMES[anyTool.Name]
	if not toolData then return end
	
	drops.ChildAdded:Once(function(newTool)
		local dropPrompt=newTool:FindFirstChild("ModulePrompt")
		if dropPrompt then
			firePrompt(dropPrompt)
		end
	end)
	
	pcall(function() dropRemote:FireServer(anyTool) end)
end)

infBg.MouseButton1Click:Connect(function()
	infiniteItemsEnabled=not infiniteItemsEnabled
	if infiniteItemsEnabled then
		sOn(infBg,infKnob)
		print("[INFINITE ITEMS] ON")
	else
		sOff(infBg,infKnob)
		print("[INFINITE ITEMS] OFF")
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	if speedEnabled then cleanupSpeed() applySpeed() end
	if bypassEnabled then setupBypass(player.Character) end
end)

makeDraggable(buttonHolder,toggleButton,function() return not isLocked end)
makeDraggable(buttonHolder,lockButton,function() return not isLocked end)
makeDraggable(buttonHolder,unloadButton,function() return not isLocked end)
makeDraggable(menu,menu,function() return not isLocked end)

local menuOpen=false
toggleButton.MouseButton1Click:Connect(function()
	menuOpen=not menuOpen
	menu.Visible=menuOpen
	if menuOpen then
		menu.Position=UDim2.new(buttonHolder.Position.X.Scale,buttonHolder.Position.X.Offset,buttonHolder.Position.Y.Scale,buttonHolder.Position.Y.Offset+50)
	end
end)

lockButton.MouseButton1Click:Connect(function()
	isLocked=not isLocked
	if isLocked then
		lockButton.Text="Locked"
		lockButton.BackgroundColor3=Color3.fromRGB(75,0,130)
	else
		lockButton.Text="Unlocked"
		lockButton.BackgroundColor3=Color3.fromRGB(120,0,200)
	end
end)

unloadButton.MouseButton1Click:Connect(function()
	speedEnabled=false
	fovEnabled=false
	fbEnabled=false
	espEnabled=false
	toolEnabled=false
	promptEnabled=false
	monsterEnabled=false
	instantEnabled=false
	bypassEnabled=false
	doorEnabled=false
	notifyEnabled=false
	lagEnabled=false
	infiniteItemsEnabled=false
	anticheatDisabled=false

	pcall(cleanupSpeed)
	pcall(clearAllESP)
	pcall(clearAllToolESP)
	pcall(clearAllPromptESP)
	pcall(clearAllMonsterESP)
	pcall(restoreAntiLag)

	if savedLight.saved then
		Lighting.Ambient=savedLight.Ambient
		Lighting.OutdoorAmbient=savedLight.OutdoorAmbient
		Lighting.Brightness=savedLight.Brightness
		Lighting.ClockTime=savedLight.ClockTime
		Lighting.GlobalShadows=savedLight.GlobalShadows
		Lighting.FogEnd=savedLight.FogEnd
		savedLight={}
	end

	if notifGui and notifGui.Parent then notifGui:Destroy() end
	if gui and gui.Parent then gui:Destroy() end
end)

print("[MENU] Loaded. hookmetamethod:",hookOk and "OK" or "NOT SUPPORTED")
