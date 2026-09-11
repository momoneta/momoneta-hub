-- ============ UI: Elerium v2 (estilo Silence, adaptador Rayfield) ============
local GUI_LIB_URL = "https://raw.githubusercontent.com/momoneta/momoneta-hub/refs/heads/main/mome.lua"
-- PEGA AQUI TU LINK raw DE GitHub CUANDO SUBAS elerium-momoneta.luau
local library = loadstring(game:HttpGet(GUI_LIB_URL, true))()
local _eleriumWindow = library:AddWindow("La momoneta Hub", {
	main_color = Color3.fromRGB(0, 0, 139),
	min_size = Vector2.new(500, 620),
	can_resize = true,
})
local Rayfield = {}
function Rayfield:CreateWindow(_config)
	local Window = {}
	function Window:CreateTab(opt)
		local name = type(opt) == "table" and (opt.name or opt.Name or "Tab") or tostring(opt)
		local tab = _eleriumWindow:AddTab(name)
		local T = {}
		function T:CreateToggle(opt2)
			local state = false
			local busy = false
			local sw = tab:AddSwitch(opt2.Name, function(v)
				if busy then return end
				state = v and true or false
				pcall(opt2.Callback, state)
			end)
			if opt2.CurrentValue == true then
				sw:Set(true)
			end
			return {
				Set = function(_, v)
					v = (v == true)
					if state == v then return end
					busy = true
					sw:Set(v)
					busy = false
					state = v
					pcall(opt2.Callback, v)
				end,
				Get = function() return state end,
			}
		end
		function T:CreateDropdown(opt2)
			local dd = tab:AddDropdown(opt2.Name, function(sel)
				pcall(opt2.Callback, sel)
			end)
			if type(opt2.Options) == "table" then
				for _, op in ipairs(opt2.Options) do
					pcall(function() dd:Add(op) end)
				end
			end
			return dd
		end
		function T:CreateSlider(opt2)
			local range = opt2.Range or { 1, 100 }
			local sl = tab:AddSlider(opt2.Name, function(v)
				pcall(opt2.Callback, v)
			end, { min = range[1], max = range[2] })
			return sl
		end
		function T:CreateButton(opt2)
			return tab:AddButton(opt2.Name, function()
				pcall(opt2.Callback)
			end)
		end
		function T:CreateText(opt2)
			local label = tab:AddLabel(opt2.Name or "")
			if opt2.Description then
				label.Text = tostring(opt2.Name or "") .. "\n" .. tostring(opt2.Description)
			end
			return {
				Set = function(_, t)
					label.Text = tostring(t)
				end,
			}
		end
		function T:CreateDivider(opt2)
			if type(opt2) == "table" then
				tab:AddLabel(tostring(opt2.text or opt2.Text or ""))
			else
				tab:AddLabel(tostring(opt2 or ""))
			end
		end
		return T
	end
	function Window:Notify(opt2)
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = tostring(opt2.Title or "Hub"),
				Text = tostring(opt2.Content or opt2.Text or ""),
				Duration = tonumber(opt2.Duration) or 3,
			})
		end)
	end
	return Window
end

local Window = Rayfield:CreateWindow({
	Name = "La momoneta Hub",
	LoadingTitle = "La momoneta Hub",
	LoadingSubtitle = "by Yail",
	ConfigurationSaving = { Enabled = true, FolderName = "LaMomonetaHub", FileName = "Config" },
	KeySystem = false
})

local MainTab = Window:CreateTab({ name = "Main" })
local FarmTab = Window:CreateTab({ name = "Farm" })
local TravelTab = Window:CreateTab({ name = "Islands" })
local ShopTab = Window:CreateTab({ name = "Shop" })

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local muscleEvent = LocalPlayer:WaitForChild("muscleEvent")
local equipPetEvent = ReplicatedStorage.rEvents:WaitForChild("equipPetEvent")
local exclusiveEggOpenRemote = ReplicatedStorage.rEvents:WaitForChild("exclusiveEggOpenRemote")
local enemyNPCs = Workspace:WaitForChild("enemyNPCs")
local currentMap = LocalPlayer:WaitForChild("currentMap")
local rebirthRemote = ReplicatedStorage.rEvents:WaitForChild("rebirthRemote")
local machineInteractRemote = ReplicatedStorage.rEvents:WaitForChild("machineInteractRemote")
local changeSpeedSizeRemote = ReplicatedStorage.rEvents:WaitForChild("changeSpeedSizeRemote")

local function getSeat(h)
	if not h then return nil end
	return h.SeatPart
end

-- ============ FAST PUNCH ============
local fastPunch = false
local fastPunchGen = 0

local function getPunchTool()
	local c = LocalPlayer.Character
	if c then
		local t = c:FindFirstChild("Punch")
		if t then return t end
	end
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if bp then
		for _, t in pairs(bp:GetChildren()) do
			if t:IsA("Tool") and t.Name:lower():find("punch") then return t end
		end
	end
	return nil
end

local punchVisual = { character = nil, tracks = {} }
local function clearPunchVisual()
	for _, tr in pairs(punchVisual.tracks) do
		pcall(function() tr:Stop(0.05) tr:Destroy() end)
	end
	punchVisual.character = nil
	punchVisual.tracks = {}
end
local function playPunchVisual()
	local c = LocalPlayer.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local animator = h and (h:FindFirstChildOfClass("Animator") or h:FindFirstChild("Animator"))
	if not c or not animator then return end
	if punchVisual.character ~= c or #punchVisual.tracks == 0 then
		clearPunchVisual()
		punchVisual.character = c
		local shared = ReplicatedStorage:FindFirstChild("shared")
		local assets = shared and shared:FindFirstChild("assets")
		local anims = assets and assets:FindFirstChild("animations")
		local gameAnims = anims and anims:FindFirstChild("gameAnims")
		local tools = gameAnims and gameAnims:FindFirstChild("Tools")
		local punch = tools and tools:FindFirstChild("Punch")
		local attacks = punch and punch:FindFirstChild("attacks")
		if attacks then
			for _, a in pairs(attacks:GetChildren()) do
				if a:IsA("Animation") then
					local ok, track = pcall(animator.LoadAnimation, animator, a)
					if ok and track then
						track.Priority = Enum.AnimationPriority.Action
						table.insert(punchVisual.tracks, track)
					end
				end
			end
		end
	end
	if #punchVisual.tracks == 0 then return end
	for _, tr in pairs(punchVisual.tracks) do
		if tr.IsPlaying then pcall(function() tr:Stop(0.02) end) end
	end
	pcall(function() punchVisual.tracks[1]:Play(0.02, 1, 1.8) end)
end

-- Rocks (Fast Glitch)
local Rocks = {
	{label="Industrial Rock", durability=25000000},
	{label="Ancient Rock", durability=10000000},
	{label="Muscle King Rock", durability=5000000},
	{label="Legend Rock", durability=1000000},
	{label="Eternal Rock", durability=750000},
	{label="Mythical Rock", durability=400000},
	{label="Frost Rock", durability=150000},
	{label="Beach Rock", durability=5000},
	{label="Starter Rock", durability=100},
	{label="Tiny Rock", durability=0},
}
local selectedRock = nil
local function findRock(durability)
	local mf = Workspace:FindFirstChild("machinesFolder")
	if not mf then return nil end
	for _, d in ipairs(mf:GetDescendants()) do
		if d.Name == "neededDurability" and d:IsA("ValueBase") and tonumber(d.Value) == durability then
			local rock = d.Parent and d.Parent:FindFirstChild("Rock")
			if rock and rock:IsA("BasePart") then return rock end
		end
	end
	return nil
end

local function setFastPunch(on)
	fastPunchGen += 1
	local gen = fastPunchGen
	fastPunch = on
	if not fastPunch then
		clearPunchVisual()
		local c = LocalPlayer.Character
		local t = c and c:FindFirstChild("Punch")
		local at = t and t:FindFirstChild("attackTime")
		if at then at.Value = 0.3 end
		if t and LocalPlayer:FindFirstChild("Backpack") then t.Parent = LocalPlayer.Backpack end
		return
	end
	task.spawn(function()
		while fastPunch and fastPunchGen == gen do
			local t = getPunchTool()
			if t then
				local at = t:FindFirstChild("attackTime")
				if at and at.Value ~= 0 then at.Value = 0 end
				if t.Parent ~= LocalPlayer.Character then
					local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if h then pcall(function() h:EquipTool(t) end) end
				end
			end
			task.wait(0.05)
		end
	end)
	task.spawn(function()
		local lastActivate = 0
		while fastPunch and fastPunchGen == gen do
			local me = LocalPlayer:FindFirstChild("muscleEvent")
			local t = getPunchTool()
			if me and me:IsA("RemoteEvent") then
				pcall(function() me:FireServer("punch", "rightHand") end)
				pcall(function() me:FireServer("punch", "leftHand") end)
			end
			if t and time() - lastActivate >= 0.12 then
				lastActivate = time()
				pcall(function() t:Activate() end)
				playPunchVisual()
			end
			if selectedRock and type(firetouchinterest) == "function" then
				local c = LocalPlayer.Character
				local lh = c and c:FindFirstChild("LeftHand")
				local rh = c and c:FindFirstChild("RightHand")
				local rock = findRock(selectedRock)
				if rock and lh and rh then
					pcall(function() firetouchinterest(rock, rh, 0) end)
					pcall(function() firetouchinterest(rock, rh, 1) end)
					pcall(function() firetouchinterest(rock, lh, 0) end)
					pcall(function() firetouchinterest(rock, lh, 1) end)
				end
			end
			task.wait(0.01)
		end
	end)
end

MainTab:CreateToggle({
	Name = "Fast Punch",
	CurrentValue = false,
	Flag = "FastPunch",
	Callback = function(v)
		setFastPunch(v)
		Window:Notify({Title="La momoneta Hub", Content=v and "Fast Punch ON" or "Fast Punch OFF", Duration=2})
	end
})

MainTab:CreateDropdown({
	Name = "Roca (Fast Glitch)",
	Options = (function()
		local o = {"Ninguna"}
		for _, r in ipairs(Rocks) do table.insert(o, r.label) end
		return o
	end)(),
	CurrentOption = "Ninguna",
	Callback = function(o)
		selectedRock = nil
		for _, r in ipairs(Rocks) do
			if r.label == o then selectedRock = r.durability break end
		end
	end
})

local currentMapLabel = MainTab:CreateText({Name="Current: "..currentMap.Value})
currentMap.Changed:Connect(function() currentMapLabel:Set("Current: "..currentMap.Value) end)

-- ============ FAST REP (siempre dispara) ============
local fastRepOn = false
local savedRepTimes = {}
local function applyRepTimeZero()
	local mf = Workspace:FindFirstChild("machinesFolder")
	if mf then
		for _, v in pairs(mf:GetDescendants()) do
			if v.Name == "repTime" and v:IsA("NumberValue") then
				if savedRepTimes[v] == nil then savedRepTimes[v] = v.Value end
				if v.Value ~= 0 then
					pcall(function() v.Value = 0 end)
				end
			end
		end
	end
	for _, loc in pairs({LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character}) do
		if loc then
			for _, tool in pairs(loc:GetChildren()) do
				if tool:IsA("Tool") then
					local r = tool:FindFirstChild("repTime", true)
					if r and r:IsA("NumberValue") then
						if savedRepTimes[r] == nil then savedRepTimes[r] = r.Value end
						if r.Value ~= 0 then pcall(function() r.Value = 0 end) end
					end
				end
			end
		end
	end
end
local function restoreRepTimes()
	for inst, orig in pairs(savedRepTimes) do
		if inst and inst.Parent then pcall(function() inst.Value = orig end) end
	end
	table.clear(savedRepTimes)
end
FarmTab:CreateToggle({
	Name = "Fast Rep",
	CurrentValue = false,
	Flag = "FastRepZero",
	Callback = function(v)
		fastRepOn = v
		if v then
			task.spawn(function()
				local ticks = 0
				while fastRepOn do
					ticks += 1
					if ticks % 30 == 1 then applyRepTimeZero() end
					local c = LocalPlayer.Character
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if h and h.Health > 0 then
						local seat = getSeat(h)
						if seat then
							pcall(function() muscleEvent:FireServer("rep", seat) end)
						else
							pcall(function() muscleEvent:FireServer("rep") end)
						end
					end
					RunService.Heartbeat:Wait()
				end
			end)
		else
			restoreRepTimes()
		end
		Window:Notify({Title="La momoneta Hub", Content=v and "Fast Rep ON" or "Fast Rep OFF", Duration=2})
	end
})

-- ============ SUPER FAST REP ============
local superRepOn = false
local superRepBatch = 3
local superRepInterval = 0.02
FarmTab:CreateSlider({
	Name = "Super Rep Batch",
	Range = {1, 10},
	Increment = 1,
	CurrentValue = 3,
	Flag = "SuperRepBatch",
	Callback = function(v) superRepBatch = v end
})
FarmTab:CreateToggle({
	Name = "Super Fast Rep",
	CurrentValue = false,
	Flag = "SuperFastRep",
	Callback = function(v)
		superRepOn = v
		if v then
			task.spawn(function()
				while superRepOn do
					applyRepTimeZero()
					local c = LocalPlayer.Character
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if h and h.Health > 0 then
						local seat = getSeat(h)
						local hasX2 = LocalPlayer:FindFirstChild("ownedGamepasses") and LocalPlayer.ownedGamepasses:FindFirstChild("x2 Rep Time")
						local effective = superRepInterval
						if hasX2 then effective = effective * 0.5 end
						for i = 1, superRepBatch do
							if seat then
								pcall(function() muscleEvent:FireServer("rep", seat) end)
							else
								pcall(function() muscleEvent:FireServer("rep") end)
							end
						end
						task.wait(effective)
					else
						task.wait(0.2)
					end
				end
			end)
		else
			restoreRepTimes()
		end
		Window:Notify({Title="La momoneta Hub", Content=v and "Super Fast Rep ON" or "Super Fast Rep OFF", Duration=2})
	end
})

-- ============ MOTOR RAPIDO (rebirth + strength) ============
local LP = LocalPlayer
local Env = getgenv and getgenv() or _G
local StatsService = game:GetService("Stats")
local UltimateAttributes = {}
local State = {
	running = true,
	fastFarmMode = nil,
	autoWeight = false,
	hideFrames = false,
	rebirth = {},
	visualStatRecords = setmetatable({}, { __mode = "k" }),
}
State.setAutoEgg = function() return true end
local threads = {}
local threadGenerations = {}
local function stopThread(key)
	threadGenerations[key] = (threadGenerations[key] or 0) + 1
	local t = threads[key]
	if t then
		pcall(task.cancel, t)
		threads[key] = nil
	end
end
local function startThread(key, callback)
	stopThread(key)
	local generation = threadGenerations[key]
	local thread
	thread = task.defer(function()
		pcall(callback)
		if threadGenerations[key] == generation and threads[key] == thread then
			threads[key] = nil
		end
	end)
	threads[key] = thread
	return threads[key]
end
local function setHideFrames() end
local FastFarm = {
	RepToggles = {},
	MachineToggles = {},
	FullTrainToggles = {},
	MachineVisuals = {
		playIdle = function() end,
		playRep = function() end,
		stopAnimations = function() end,
	},
}
FastFarm.UpdateStrengthFramesControl = function() end
local protectBossRareOn = true
-- Cache de ProfileId de boss rare ya vistas: si el atributo BossRewardDisplayName
-- tarda en replicar o se pierde tras rebirth/respawn, seguimos protegiendo por id.
local knownBossRareIds = {}
local function isBossRara(pet)
	if not protectBossRareOn then return false end
	if not pet then return false end
	local okId, pid = pcall(function() return pet:GetAttribute("ProfileId") end)
	if okId and type(pid) == "string" and knownBossRareIds[pid] then return true end
	local ok, mark = pcall(function() return pet:GetAttribute("BossRewardDisplayName") end)
	if ok and mark ~= nil then
		if okId and type(pid) == "string" then knownBossRareIds[pid] = true end
		return true
	end
	if tostring(pet.Name or "") == "Rare Boss Pet" then
		if okId and type(pid) == "string" then knownBossRareIds[pid] = true end
		return true
	end
	return false
end
local function isProtegida(pet)
	return isBossRara(pet)
end
function FastFarm:ProtectedEquippedCount()
	local n = 0
	local eq = LP:FindFirstChild("equippedPets")
	if eq then
		for _, slot in ipairs(eq:GetChildren()) do
			local ref = slot:FindFirstChild("petReference")
			local pet = (ref and ref:IsA("ObjectValue") and ref.Value) or (slot:IsA("ObjectValue") and slot.Value) or nil
			if pet and pet:IsA("StringValue") and isProtegida(pet) then
				n = n + 1
			end
		end
	end
	return n
end
function FastFarm:FreePetSlots()
	return math.max(0, self:GetPetSlotCapacity() - self:ProtectedEquippedCount())
end

local CONFIG = {
FastFarm = {
		Packs = {
			chaos = {
				label = "Señores del Caos",
				strength = { "Swift Samurai" },
				rebirth = "Tribal Overlord",
			},
			ultra = {
				label = "Ultra Titanes",
				strength = { "Powercore Hound", "Omega Overlord" },
				rebirth = "Titanium Hydra",
			},
		},
		StrengthMachine = "Industrial Bench",
		RebirthMachine = "Industrial Bar Lift",
		MaxPets = 9,
		RepsPerCycle = 48,
		RepDelay = 0.008,
		PingSoft = 180,
		PingMedium = 300,
		PingHigh = 600,
		PingCritical = 700,
		PingPause = 880,
		PingResume = 450,
		PingReducerPause = 860,
		PingReducerResume = 480,
		PingSampleInterval = 0.12,
		StrengthPingSoft = 400,
		StrengthPingMedium = 560,
		StrengthPingHigh = 720,
		StrengthPingCritical = 840,
		StrengthMinBatch = 26,
		StrengthStartBatch = 42,
		StrengthMaxBatch = 42,
		StrengthBackoffPing = 700,
		StrengthBackoffInterval = 0.35,
		StrengthRampPing = 450,
		StrengthRampInterval = 0.9,
		StrengthDelay = 0.05,
		SizeInvokeInterval = 0.75,
		SizeReleaseDuration = 5,
		FramesReleaseDuration = 10,
		RebirthCooldown = 6.0,
		RebirthSafetyMargin = 0.03,
		RebirthRepBatch = 6,
		RebirthPingRise = 100,
		RebirthPingPause = 800,
		RebirthStrengthBufferRatio = 0.03,
		RebirthCycleDelay = 0.2,
		RebirthRetryDelay = 0.02,
		RebirthRequestWindow = 0.75,
		RateCycle = 6.03,
	},
}

local function getCharacter()
	return LP.Character
end


local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildWhichIsA("Humanoid")
end


local function getRoot()
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end


local function findValue(root, names)
	if not root then
		return nil
	end
	for _, name in ipairs(names) do
		local wanted = name:lower():gsub("%s+", "")
		for _, child in ipairs(root:GetChildren()) do
			local key = child.Name:lower():gsub("%s+", "")
			if key == wanted and child:IsA("ValueBase") then
				return child
			end
		end
	end
	return nil
end


local function getPlayerStat(player, names)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	return findValue(leaderstats, names) or findValue(player, names)
end


State.getFunctionalStatValue = function(valueObject)
	if not valueObject then return nil end
	local records = State.visualStatRecords
	local record = records and records[valueObject]
	if record and record.realValue ~= nil then return record.realValue end
	return valueObject.Value
end

State.protectedPetNameFallback = {
	["swift samurai"] = true,
	["tribal overlord"] = true,
}


State.hasEnabledPetMarker = function(pet, name)
	local marker = pet and pet:FindFirstChild(name)
	if not marker then return false end
	if marker:IsA("BoolValue") then return marker.Value == true end
	return true
end


State.isProtectedPetAsset = function(pet)
	if not pet or not pet.Parent or not pet:IsA("StringValue") then return true end
	if State.protectedPetNameFallback[pet.Name:lower()] then return true end
	local categoryName = pet.Parent and pet.Parent.Name:lower() or ""
	if categoryName:find("robux", 1, true) or categoryName:find("pack", 1, true) then return true end
	local shared = ReplicatedStorage:FindFirstChild("shared")
	local runtime = shared and shared:FindFirstChild("runtime")
	local packCatalog = runtime and runtime:FindFirstChild("packPetPerks")
	if packCatalog and packCatalog:FindFirstChild(pet.Name) then return true end
	for _, marker in ipairs({ "packPet", "unsellable", "untradeable", "locked", "protected" }) do
		if State.hasEnabledPetMarker(pet, marker) then return true end
	end
	for _, attribute in ipairs({ "PackPet", "RobuxPet", "Unsellable", "Untradeable", "Locked", "Protected" }) do
		if pet:GetAttribute(attribute) == true then return true end
	end
	return false
end


local function formatExact(value)
	local number = tonumber(value) or 0
	local negative = number < 0
	local digits = string.format("%.0f", math.abs(number))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
	return (negative and "-" or "") .. grouped
end


State.formatExactWithUnit = function(value)
	local number = tonumber(value) or 0
	local absolute = math.abs(number)
	local units = {
		{ 1e33, "DC" }, { 1e30, "NO" }, { 1e27, "OC" }, { 1e24, "SP" },
		{ 1e21, "SX" }, { 1e18, "QI" }, { 1e15, "QA" }, { 1e12, "T" },
		{ 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" },
	}
	for _, unit in ipairs(units) do
		if absolute >= unit[1] then
			local compact = string.format("%.1f", number / unit[1])
			compact = compact:gsub("%.0$", "")
			return compact .. unit[2]
		end
	end
	return formatExact(number)
end


local function getPing()
	local ok, value = pcall(function()
		return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	return ok and math.floor((tonumber(value) or 0) + 0.5) or 0
end


State.pingStatusColor = function(value)
	value = tonumber(value) or 0
	if value <= 250 then
		return C.green
	end
	if value < 800 then
		return C.yellow
	end
	return C.red
end


local function realNow()
	local ok, value = pcall(workspace.GetServerTimeNow, workspace)
	if ok and type(value) == "number" then
		return value
	end
	return os.clock()
end


local function copyText(value)
	local environment = getgenv and getgenv() or _G
	local clipboard = environment.setclipboard or environment.toclipboard or environment.writeclipboard
	if type(clipboard) == "function" then
		pcall(clipboard, tostring(value))
		return true
	end
	return false
end


local function equipTool(names)
	local character = getCharacter()
	local humanoid = getHumanoid()
	if not character or not humanoid then
		return nil
	end
	local wanted = {}
	for _, name in ipairs(names) do
		wanted[name:lower()] = true
	end
	for _, container in ipairs({ character, LP:FindFirstChild("Backpack") }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and wanted[child.Name:lower()] then
					if child.Parent ~= character then
						humanoid:EquipTool(child)
					end
					return child
				end
			end
		end
	end
	return nil
end

local machineFunctions = nil

local function machineIsActive(machine, seat, humanoid)
	if not machine or not seat then
		return false
	end
	if humanoid and humanoid.SeatPart == seat then
		return true
	end
	local machineInUse = LP:FindFirstChild("machineInUse")
	if machineInUse and machineInUse.Value == seat then
		return true
	end
	if tonumber(machine:GetAttribute("InUseUserId")) == LP.UserId then
		return true
	end
	local character = getCharacter()
	local standingMount = character and character:GetAttribute("MachineStandingMount") == true
	local scaleFrozen = character and character:GetAttribute("MachineScaleFrozen") == true
	return (standingMount or scaleFrozen)
		and FastFarm.acceptedMachine == machine
		and FastFarm.acceptedMachineSeat == seat
end


local function getMachineParts(definition)
	local folder = workspace:FindFirstChild("machinesFolder")
	if not folder or type(definition) ~= "table" then
		return nil, nil
	end

	local bestMachine, bestSeat, bestGain, bestRequirement, bestDistance = nil, nil, -math.huge, -1, math.huge
	local currentHumanoid = getHumanoid()
	local root = getRoot()
	local referencePosition = root and root.Position or (definition.fallback and definition.fallback.Position)
	local expectedPosition = definition.fallback and definition.fallback.Position
	local candidates = definition.instance and { definition.instance } or folder:GetChildren()
	for _, candidate in ipairs(candidates) do
		if candidate:IsA("Model") and candidate.Name == definition.object then
			local seat = candidate.PrimaryPart
			if not (seat and seat:IsA("Seat")) then
				seat = candidate:FindFirstChild("interactSeat", true)
			end
			local expectedDistance = seat and expectedPosition
				and (Vector3.new(seat.Position.X, 0, seat.Position.Z)
					- Vector3.new(expectedPosition.X, 0, expectedPosition.Z)).Magnitude or 0
			local candidateGain = candidate:FindFirstChild("strengthGain")
			local gainMatches = definition.strengthGain == nil
				or (candidateGain and tonumber(candidateGain.Value) == tonumber(definition.strengthGain))
			if seat and seat:IsA("Seat") and expectedDistance <= 1400 and gainMatches then
				if machineIsActive(candidate, seat, currentHumanoid) then
					return candidate, seat
				end
				local inUseUserId = tonumber(candidate:GetAttribute("InUseUserId"))
				local available = (seat.Occupant == nil or seat.Occupant == currentHumanoid)
					and (inUseUserId == nil or inUseUserId == LP.UserId)
				local requirement = 0
				local requirements = candidate:FindFirstChild("requirements")
				if available and requirements then
					for _, value in ipairs(requirements:GetChildren()) do
						if value:IsA("ValueBase") then
							local playerValue = getPlayerStat(LP, { value.Name })
							local needed = tonumber(value.Value) or 0
							if not playerValue or (tonumber(State.getFunctionalStatValue(playerValue)) or 0) < needed then
								available = false
								break
							end
							requirement = math.max(requirement, needed)
						end
					end
				end
				if available then
					local strengthGain = tonumber(candidateGain and candidateGain.Value) or 0
					local distance = referencePosition and (seat.Position - referencePosition).Magnitude or 0
					if strengthGain > bestGain
						or (strengthGain == bestGain and requirement > bestRequirement)
						or (strengthGain == bestGain and requirement == bestRequirement and distance < bestDistance) then
						bestMachine, bestSeat = candidate, seat
						bestGain, bestRequirement, bestDistance = strengthGain, requirement, distance
					end
				end
			end
		end
	end
	return bestMachine, bestSeat
end


local function machineTargetCFrame(machine, seat, fallback, humanoid, root)
	if seat and seat:IsA("BasePart") then
		local rootHalf = root and root.Size.Y * 0.5 or 1
		local seatHalf = seat.Size.Y * 0.5
		local hipAllowance = humanoid and math.max(0.15, humanoid.HipHeight * 0.12) or 0.25
		local lift = math.clamp(rootHalf + seatHalf + hipAllowance, 1.8, 3.3)
		return seat.CFrame * CFrame.new(0, lift, 0)
	end
	if machine then
		local ok, pivot = pcall(machine.GetPivot, machine)
		if ok then return pivot end
	end
	return fallback
end


FastFarm.SafeMachineLockCFrame = function(character, frame)
	local expectedY = character and tonumber(character:GetAttribute("MachineStandHrpY"))
	if frame and expectedY and frame.Position.Y < expectedY - 0.15 then
		frame = frame + Vector3.new(0, expectedY - frame.Position.Y, 0)
	end
	return frame
end


local function machineRepDelay(machine)
	local repTime = machine and machine:FindFirstChild("repTime", true)
	local attributeRepTime = machine and machine:GetAttribute("repTime")
	local delay = math.max(0.15, tonumber(attributeRepTime) or tonumber(repTime and repTime.Value) or 1)
	local owned = LP:FindFirstChild("ownedGamepasses")
	if owned and owned:FindFirstChild("x2 Rep Time") then
		delay = delay * 0.5
	end
	if not machineFunctions then
		pcall(function()
			local shared = ReplicatedStorage:FindFirstChild("shared")
			local modules = shared and shared:FindFirstChild("modules")
			local module = (modules and modules:FindFirstChild("GlobalFunctions"))
				or ReplicatedStorage:FindFirstChild("globalFunctions")
			if module and module:IsA("ModuleScript") then
				machineFunctions = require(module)
			end
		end)
	end
	if machineFunctions then
		local okUltimate, ultimate = pcall(machineFunctions.calculateUltimateRepTime, LP)
		if okUltimate then
			delay = delay * (1 - math.clamp(tonumber(ultimate) or 0, 0, 0.9))
		end
		local okPet, petBoost = pcall(machineFunctions.calculatePetRepTimeBoost, LP)
		if okPet then
			delay = delay * (1 - math.clamp(tonumber(petBoost) or 0, 0, 0.9))
		end
	end
	return math.max(0.12, delay + 0.025)
end


local function useMachine(definition, maximumAttempts, retryDelay)
	local root = getRoot()
	local humanoid = getHumanoid()
	if not root or not humanoid then return false end
	local machine, seat = getMachineParts(definition)
	if not machine or not seat or not seat:IsA("Seat") then
		return false
	end
	if machineIsActive(machine, seat, humanoid) then
		return true, machine, seat
	end
	local remote = ReplicatedStorage:FindFirstChild("rEvents")
		and ReplicatedStorage.rEvents:FindFirstChild("machineInteractRemote")
	if not remote or not remote:IsA("RemoteFunction") then
		return false
	end
	local attempts = math.max(1, tonumber(maximumAttempts) or 4)
	for attempt = 1, attempts do
		repeat
		if machineIsActive(machine, seat, humanoid) then
			return true, machine, seat
		end
		local targetCFrame = machineTargetCFrame(machine, seat, definition.fallback, humanoid, root)
		if not targetCFrame then return false end
		if seat.Occupant and seat.Occupant ~= humanoid then
			return false, machine, seat, "occupied"
		end
		root.Anchored = false
		local character = LP.Character
		if character then
			pcall(character.PivotTo, character, targetCFrame)
		end
		root.CFrame = targetCFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		RunService.Heartbeat:Wait()
		task.wait(FastFarm.mode == "strength" and 0.02 or (attempt == 1 and 0.1 or 0.06))
		local invoked, accepted, rejectionReason = pcall(remote.InvokeServer, remote, "useMachine", seat)
		if FastFarm.mode == "rebirth" and FastFarm.currentCycle then
			local cycle = FastFarm.currentCycle
			cycle.machineAttempts = cycle.machineAttempts or {}
			if #cycle.machineAttempts < 20 then
				cycle.machineAttempts[#cycle.machineAttempts + 1] = {
					machine = machine.Name, accepted = invoked and accepted == true,
					reason = tostring(rejectionReason), at = os.clock() - cycle.startedAt,
				}
			end
		end
		if invoked and accepted == true then
			FastFarm.acceptedMachine = machine
			FastFarm.acceptedMachineSeat = seat
		elseif invoked and accepted == false then
			if attempt < attempts then
				local retryWait = tonumber(retryDelay) or 0.22
				task.wait(retryWait)
				break
			else
				return false, machine, seat, rejectionReason
			end
		elseif not invoked then
			return false, machine, seat, "invokeFailed"
		end
		local entryWait = FastFarm.MachineEntryWait or 2.3
		if FastFarm.mode == "strength" then
			entryWait = math.clamp(0.35 + math.max(0, getPing()) * 0.0015, 0.55, 1.4)
		end
		local deadline = time() + entryWait
		repeat
			if machineIsActive(machine, seat, humanoid) then
				return true, machine, seat
			end
			RunService.Heartbeat:Wait()
		until time() >= deadline
		machine, seat = getMachineParts(definition)
		if not machine or not seat then
			return false
		end
		until true
	end
	return machineIsActive(machine, seat, humanoid), machine, seat
end


local function leaveMachine()
	FastFarm.MachineVisuals.stopAnimations(0.1)
	FastFarm.acceptedMachine = nil
	FastFarm.acceptedMachineSeat = nil
	local remote = ReplicatedStorage:FindFirstChild("rEvents")
		and ReplicatedStorage.rEvents:FindFirstChild("machineInteractRemote")
	if remote and remote:IsA("RemoteFunction") then
		if State.shuttingDown then
			task.spawn(function()
				pcall(remote.InvokeServer, remote, "leaveMachine")
			end)
		else
			pcall(remote.InvokeServer, remote, "leaveMachine")
		end
	end
	local humanoid = getHumanoid()
	if humanoid and humanoid.SeatPart then
		humanoid.Sit = false
	end
end

do
FastFarm.generation = 0
	FastFarm.warningAccepted = false
	FastFarm.mode = nil
	FastFarm.startedAt = nil
	FastFarm.sessionStartedAt = nil
	FastFarm.startStats = nil
	FastFarm.lockCFrame = nil
	FastFarm.lockCharacter = nil
	FastFarm.machine = nil
	FastFarm.machineSeat = nil
	FastFarm.machineDefinition = nil
	FastFarm.machineFailureCooldowns = {}
	FastFarm.lastMachineSelection = nil
	FastFarm.hideFramesOwned = false
	FastFarm.packCount = 0
	FastFarm.petSlotCapacity = 1
	FastFarm.requiredPackCount = 1
	FastFarm.strengthPack = nil
	FastFarm.strengthPackCount = 0
	FastFarm.strengthPackRepBoost = 0
	FastFarm.rebirthPack = nil
	FastFarm.rebirthPackCount = 0
	FastFarm.expectedRebirthDelta = 0
	FastFarm.cycleStrengthGain = 0
	FastFarm.lastTargetStrength = 0
	FastFarm.cycleCount = 0
	FastFarm.successfulRebirths = 0
	FastFarm.failedRebirths = 0
	FastFarm.validRebirthSamples = {}
	FastFarm.validStrengthSamples = {}
	FastFarm.lastSuccessfulRebirthAt = nil
	FastFarm.rebirthMeasurementStartedAt = nil
	FastFarm.nextRebirthRequestAt = nil
	FastFarm.lastStrengthSampleAt = nil
	FastFarm.lastStrengthSampleValue = nil
	FastFarm.lastRequiredStrength = 0
	FastFarm.lastRebirthAccepted = false
	FastFarm.lastError = nil
	FastFarm.cachedPing = 0
	FastFarm.pingCheckedAt = 0
	FastFarm.pingPaused = false
	FastFarm.resumeSamples = 0
	FastFarm.strengthBatch = CONFIG.FastFarm.StrengthStartBatch
	FastFarm.lastBatchAdjust = 0
	FastFarm.pingReducer = false
	FastFarm.sizeInvokeBusy = false
	FastFarm.lastSizeInvoke = 0
	FastFarm.sizeReleaseGeneration = 0
	FastFarm.frameReleaseGeneration = 0
	FastFarm.bootstrapAutoWeight = false
	FastFarm.nextMachineAcquireAt = 0


	function FastFarm:SetPingReducer(enabled)
		self.pingReducer = enabled == true
		self.resumeSamples = 0
		if self.pingReducer then
			self.strengthBatch = math.min(
				self.strengthBatch or CONFIG.FastFarm.StrengthStartBatch,
				CONFIG.FastFarm.StrengthStartBatch
			)
		end
		return self.pingReducer
	end


	local function readStat(names)
		local value = getPlayerStat(LP, names)
		return value and tonumber(State.getFunctionalStatValue(value)) or 0, value
	end


	local function readStats()
		local rebirths = readStat({ "Rebirths", "Rebirth" })
		local strength = readStat({ "Strength", "Fuerza" })
		local durability = readStat({ "Durability", "Resistencia" })
		return {
			rebirths = rebirths,
			strength = strength,
			durability = durability,
		}
	end


	local function farmEvents()
		return ReplicatedStorage:FindFirstChild("rEvents")
	end


	local function unequipAllPets()
		local events = farmEvents()
		local remote = events and events:FindFirstChild("equipPetEvent")
		local equippedPets = LP:FindFirstChild("equippedPets")
		if not remote or not equippedPets then
			return false
		end
		for _, slot in ipairs(equippedPets:GetChildren()) do
			local reference = (slot:FindFirstChild("petReference") or slot)
			local pet = reference and reference:IsA("ObjectValue") and reference.Value
			if pet then
				pcall(function() if not isProtegida(pet) then remote:FireServer("unequipPet", pet) end end)
			end
		end
		RunService.Heartbeat:Wait()
		local deadline = time() + 1.2
		repeat
			local remaining = 0
			for _, slot in ipairs(equippedPets:GetChildren()) do
				local reference = (slot:FindFirstChild("petReference") or slot)
				local pet = reference and reference:IsA("ObjectValue") and reference.Value or nil
				-- Las boss rare protegidas DEBEN quedarse equipadas: no cuentan como "remaining"
				if pet and not isProtegida(pet) then
					remaining = remaining + 1
				end
			end
			if remaining == 0 then return true end
			task.wait(0.04)
		until time() >= deadline
		return false
	end


	function FastFarm:GetPetSlotCapacity()
		local capacity = 2
		if LP.MembershipType == Enum.MembershipType.Premium then
			capacity = capacity + 1
		end
		local ownedGamepasses = LP:FindFirstChild("ownedGamepasses")
		if ownedGamepasses and ownedGamepasses:FindFirstChild("+2 Pet Slots") then
			capacity = capacity + 2
		end
		local petSlotAttribute = UltimateAttributes["+1 Pet Slot"] or "UltimatePetSlot"
		local ultimateSlots = LP:GetAttribute(petSlotAttribute)
		if typeof(ultimateSlots) == "number" then
			capacity = capacity + math.max(0, math.floor(ultimateSlots))
		end
		local industrialSlot = LP:GetAttribute("IndustrialPetSlot")
		if industrialSlot == true or industrialSlot == 1 then
			capacity = capacity + 1
		end
		local availableSlotObjects = 0
		local equippedPets = LP:FindFirstChild("equippedPets")
		if equippedPets then
			for _, slot in ipairs(equippedPets:GetChildren()) do
				if slot:IsA("ObjectValue") then
					availableSlotObjects = availableSlotObjects + 1
				end
			end
		end
		if availableSlotObjects > 0 then
			capacity = math.min(capacity, availableSlotObjects)
		end
		self.petSlotCapacity = math.clamp(capacity, 1, CONFIG.FastFarm.MaxPets)
		return self.petSlotCapacity
	end


	function FastFarm:CountOwnedPet(name)
		local count = 0
		local petsFolder = LP:FindFirstChild("petsFolder")
		if petsFolder then
			for _, folder in ipairs(petsFolder:GetChildren()) do
				if folder:IsA("Folder") then
					for _, pet in ipairs(folder:GetChildren()) do
						if pet:IsA("StringValue") and pet.Name == name then
							count = count + 1
						end
					end
				end
			end
		end
		return count
	end


	function FastFarm:GetPackCatalog(force)
		if not force and self.packCatalog and time() - (self.packCatalogAt or 0) < 30 then return self.packCatalog end
		local shared = ReplicatedStorage:FindFirstChild("shared")
		local runtime = shared and shared:FindFirstChild("runtime")
		local catalog = runtime and runtime:FindFirstChild("packPetPerks")
		local modules = shared and shared:FindFirstChild("modules")
		local module = modules and modules:FindFirstChild("GlobalFunctions")
		local ok, functions = pcall(function() return module and require(module) end)
		if not catalog or not ok or type(functions) ~= "table" then return self.packCatalog or {} end
		local result, owned = {}, {}
		local inventory = LP:FindFirstChild("petsFolder")
		for _, folder in ipairs(inventory and inventory:GetChildren() or {}) do
			for _, pet in ipairs(folder:GetChildren()) do
				if pet:IsA("StringValue") then owned[pet.Name] = (owned[pet.Name] or 0) + 1 end
			end
		end
		local sample = Instance.new("Folder")
		local equipped = Instance.new("Folder")
		equipped.Name, equipped.Parent = "equippedPets", sample
		local slot = Instance.new("ObjectValue")
		slot.Parent = equipped
		local reference = Instance.new("ObjectValue")
		reference.Name, reference.Parent = "petReference", slot
		for _, item in ipairs(catalog:GetChildren()) do
			local perks = item:FindFirstChild("perksFolder")
			local strength = perks and perks:FindFirstChild("strength")
			local entry = { name = item.Name, owned = owned[item.Name] or 0, ref = item,
				strength = strength and tonumber(strength.Value) or 0 }
			slot.Value, reference.Value = item, item
			for key, method in pairs({ repSpeed = "calculatePetRepTimeBoost",
				strengthBonus = "calculatePetStrengthGainMultiplier", rebirthBonus = "calculatePetRebirthGainMultiplier" }) do
				if type(functions[method]) == "function" then
					local calculated, value = pcall(functions[method], sample)
					if calculated and type(value) == "number" then entry[key] = value end
				end
			end
			result[#result + 1] = entry
		end
		sample:Destroy()
		table.sort(result, function(a, b) return a.name < b.name end)
		self.packCatalog, self.packCatalogAt = result, time()
		return result
	end


	function FastFarm:GetModes(force)
		local cap = self:GetPetSlotCapacity()
		local byName = {}
		for _, pet in ipairs(self:GetPackCatalog(force)) do byName[pet.name] = pet end
		local out = {}
		for key, pack in pairs(CONFIG.FastFarm.Packs) do
			local strength = 0
			for _, name in ipairs(pack.strength) do
				strength = strength + math.min(cap, tonumber(byName[name] and byName[name].owned) or 0)
			end
			local rebirth = math.min(cap, tonumber(byName[pack.rebirth] and byName[pack.rebirth].owned) or 0)
			out[key] = { key = key, label = pack.label, available = strength > 0 and rebirth > 0,
				strength = strength, rebirth = rebirth, pets = byName }
		end
		self.packModes = out
		return out
	end


	function FastFarm:LoadPack(force)
		local modes = self:GetModes(force)
		local mode = modes[self.packMode]
		if not mode or not mode.available then
			for _, fallbackMode in ipairs({ "chaos", "ultra" }) do
				if modes[fallbackMode] and modes[fallbackMode].available then
					self.packMode = fallbackMode
					mode = modes[fallbackMode]
					break
				end
			end
		end
		if not mode or not mode.available then
			self.strengthPack, self.rebirthPack = nil, nil
			self.strengthSetup, self.rebirthSetup = nil, nil
			self.strengthPackCount, self.rebirthPackCount = 0, 0
			self.strengthPackRepBoost, self.expectedRebirthDelta = 0, 0
			return false, false
		end
		local cap = self:GetPetSlotCapacity()
		local pack = CONFIG.FastFarm.Packs[self.packMode]
		local s = {}
		if self.packMode == "ultra" then
			local hound, omega = mode.pets[pack.strength[1]], mode.pets[pack.strength[2]]
			local hMax = math.min(cap, tonumber(hound and hound.owned) or 0)
			local oMax = math.min(cap, tonumber(omega and omega.owned) or 0)
			local bestH, bestO, bestScore, bestUsed = 0, 0, -1, 0
			for h = 0, hMax do
				for o = 0, math.min(oMax, cap - h) do
					local used = h + o
					if used > 0 then
						local base = h * (tonumber(hound.strength) or 0) + o * (tonumber(omega.strength) or 0)
						local bonus = h * (tonumber(hound.strengthBonus) or 0)
							+ o * (tonumber(omega.strengthBonus) or 0)
						local speed = h * (tonumber(hound.repSpeed) or 0) + o * (tonumber(omega.repSpeed) or 0)
						local score = base * (1 + bonus) / math.max(0.10, 1 - math.min(0.90, speed))
						if score > bestScore or (score == bestScore and used > bestUsed) then
							bestH, bestO, bestScore, bestUsed = h, o, score, used
						end
					end
				end
			end
			if bestH > 0 then s[#s + 1] = { name = hound.name, count = bestH, data = hound } end
			if bestO > 0 then s[#s + 1] = { name = omega.name, count = bestO, data = omega } end
		else
			local pet = mode.pets[pack.strength[1]]
			local count = math.min(cap, tonumber(pet and pet.owned) or 0)
			if count > 0 then s[1] = { name = pet.name, count = count, data = pet } end
		end
		local rPet = mode.pets[pack.rebirth]
		local rCount = math.min(cap, tonumber(rPet and rPet.owned) or 0)
		local r = rCount > 0 and { { name = rPet.name, count = rCount, data = rPet } } or {}
		local sCount, rep = 0, 0
		for _, part in ipairs(s) do
			sCount = sCount + part.count
			rep = rep + (tonumber(part.data.repSpeed) or 0) * part.count
		end
if sCount == 0 then
			local pool = {}
			local inv = LP:FindFirstChild('petsFolder')
			if inv then
				for _, cat in ipairs(inv:GetChildren()) do
					if cat:IsA('Folder') then
						for _, pet in ipairs(cat:GetChildren()) do
							if pet:IsA('StringValue') and not isProtegida(pet) then
								local perks = pet:FindFirstChild('perksFolder')
								local st = perks and perks:FindFirstChild('strength')
								local score = tonumber(st and st.Value) or 0
								if score > 0 then pool[#pool + 1] = { pet = pet, name = pet.Name, score = score } end
							end
						end
					end
				end
			end
			table.sort(pool, function(a, b) return a.score > b.score end)
			local groups, order = {}, {}
			for i = 1, math.min(cap, #pool) do
				local p = pool[i]
				if not groups[p.name] then groups[p.name] = { name = p.name, count = 0 } order[#order + 1] = groups[p.name] end
				groups[p.name].count = groups[p.name].count + 1
			end
			s = order
			for _, part in ipairs(s) do
				sCount = sCount + part.count
			end
		end
		self.strengthSetup, self.rebirthSetup = s, r
		self.strengthPack, self.rebirthPack = "s:" .. self.packMode, "r:" .. self.packMode
		self.strengthPackCount, self.rebirthPackCount = sCount, rCount
		self.strengthPackRepBoost = rep
		self.expectedRebirthDelta = math.max(1,
			math.floor((tonumber(rPet.rebirthBonus) or 0) * rCount + 0.5))
		return sCount > 0, rCount > 0
	end


	local function equipPetByName(name, requestedCount)
		local events = farmEvents()
		local remote = events and events:FindFirstChild("equipPetEvent")
		local petsFolder = LP:FindFirstChild("petsFolder")
		if not remote or not petsFolder then
			return 0
		end
		local pets = {}
		for _, folder in ipairs(petsFolder:GetChildren()) do
			if folder:IsA("Folder") then
				for _, pet in ipairs(folder:GetChildren()) do
					if pet.Name == name then
						pets[#pets + 1] = pet
					end
				end
			end
		end
		table.sort(pets, function(a, b)
			local momentumA = tonumber(a:GetAttribute("MomentumSeconds")) or 0
			local momentumB = tonumber(b:GetAttribute("MomentumSeconds")) or 0
			if momentumA ~= momentumB then
				return momentumA > momentumB
			end
			return a:GetFullName() < b:GetFullName()
		end)
		local target = math.min(requestedCount or FastFarm:GetPetSlotCapacity(), FastFarm:GetPetSlotCapacity(), #pets)
		-- Nunca exceder los slots libres (capacidad - boss rare protegidas).
		-- Sin esto el servidor saca pets solas al superar el limite y parece que
		-- "se desequipa en unos minutos".
		target = math.min(target, math.max(1, FastFarm:FreePetSlots()))
		FastFarm.requiredPackCount = math.max(1, target)
		if target < 1 then
			FastFarm.lastError = "No se encontró el pack " .. tostring(name)
			return 0
		end
		for index = 1, target do
			pcall(remote.FireServer, remote, "equipPet", pets[index])
		end
		RunService.Heartbeat:Wait()
		local equippedPets = LP:FindFirstChild("equippedPets")
		local deadline = time() + 1.4
		repeat
			local confirmed = 0
			if equippedPets then
				for _, slot in ipairs(equippedPets:GetChildren()) do
					local reference = (slot:FindFirstChild("petReference") or slot)
					local pet = reference and reference:IsA("ObjectValue") and reference.Value
					if pet and pet.Name == name then confirmed = confirmed + 1 end
				end
			end
			if confirmed >= target then
				FastFarm.lastError = nil
				return confirmed
			end
			task.wait(0.04)
		until time() >= deadline
		FastFarm.lastError = "No se confirmó el equipamiento de " .. tostring(name)
		return 0
	end


	local function switchPetPack(name, requestedCount)
		local generation = FastFarm.generation
		local events = farmEvents()
		local remote = events and events:FindFirstChild("equipPetEvent")
		local petsFolder = LP:FindFirstChild("petsFolder")
		local equippedPets = LP:FindFirstChild("equippedPets")
		if not remote or not petsFolder or not equippedPets then
			return 0
		end

		local targets = {}
		FastFarm.packCache = FastFarm.packCache or {}
		local cached = FastFarm.packCache[name]
		local validCache = cached and time() - cached.at < 30
		if validCache then
			for _, pet in ipairs(cached.pets) do
				if not pet:IsDescendantOf(petsFolder) or pet.Name ~= name then validCache = false; break end
			end
		end
		if validCache then targets = cached.pets else
		for _, folder in ipairs(petsFolder:GetChildren()) do
			if folder:IsA("Folder") then
				for _, pet in ipairs(folder:GetChildren()) do
					if pet.Name == name then targets[#targets + 1] = pet end
				end
			end
		end
		FastFarm.packCache[name] = { at = time(), pets = targets }
		end
		table.sort(targets, function(a, b)
			local momentumA = tonumber(a:GetAttribute("MomentumSeconds")) or 0
			local momentumB = tonumber(b:GetAttribute("MomentumSeconds")) or 0
			if momentumA ~= momentumB then return momentumA > momentumB end
			return a:GetFullName() < b:GetFullName()
		end)
		local target = math.min(requestedCount or FastFarm:GetPetSlotCapacity(), FastFarm:GetPetSlotCapacity(), #targets)
		target = math.min(target, math.max(1, FastFarm:FreePetSlots()))
		FastFarm.requiredPackCount = math.max(1, target)
		if target < 1 or #targets < target or FastFarm:GetPetSlotCapacity() < target then
			FastFarm.lastError = "No se encontró el pack " .. tostring(name)
			return 0
		end
		local selected = {}
		for index = 1, target do selected[targets[index]] = true end

		local function confirmedReferences()
			local found, occupied, seen = 0, 0, {}
			for _, slot in ipairs(equippedPets:GetChildren()) do
				local reference = (slot:FindFirstChild("petReference") or slot)
				local pet = reference and reference:IsA("ObjectValue") and reference.Value
				if pet then
					if not isProtegida(pet) then occupied = occupied + 1 end
					if slot:IsA("ObjectValue") and slot.Value and selected[pet]
						and pet.Parent and not seen[pet] then
						seen[pet] = true
						found = found + 1
					end
				end
			end
			return found == target and occupied == target
		end

		local matching = 0
		local occupied = 0
		for _, slot in ipairs(equippedPets:GetChildren()) do
			local reference = (slot:FindFirstChild("petReference") or slot)
			local pet = reference and reference:IsA("ObjectValue") and reference.Value
			if pet then
				if not isProtegida(pet) then occupied = occupied + 1 end
				if pet.Name == name then matching = matching + 1 end
			end
		end
		if matching == target and occupied == target and confirmedReferences() then
			FastFarm.confirmedPack = { name = name, references = selected, count = target }
			FastFarm.lastError = nil
			return matching
		end
		local network = FastFarm:GetRebirthNetwork()
		while os.clock() < (network.petNextSendAt or 0) do
			if not State.running or FastFarm.generation ~= generation then return 0 end
			task.wait(0.05)
		end
		if confirmedReferences() then
			FastFarm.confirmedPack = { name = name, references = selected, count = target }
			return target
		end
		network.petNextSendAt = os.clock() + math.max(0.4, (FastFarm.cachedPing or 0) / 500)

		for _, slot in ipairs(equippedPets:GetChildren()) do
			local reference = (slot:FindFirstChild("petReference") or slot)
			local pet = reference and reference:IsA("ObjectValue") and reference.Value
			if pet then pcall(function() if not isProtegida(pet) then remote:FireServer("unequipPet", pet) end end) end
		end
		for index = 1, target do
			pcall(remote.FireServer, remote, "equipPet", targets[index])
		end

		local deadline = time() + math.max(1.4, (FastFarm.cachedPing or 0) / 1000 * 4)
		repeat
			if not State.running or FastFarm.generation ~= generation then return 0 end
			local confirmed = 0
			for _, slot in ipairs(equippedPets:GetChildren()) do
				local reference = (slot:FindFirstChild("petReference") or slot)
				local pet = reference and reference:IsA("ObjectValue") and reference.Value
				if pet and pet.Name == name then confirmed = confirmed + 1 end
			end
			if confirmed >= target and confirmedReferences() then
				FastFarm.confirmedPack = { name = name, references = selected, count = target }
				FastFarm.lastError = nil
				return confirmed
			end
			RunService.Heartbeat:Wait()
		until time() >= deadline
		FastFarm.lastError = "No se confirmó el equipamiento de " .. tostring(name)
		return 0
	end
	FastFarm.UnequipAllPets = unequipAllPets
	FastFarm.EquipPack = equipPetByName
	FastFarm.SwitchPack = switchPetPack


	local function equipSetup(setup, key)
		if type(setup) ~= "table" or #setup < 1 then return 0 end
		if #setup == 1 and not setup[1].pets then
			local count = switchPetPack(setup[1].name, setup[1].count)
			if count > 0 and FastFarm.confirmedPack then FastFarm.confirmedPack.name = key end
			return count
		end
		local generation = FastFarm.generation
		local events = farmEvents()
		local remote = events and events:FindFirstChild("equipPetEvent")
		local pets = LP:FindFirstChild("petsFolder")
		local equipped = LP:FindFirstChild("equippedPets")
		if not remote or not pets or not equipped then return 0 end
		local targets = {}
		for _, part in ipairs(setup) do
			local found = {}
			if part.pets then
				for _,pet in ipairs(part.pets) do if pet.Parent and pet.Name==part.name then found[#found+1]=pet end end
			else
			for _, folder in ipairs(pets:GetChildren()) do
				for _, pet in ipairs(folder:IsA("Folder") and folder:GetChildren() or {}) do
					if pet.Name == part.name then found[#found + 1] = pet end
				end
			end
			table.sort(found, function(a, b)
				local am = tonumber(a:GetAttribute("MomentumSeconds")) or 0
				local bm = tonumber(b:GetAttribute("MomentumSeconds")) or 0
				return am ~= bm and am > bm or (am == bm and a:GetFullName() < b:GetFullName())
			end)
			end
			if #found < part.count then return 0 end
			for i = 1, part.count do targets[#targets + 1] = found[i] end
		end
		if #targets < 1 or #targets > FastFarm:GetPetSlotCapacity() then return 0 end
		local freeSlots = FastFarm:FreePetSlots()
		while #targets > freeSlots and #targets > 1 do table.remove(targets, 1) end
		local selected = {}
		for _, pet in ipairs(targets) do selected[pet] = true end

		local function ready()
			local count, used, seen = 0, 0, {}
			for _, slot in ipairs(equipped:GetChildren()) do
				local ref = (slot:FindFirstChild("petReference") or slot)
				local pet = ref and ref:IsA("ObjectValue") and ref.Value
				if pet then
					if not isProtegida(pet) then used = used + 1 end
					if slot:IsA("ObjectValue") and slot.Value and selected[pet] and pet.Parent and not seen[pet] then
						seen[pet], count = true, count + 1
					end
				end
			end
			return count == #targets and used == count
		end
		if not ready() then
			local net = FastFarm:GetRebirthNetwork()
			while os.clock() < (net.petNextSendAt or 0) do
				if not State.running or FastFarm.generation ~= generation then return 0 end
				task.wait(0.04)
			end
			net.petNextSendAt = os.clock() + math.max(0.4, (FastFarm.cachedPing or 0) / 500)
			for _, slot in ipairs(equipped:GetChildren()) do
				local ref = (slot:FindFirstChild("petReference") or slot)
				local pet = ref and ref:IsA("ObjectValue") and ref.Value
				if pet then pcall(function() if not isProtegida(pet) then remote:FireServer("unequipPet", pet) end end) end
			end
			for _, pet in ipairs(targets) do pcall(remote.FireServer, remote, "equipPet", pet) end
			local deadline = time() + math.max(1.4, (FastFarm.cachedPing or 0) / 250)
			repeat
				if not State.running or FastFarm.generation ~= generation then return 0 end
				if ready() then break end
				RunService.Heartbeat:Wait()
			until time() >= deadline
		end
		if not ready() then return 0 end
		FastFarm.confirmedPack = { name = key, references = selected, count = #targets }
		FastFarm.lastError = nil
		return #targets
	end
	FastFarm.EquipSetup = equipSetup


	local function fireReps(amount, machineSeat, allowFallback)
		local event = LP:FindFirstChild("muscleEvent")
		if not event then
			return false
		end
		local humanoid = getHumanoid()
		local machineReady = machineSeat and humanoid
			and machineIsActive(FastFarm.machine, machineSeat, humanoid)
		if not machineReady and not allowFallback then
			return false
		end
		for _ = 1, amount or CONFIG.FastFarm.RepsPerCycle do
			if machineReady then
				pcall(event.FireServer, event, "rep", machineSeat)
			else
				pcall(event.FireServer, event, "rep")
			end
		end
		if FastFarm.currentCycle and FastFarm.mode == "rebirth" then
			FastFarm.currentCycle.reps = FastFarm.currentCycle.reps + (amount or CONFIG.FastFarm.RepsPerCycle)
		end
		return true
	end


	local function adaptiveRepDelay(mode, machineSeat)
		local now = time()
		local sampled = false
		if now - FastFarm.pingCheckedAt >= CONFIG.FastFarm.PingSampleInterval then
			FastFarm.cachedPing = getPing()
			FastFarm.pingCheckedAt = now
			sampled = true
		end
		local ping = FastFarm.cachedPing
		if mode == "rebirth" then
			local cycle = FastFarm.currentCycle
			if ping <= 0 then FastFarm.repBlockedReason = "ping_pending"; return 0.2, false end
			if not FastFarm.rebirthIdlePing or FastFarm.rebirthIdlePing <= 0 then
				FastFarm.rebirthIdlePing = ping
			end
			local baseline = FastFarm.rebirthIdlePing
			local pauseAt = CONFIG.FastFarm.RebirthPingPause
			local resumeAt = math.max(0, pauseAt - 150)
			if cycle then cycle.maxPing = math.max(cycle.maxPing, ping) end
			if ping >= pauseAt then FastFarm.pingPaused = true end
			if FastFarm.pingPaused then
				if sampled then
					if ping > 0 and ping <= resumeAt then
						FastFarm.resumeSamples = FastFarm.resumeSamples + 1
					else
						FastFarm.resumeSamples = 0
					end
				end
				if FastFarm.resumeSamples < 3 then FastFarm.repBlockedReason = "ping"; return 0.25, false end
				FastFarm.pingPaused, FastFarm.resumeSamples = false, 0
				if cycle then cycle.lastGainAt = time() end
			end
			if not FastFarm:HasRebirthMachine() then
				FastFarm.repBlockedReason = "machine_or_pack"
				return 0.1, false
			end
			if (FastFarm.strengthPackRepBoost or 0) < 0.9 then
				FastFarm.repBlockedReason = nil
				fireReps(FastFarm.strengthBatch or CONFIG.FastFarm.RepsPerCycle, machineSeat, false)
				return 0.05, true
			end
			local amount = math.max(CONFIG.FastFarm.RebirthRepBatch, FastFarm.strengthBatch or CONFIG.FastFarm.RebirthRepBatch)
			local idle = cycle and time() - cycle.lastGainAt or 0
			if ping > baseline + CONFIG.FastFarm.RebirthPingRise or idle > 0.65 then amount = 1 end
			if idle > 1.25 then FastFarm.repBlockedReason = "no_progress"; return 0.2, false end
			FastFarm.repBlockedReason = nil
			fireReps(amount, machineSeat, false)
			return 0.05, true
		end
		local reducerEnabled = FastFarm.pingReducer == true

		local function sendReps(amount)
			return fireReps(amount, machineSeat, mode == "rebirth")
		end
		local pauseAt = reducerEnabled and CONFIG.FastFarm.PingReducerPause or CONFIG.FastFarm.PingPause
		local resumeAt = reducerEnabled and CONFIG.FastFarm.PingReducerResume or CONFIG.FastFarm.PingResume

		if mode ~= "rebirth" and mode ~= "strength" and not FastFarm.pingPaused and ping >= pauseAt then
			FastFarm.pingPaused = true
			FastFarm.resumeSamples = 0
			FastFarm.strengthBatch = CONFIG.FastFarm.StrengthMinBatch
			FastFarm.lastBatchAdjust = now
		end

		if mode ~= "rebirth" and mode ~= "strength" and FastFarm.pingPaused then
			if sampled then
				if ping <= resumeAt then
					FastFarm.resumeSamples = FastFarm.resumeSamples + 1
				else
					FastFarm.resumeSamples = 0
				end
				if FastFarm.resumeSamples >= 4 then
					FastFarm.pingPaused = false
					FastFarm.resumeSamples = 0
					if mode == "strength" then
						FastFarm.strengthBatch = math.max(
							FastFarm.strengthBatch,
							math.floor(CONFIG.FastFarm.StrengthStartBatch * 0.75)
						)
						FastFarm.lastBatchAdjust = now
					end
				end
			end
			if FastFarm.pingPaused then
				return 0.25, false
			end
		end
		if mode == "strength" then
			if sampled then
				if ping >= CONFIG.FastFarm.StrengthBackoffPing
					and now - FastFarm.lastBatchAdjust >= CONFIG.FastFarm.StrengthBackoffInterval then
					FastFarm.strengthBatch = math.max(
						CONFIG.FastFarm.StrengthMinBatch,
						FastFarm.strengthBatch - (reducerEnabled and 6 or 4)
					)
					FastFarm.lastBatchAdjust = now
				elseif ping <= CONFIG.FastFarm.StrengthRampPing
					and now - FastFarm.lastBatchAdjust >= CONFIG.FastFarm.StrengthRampInterval then
					FastFarm.strengthBatch = math.min(
						CONFIG.FastFarm.StrengthMaxBatch,
						FastFarm.strengthBatch + 2
					)
					FastFarm.lastBatchAdjust = now
				end
			end
			local repScale = 1
			local delayScale = 1
			local criticalAt = CONFIG.FastFarm.StrengthPingCritical

			local function scaledReps(amount, minimum)
				return math.max(minimum or 1, math.floor(amount * repScale))
			end
			if ping >= criticalAt then
				sendReps(1)
				return 0.25, true
			elseif ping >= CONFIG.FastFarm.StrengthPingHigh then
				sendReps(scaledReps(2))
				return 0.18 * delayScale, true
			elseif ping >= CONFIG.FastFarm.StrengthPingMedium then
				sendReps(scaledReps(FastFarm.strengthBatch * 0.18, 3))
				return 0.09 * delayScale, true
			elseif ping >= CONFIG.FastFarm.StrengthPingSoft then
				sendReps(scaledReps(FastFarm.strengthBatch * 0.35, 6))
				return 0.05 * delayScale, true
			end
			sendReps(scaledReps(FastFarm.strengthBatch * 0.6, 10))
			return CONFIG.FastFarm.StrengthDelay * delayScale, true
		end

		if ping >= CONFIG.FastFarm.PingCritical then
			sendReps(4)
			return 0.35, true
		elseif ping >= CONFIG.FastFarm.PingHigh then
			sendReps(10)
			return 0.18, true
		elseif ping >= CONFIG.FastFarm.PingMedium then
			sendReps(24)
			return 0.075, true
		elseif ping >= CONFIG.FastFarm.PingSoft then
			sendReps(36)
			return 0.025, true
		end
		sendReps(CONFIG.FastFarm.RepsPerCycle)
		return CONFIG.FastFarm.RepDelay, true
	end


	local function goldenRebirths()
		local attributeName = UltimateAttributes["Golden Rebirth"]
		local value = attributeName and LP:GetAttribute(attributeName)
		return typeof(value) == "number" and math.max(0, math.floor(value)) or 0
	end


	local function requiredStrength(rebirthValue)
		if not machineFunctions then
			pcall(function()
				local shared = ReplicatedStorage:FindFirstChild("shared")
				local modules = shared and shared:FindFirstChild("modules")
				local module = modules and modules:FindFirstChild("GlobalFunctions")
				if module and module:IsA("ModuleScript") then machineFunctions = require(module) end
			end)
		end
		if machineFunctions and type(machineFunctions.calculateRequiredRebirthStrength) == "function" then
			local ok, official = pcall(machineFunctions.calculateRequiredRebirthStrength, rebirthValue, LP)
			if ok and type(official) == "number" then return math.floor(official) end
		end
		local required = 10000 + 5000 * (tonumber(rebirthValue) or 0)
		local golden = goldenRebirths()
		if golden > 0 then required = required * math.max(0.1, 1 - golden * 0.1) end
		return math.floor(required)
	end


	local function requestRebirth()
		local events = farmEvents()
		local remote = events and events:FindFirstChild("rebirthRemote")
		if remote and remote:IsA("RemoteFunction") then
			local ok, accepted = pcall(remote.InvokeServer, remote, "rebirthRequest")
			return ok and accepted == true
		elseif remote and remote:IsA("RemoteEvent") then
			return pcall(remote.FireServer, remote, "rebirthRequest")
		end
		return false
	end
	FastFarm.GetRequiredRebirthStrength = requiredStrength
	FastFarm.RequestRebirth = requestRebirth


	local function waitForRebirthWindow(controller, generation, mode)
		while State.running and controller.mode == mode and controller.generation == generation do
			local deadline = controller.nextRebirthRequestAt
			if not deadline then return true end
			local remaining = deadline - os.clock()
			if remaining <= 0 then return true end
			if remaining > 0.12 then
				task.wait(math.min(remaining - 0.06, 0.2))
			else
				RunService.Heartbeat:Wait()
			end
		end
		return false
	end


	local function applyLocalSizeOne()
		local humanoid = getHumanoid()
		if not humanoid then
			return
		end
		for _, name in ipairs({
			"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale",
		}) do
			local scale = humanoid:FindFirstChild(name)
			if scale and scale:IsA("NumberValue") then
				pcall(function()
					scale.Value = 1
				end)
			end
		end
	end


	local function setSizeOne()
		applyLocalSizeOne()
		local now = time()
		if FastFarm.sizeInvokeBusy
			or now - FastFarm.lastSizeInvoke < CONFIG.FastFarm.SizeInvokeInterval then
			return
		end
		local events = farmEvents()
		local remote = events and events:FindFirstChild("changeSpeedSizeRemote")
		if remote then
			FastFarm.sizeInvokeBusy = true
			FastFarm.lastSizeInvoke = now
			task.spawn(function()
				pcall(remote.InvokeServer, remote, "changeSize", 1)
				FastFarm.sizeInvokeBusy = false
			end)
		end
	end
	FastFarm.SetSizeOne = setSizeOne


	local function holdSizeOne(seconds)
		FastFarm.sizeReleaseGeneration = FastFarm.sizeReleaseGeneration + 1
		local releaseGeneration = FastFarm.sizeReleaseGeneration
		task.spawn(function()
			local deadline = time() + (seconds or CONFIG.FastFarm.SizeReleaseDuration)
			while State.running and FastFarm.mode == nil
				and FastFarm.sizeReleaseGeneration == releaseGeneration and time() < deadline do
				setSizeOne()
				task.wait(0.1)
			end
		end)
	end


	local function minimumIndustrialStrength()
		local folder = workspace:FindFirstChild("machinesFolder")
		local minimum = math.huge
		for _, machine in ipairs(folder and folder:GetChildren() or {}) do
			if machine:IsA("Model") and string.find(machine.Name, "Industrial", 1, true) then
				local seat = machine.PrimaryPart
				if not (seat and seat:IsA("Seat")) then seat = machine:FindFirstChild("interactSeat", true) end
				local requirements = machine:FindFirstChild("requirements")
				local requirement = requirements and (requirements:FindFirstChild("Strength")
					or requirements:FindFirstChild("Fuerza"))
				if seat and seat:IsA("Seat") and requirement and requirement:IsA("ValueBase") then
					minimum = math.min(minimum, tonumber(requirement.Value) or math.huge)
				end
			end
		end
		return minimum < math.huge and math.max(0, minimum) or 0
	end
	FastFarm.GetMinimumIndustrialStrength = minimumIndustrialStrength

	FastFarm.NeedsBootstrap = function(strength)
		return (tonumber(strength) or 0) < minimumIndustrialStrength()
	end
	FastFarm.MachineEntryWait = 2.3
	FastFarm.MachineRetryDelay = 2.15


	function FastFarm:BootstrapToIndustrial(generation, mode)
		if mode == "rebirth" and self:HasRebirthMachine() then
			self.bootstrapAutoWeight = false
			return true
		end
		local minimum = minimumIndustrialStrength()
		local strength = readStat({ "Strength", "Fuerza" })
		if minimum <= 0 or strength >= minimum then
			self.bootstrapAutoWeight = false
			return true
		end
		self.bootstrapAutoWeight = true
		equipTool({ "Weight" })
		self.bootstrapTool = getCharacter() and getCharacter():FindFirstChild("Weight")
		local progressAt, previousStrength = time(), strength
		while State.running and self.generation == generation and self.mode == mode do
			strength = readStat({ "Strength", "Fuerza" })
			if strength >= minimum then break end
			if strength > previousStrength then progressAt, previousStrength = time(), strength end
			if time() - progressAt > 3 or not self.bootstrapTool or self.bootstrapTool.Parent ~= getCharacter() then
				self.lastError = "Weight temporal sin progreso"
				break
			end
			if mode == "rebirth" then
				if self.currentCycle then self.currentCycle.bootstrap = true end
				self.cachedPing = getPing()
				if self.cachedPing >= CONFIG.FastFarm.RebirthPingPause then break end
			end
			fireReps(mode == "rebirth" and 1 or 6, nil, true)
			task.wait(0.08)
		end
		self:CleanBootstrapTool()
		return self.generation == generation and self.mode == mode
			and readStat({ "Strength", "Fuerza" }) >= minimum
	end


	local function machineDefinition(objectName)
		for _, definition in ipairs(CONFIG.Machines) do
			if definition.object == objectName then
				return definition
			end
		end
		return nil
	end


	local function fastFarmMachineCandidates(primaryObject)
		local folder = workspace:FindFirstChild("machinesFolder")
		local candidates = {}
		if not folder then return candidates end
		for _, machine in ipairs(folder:GetChildren()) do
			local gain = machine:FindFirstChild("strengthGain")
			local gainValue = gain and tonumber(gain.Value) or 0
			if machine:IsA("Model") and gainValue > 0 then
				local definition = { object = machine.Name, instance = machine }
				local resolved, seat = getMachineParts(definition)
				if resolved and seat then
					definition.seat = seat
					definition.label = machine.Name
					definition.isPrimary = (machine.Name == primaryObject)
					definition.score = gainValue / math.max(0.05, machineRepDelay(machine))
					candidates[#candidates + 1] = definition
				end
			end
		end
		table.sort(candidates, function(a, b)
			if a.isPrimary ~= b.isPrimary then return a.isPrimary end
			return a.score > b.score
		end)
		return candidates
	end
	FastFarm.GetMachineCandidates = fastFarmMachineCandidates


	local function acquireFastFarmMachine(generation, mode, primaryObject)
		local now = time()
		if now < (FastFarm.nextMachineAcquireAt or 0) then return false end
		FastFarm.nextMachineAcquireAt = now + 2.5
		for _, definition in ipairs(fastFarmMachineCandidates(primaryObject)) do
			if FastFarm.generation ~= generation or FastFarm.mode ~= mode then
				return false
			end
			local cooldownKey = definition.instance or definition
			local blockedUntil = FastFarm.machineFailureCooldowns[cooldownKey]
			if not blockedUntil or now >= blockedUntil then
				local ready, machine, seat, rejectionReason = useMachine(definition, 2)
				local humanoid = getHumanoid()
				if ready and machine and seat and machineIsActive(machine, seat, humanoid) then
					FastFarm.machine = machine
					FastFarm.machineSeat = seat
					FastFarm.machineDefinition = definition
					FastFarm.lastMachineSelection = definition.label or definition.object
					FastFarm.machineFailureCooldowns[cooldownKey] = nil
					FastFarm.nextMachineAcquireAt = 0
					if mode == "rebirth" then
						local root = getRoot()
						FastFarm.lockCharacter = getCharacter()
						FastFarm.lockCFrame = FastFarm.SafeMachineLockCFrame(FastFarm.lockCharacter, root and root.CFrame)
					end
					return true
				end
				if rejectionReason == "occupied" then
					FastFarm.machineFailureCooldowns[cooldownKey] = time() + 3
				else
					FastFarm.nextMachineAcquireAt = time() + 0.65
				end
				return false
			end
		end
		FastFarm.machine = nil
		FastFarm.machineSeat = nil
		FastFarm.machineDefinition = nil
		FastFarm.lastMachineSelection = nil
		return false
	end

	FastFarm.AcquireStrengthMachine = function(generation)
		return acquireFastFarmMachine(generation, "strength", CONFIG.FastFarm.StrengthMachine)
	end


	local function prepareLift(generation)
		return FastFarm:AcquireRebirthMachine(generation)
	end


	local function setFarmFrames(enabled)
		if FastFarm.HideFramesToggle then
			FastFarm.HideFramesToggle:Set(enabled)
		else
			setHideFrames(enabled)
		end
	end
	FastFarm.SetFarmFrames = setFarmFrames


	local function disableOtherFarmControls()
		for _, toggle in ipairs(FastFarm.RepToggles or {}) do
			toggle:Set(false)
		end
		for _, toggle in ipairs(FastFarm.MachineToggles or {}) do
			toggle:Set(false)
		end
		for _, toggle in ipairs(FastFarm.FullTrainToggles or {}) do
			toggle:Set(false)
		end
	end


	function FastFarm:ReadStats()
		return readStats()
	end


	function FastFarm:CalculateRebirthRate(samples)
		samples = samples or self.validRebirthSamples or {}
		if #samples < 3 then return nil, #samples end
		local durations = {}
		local deltas = {}
		for _, sample in ipairs(samples) do
			local duration = tonumber(sample.duration)
			local delta = tonumber(sample.delta)
			if duration and delta and duration >= 0.4 and duration <= 120 and delta >= 1 and delta <= 10000 then
				durations[#durations + 1] = duration
				deltas[#deltas + 1] = delta
			end
		end
		if #durations < 3 then return nil, #durations end
		local sortedDurations = table.clone(durations)
		local sortedDeltas = table.clone(deltas)
		table.sort(sortedDurations)
		table.sort(sortedDeltas)

		local function median(values)
			local count = #values
			local middle = math.floor((count + 1) * 0.5)
			return count % 2 == 0 and (values[middle] + values[middle + 1]) * 0.5 or values[middle]
		end
		local medianDuration = median(sortedDurations)
		local medianDelta = median(sortedDeltas)
		local totalDuration, totalDelta, accepted = 0, 0, 0
		for _, sample in ipairs(samples) do
			local duration = tonumber(sample.duration)
			local delta = tonumber(sample.delta)
			if duration and delta
				and duration >= math.max(0.4, medianDuration * 0.4)
				and duration <= math.min(120, medianDuration * 2.5)
				and delta >= math.max(1, medianDelta * 0.25)
				and delta <= math.min(10000, medianDelta * 4) then
				totalDuration = totalDuration + duration
				totalDelta = totalDelta + delta
				accepted = accepted + 1
			end
		end
		if accepted < 3 or totalDuration <= 0 then return nil, accepted end
		return totalDelta / totalDuration, accepted
	end


	function FastFarm:CalculateStrengthRate(samples)
		samples = samples or self.validStrengthSamples or {}
		if #samples < 3 then return nil, #samples end
		local durations = {}
		local deltas = {}
		for _, sample in ipairs(samples) do
			local duration = tonumber(sample.duration)
			local delta = tonumber(sample.delta)
			if duration and delta and duration >= 0.05 and duration <= 30 and delta > 0 then
				durations[#durations + 1] = duration
				deltas[#deltas + 1] = delta
			end
		end
		if #durations < 3 then return nil, #durations end
		local sortedDurations = table.clone(durations)
		local sortedDeltas = table.clone(deltas)
		table.sort(sortedDurations)
		table.sort(sortedDeltas)

		local function median(values)
			local count = #values
			local middle = math.floor((count + 1) * 0.5)
			return count % 2 == 0 and (values[middle] + values[middle + 1]) * 0.5 or values[middle]
		end
		local medianDuration = median(sortedDurations)
		local medianDelta = median(sortedDeltas)
		local totalDuration, totalDelta, accepted = 0, 0, 0
		for _, sample in ipairs(samples) do
			local duration = tonumber(sample.duration)
			local delta = tonumber(sample.delta)
			if duration and delta
				and duration >= math.max(0.05, medianDuration * 0.25)
				and duration <= math.min(30, medianDuration * 4)
				and delta >= math.max(1, medianDelta * 0.1)
				and delta <= medianDelta * 10 then
				totalDuration = totalDuration + duration
				totalDelta = totalDelta + delta
				accepted = accepted + 1
			end
		end
		if accepted < 3 or totalDuration <= 0 then return nil, accepted end
		return totalDelta / totalDuration, accepted
	end


	function FastFarm:FormatCompact(value)
		local number = tonumber(value) or 0
		local absolute = math.abs(number)
		local units = {
			{ 1e18, "QI" }, { 1e15, "QA" }, { 1e12, "T" },
			{ 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" },
		}
		for _, unit in ipairs(units) do
			if absolute >= unit[1] then
				local scaled = number / unit[1]
				local decimals = math.abs(scaled) >= 100 and 0 or (math.abs(scaled) >= 10 and 1 or 2)
				local compact = string.format("%." .. decimals .. "f", scaled)
				compact = compact:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
				return compact .. unit[2]
			end
		end
		return formatExact(number)
	end


	function FastFarm:FormatExactWithUnit(value)
		local number = tonumber(value) or 0
		local absolute = math.abs(number)
		local suffix = absolute >= 1e18 and "QI"
			or (absolute >= 1e15 and "QA")
			or (absolute >= 1e12 and "T")
			or (absolute >= 1e9 and "B")
			or (absolute >= 1e6 and "M")
			or (absolute >= 1e3 and "K")
			or ""
		return formatExact(number) .. suffix
	end


	function FastFarm:CleanBootstrapTool()
		local tool = self.bootstrapTool
		self.bootstrapTool, self.bootstrapAutoWeight = nil, false
		if tool and tool.Parent == getCharacter() and LP:FindFirstChild("Backpack") then
			tool.Parent = LP.Backpack
		end
	end


	function FastFarm:AcquireRebirthMachine(generation)
		if self:HasRebirthMachine() then return true end
		if time() < (self.nextMachineAcquireAt or 0) then return false end
		self.nextMachineAcquireAt = time() + 0.6
		local folder = workspace:FindFirstChild("machinesFolder")
		local candidates = {}
		for _, machine in ipairs(folder and folder:GetChildren() or {}) do
			if machine:IsA("Model")  and machine:FindFirstChild("strengthGain") then
				local definition = { object = machine.Name, instance = machine }
				local resolved, seat = getMachineParts(definition)
				if resolved and seat then candidates[#candidates + 1] = definition end
			end
		end
		table.sort(candidates, function(a, b)
			return a.instance.strengthGain.Value > b.instance.strengthGain.Value
		end)
		local definition
		for _, candidate in ipairs(candidates) do
			local blocked = self.machineFailureCooldowns[candidate.instance] or 0
			if time() >= blocked then definition = candidate; break end
		end
		if definition then
			local ready, machine, seat, reason = useMachine(definition, 3)
			if self.mode ~= "rebirth" or self.generation ~= generation then return false end
			if ready then
				self.machine, self.machineSeat, self.machineDefinition = machine, seat, definition
				self.machineCharacter = getCharacter()
				if self:HasRebirthMachine() then
					self.lastMachineSelection = machine.Name
					self.lockCharacter = getCharacter()
					local root = getRoot()
					self.lockCFrame = self.SafeMachineLockCFrame(self.lockCharacter, root and root.CFrame)
					self.lastError = nil
					return true
				end
			end
			if reason == "occupied" then
				self.machineFailureCooldowns[definition.instance] = time() + 3
				self.lastError = "Máquina ocupada; buscando otra disponible"
			else
				self.nextMachineAcquireAt = time() + 0.65
				self.lastError = "Confirmando " .. tostring(definition.instance and definition.instance.Name or definition.object)
			end
			return false
		end
		self.nextMachineAcquireAt = time() + 0.45
		self.lastError = "No hay máquina industrial disponible con los requisitos actuales"
		return false
	end


	function FastFarm:HasRebirthMachine()
		local machine, seat, humanoid = self.machine, self.machineSeat, getHumanoid()
		if not machine or not machine.Parent or not seat or not seat:IsDescendantOf(machine)
			or not humanoid or humanoid.Health <= 0 or self.machineCharacter ~= getCharacter() then return false end
		local serverSeat = LP:FindFirstChild("machineInUse")
		return (serverSeat and serverSeat.Value == seat)
			or (humanoid.SeatPart == seat and seat.Occupant == humanoid)
			or tonumber(machine:GetAttribute("InUseUserId")) == LP.UserId
	end


	function FastFarm:PackStillConfirmed(name)
		local pack, equipped = self.confirmedPack, LP:FindFirstChild("equippedPets")
		if not pack or pack.name ~= name or not equipped then return false end
		local count, occupied, seen = 0, 0, {}
		for _, slot in ipairs(equipped:GetChildren()) do
			local ref = (slot:FindFirstChild("petReference") or slot)
			local pet = ref and ref:IsA("ObjectValue") and ref.Value
			if pet then
				if not isProtegida(pet) then occupied = occupied + 1 end
				if slot:IsA("ObjectValue") and slot.Value and pack.references[pet]
					and pet.Parent and not seen[pet] then
					seen[pet], count = true, count + 1
				end
			end
		end
		return count == pack.count and occupied == count
	end


	function FastFarm:GetRebirthNetwork()
		local network = Env.__FGRebirthNet
		if type(network) ~= "table" or network.player ~= LP then
			network = { player = LP }
			Env.__FGRebirthNet = network
		end
		return network
	end


	function FastFarm:RequestTrackedRebirth(generation)
		if self.generation ~= generation or self.mode ~= "rebirth" then return nil, "cancelled" end
		local network = self:GetRebirthNetwork()
		if network.pending and not network.pending.done then return nil, "pending" end
		local events = farmEvents()
		local remote = events and events:FindFirstChild("rebirthRemote")
		if not remote or not remote:IsA("RemoteFunction") then return nil, "remote_missing" end
		local operation = { requestedAt = os.clock(), done = false, oldRebirths = readStat({ "Rebirths", "Rebirth" }) }
		network.pending = operation
		task.spawn(function()
			local ok, accepted = pcall(remote.InvokeServer, remote, "rebirthRequest")
			operation.accepted, operation.done = ok and accepted == true, true
			operation.answeredAt = os.clock()
			if operation.accepted then
				network.nextRequestAt = operation.requestedAt
					+ CONFIG.FastFarm.RebirthCooldown + CONFIG.FastFarm.RebirthSafetyMargin
			end
		end)
		return operation
	end


	function FastFarm:FinishRebirthCycle(reason)
		for _, key in ipairs({ "strengthConnection", "rebirthConnection" }) do
			if self[key] then self[key]:Disconnect(); self[key] = nil end
		end
		local cycle = self.currentCycle
		if not cycle then return end
		if reason == "confirmed" then self:RestoreManualPets() end
		cycle.elapsed, cycle.reason = os.clock() - cycle.startedAt, reason
		cycle.phase = self.phase
		cycle.lastGainAt = nil
		self.rebirthDiagnostics = self.rebirthDiagnostics or {}
		self.rebirthDiagnostics[#self.rebirthDiagnostics + 1] = cycle
		if #self.rebirthDiagnostics > 1024 then table.remove(self.rebirthDiagnostics, 1) end
		self.currentCycle = nil
	end


	function FastFarm:SnapshotEquipped()
		local names = {}
		local eq = LP:FindFirstChild("equippedPets")
		if eq then
			for _, slot in ipairs(eq:GetChildren()) do
				local ref = slot:FindFirstChild("petReference")
				local pet = (ref and ref:IsA("ObjectValue") and ref.Value) or (slot:IsA("ObjectValue") and slot.Value) or nil
				if pet and pet:IsA("StringValue") and not isProtegida(pet) then
					names[#names + 1] = pet.Name
				end
			end
		end
		self.manualPets = names
		return #names
	end
	function FastFarm:RestoreManualPets()
		local counts = {}
		for _, name in ipairs(self.manualPets or {}) do
			counts[name] = (counts[name] or 0) + 1
		end
		local setup = {}
		for name, c in pairs(counts) do
			setup[#setup + 1] = { name = name, count = c }
		end
		if #setup > 0 then
			FastFarm.EquipSetup(setup, "manual-restore")
		end
	end
	function FastFarm:UseCurrentMachine()
		local hum = getHumanoid()
		local seat = hum and hum.SeatPart or nil
		if not seat then return false end
		if self.machineSeat == seat and self.machine and self.machine.Parent then return true end
		local folder = workspace:FindFirstChild("machinesFolder")
		for _, machine in ipairs(folder and folder:GetChildren() or {}) do
			if machine:IsA("Model") then
				local s = machine.PrimaryPart
				if not (s and s:IsA("Seat")) then s = machine:FindFirstChild("interactSeat", true) end
				if s == seat then
					self.machine = machine
					self.machineSeat = seat
					self.machineDefinition = { object = machine.Name, instance = machine }
					self.machineCharacter = getCharacter()
					return true
				end
			end
		end
		return false
	end

function FastFarm:RunRebirthCycle(generation)
		local pending = self:GetRebirthNetwork().pending
		if pending and (not pending.done or (pending.accepted
			and readStat({ "Rebirths", "Rebirth" }) <= pending.oldRebirths)) then
			self.phase, self.lastError = "pending", "Esperando el rebirth anterior; no se duplican solicitudes"
			return false
		end
		local character = getCharacter()
		local rebirths, rebirthObject = readStat({ "Rebirths", "Rebirth" })
		local strength, strengthObject = readStat({ "Strength", "Fuerza" })
		if not character or not getHumanoid() or getHumanoid().Health <= 0
			or not strengthObject or not rebirthObject then
			self.lastError = "Esperando personaje y stats"
			return false
		end
		if self.machineCharacter and self.machineCharacter ~= character then
			self.lockCFrame, self.lockCharacter = nil, nil
			leaveMachine()
			self.machine, self.machineSeat, self.machineCharacter = nil, nil, nil
			self.nextMachineAcquireAt = 0
		end
		local required = requiredStrength(rebirths)
		local target = math.max(required + 1, math.ceil(required * (1 + CONFIG.FastFarm.RebirthStrengthBufferRatio)))
		self.lastRequiredStrength = required
		self.lastTargetStrength = target
		local cycle = {
			startedAt = self.lastSuccessfulRebirthAt or os.clock(), lastGainAt = time(), initialStrength = strength,
			confirmedAt = false,
			reps = 0, attempts = {}, recoveries = 0, maxPing = getPing(),
			machine = self.machine and self.machine.Name,
			startup = self.lastSuccessfulRebirthAt == nil, bootstrap = false, required = required, target = target,
		}
		self.currentCycle = cycle
		self.cycleCount = self.cycleCount + 1
		local previousStrength = strength

		local function observeStrength()
			local value = tonumber(State.getFunctionalStatValue(strengthObject)) or 0
			if value > previousStrength then
				cycle.firstGain = cycle.firstGain or os.clock() - cycle.startedAt
				cycle.lastGainAt = time()
				self.cycleStrengthGain = (self.cycleStrengthGain or 0) + value - previousStrength
			end
			previousStrength = value
			if value >= target then cycle.targetAt = cycle.targetAt or os.clock() - cycle.startedAt end
			return value
		end
		self.strengthConnection = strengthObject:GetPropertyChangedSignal("Value"):Connect(observeStrength)
		self.rebirthConnection = rebirthObject:GetPropertyChangedSignal("Value"):Connect(function()
			local value = tonumber(State.getFunctionalStatValue(rebirthObject)) or rebirths
			if value > rebirths and not cycle.confirmedAt then
				cycle.confirmedAt, cycle.delta = os.clock(), value - rebirths
			end
		end)

		local function alive()
			return State.running and self.mode == "rebirth" and self.generation == generation
				and getCharacter() == character and strengthObject.Parent and rebirthObject.Parent
				and getHumanoid() and getHumanoid().Health > 0
		end
		self.phase = "strength_pack"
		self.cycleStrengthGain = 0
		self.packCount = self:SnapshotEquipped()
		if not alive() then return false end
		if self.packCount < 1 then
			self.lastError = 'Equipa una pet de fuerza del inventario'
		return false
		end
		cycle.strengthPack, cycle.strengthPets = self.strengthPack, self.packCount
		cycle.strengthPackAt = os.clock() - cycle.startedAt
		while alive() and observeStrength() < target do
			if not self:UseCurrentMachine() then
				self.phase = 'machine'
				self.lastError = 'Sentate en una maquina'
				task.wait(0.5)
				return false
			end
			self.phase = 'training'
			if not alive() then return false end
			if not self.pingPaused and self:HasRebirthMachine() and time() - cycle.lastGainAt > 2.5 then
				cycle.recoveries = cycle.recoveries + 1
				cycle.lastGainAt = time()
				if cycle.recoveries >= 3 then return false end
			end
			local delay = adaptiveRepDelay("rebirth", self.machineSeat)
			task.wait(delay)
		end
		if not alive() then return false end
		cycle.strengthReadyAt = os.clock() - cycle.startedAt
		self.phase = "rebirth_pack"
		self.packCount = equipSetup(self.rebirthSetup, self.rebirthPack)
		if not alive() or self.packCount < 1
			or not self:PackStillConfirmed(self.rebirthPack) then return false end
			self.expectedRebirthDelta = math.max(1, math.floor(self.expectedRebirthDelta / math.max(1, self.rebirthPackCount) * self.packCount + 0.5))
		cycle.tribalPets, cycle.tribalConfirmed = self.packCount, true
		cycle.rebirthPack, cycle.expectedDelta = self.rebirthPack, self.expectedRebirthDelta
		cycle.tribalPackAt = os.clock() - cycle.startedAt
		local network = self:GetRebirthNetwork()
		for attempt = 1, 3 do
			self.phase = "cooldown"
			self.nextRebirthRequestAt = network.nextRequestAt or self.nextRebirthRequestAt
			if not waitForRebirthWindow(self, generation, "rebirth") or not alive() then return false end
			if not self:PackStillConfirmed(self.rebirthPack) then return false end
			cycle.strengthBefore = observeStrength()
			cycle.required = requiredStrength(readStat({ "Rebirths", "Rebirth" }))
			local currentTarget = math.max(cycle.required + 1,
				math.ceil(cycle.required * (1 + CONFIG.FastFarm.RebirthStrengthBufferRatio)))
			if cycle.strengthBefore < currentTarget then
				self.lastError = "Fuerza pendiente antes de renacer"
				return false
			end
			self.phase = "request"
			local operation, err = self:RequestTrackedRebirth(generation)
			if not operation then self.lastError = err; return false end
			cycle.attempts[#cycle.attempts + 1] = operation
			local deadline = os.clock() + math.max(3, getPing() / 1000 * 4)
			while alive() and not operation.done and os.clock() < deadline do RunService.Heartbeat:Wait() end
			if not alive() then return false end
			if not operation.done then self.lastError = "Rebirth pendiente del servidor"; return false end
			self.lastRebirthAccepted = operation.accepted
			self.phase = "confirmation"
			while alive() and operation.accepted and not cycle.confirmedAt and os.clock() < deadline do
				RunService.Heartbeat:Wait()
			end
			if cycle.confirmedAt then
				cycle.interval = self.lastSuccessfulRebirthAt and cycle.confirmedAt - self.lastSuccessfulRebirthAt or nil
				cycle.confirmationDelay = cycle.confirmedAt - operation.requestedAt
				if not self.sessionStartedAt then
					self.sessionStartedAt = cycle.confirmedAt
					self.startedAt = cycle.confirmedAt
				end
				self.lastSuccessfulRebirthAt = cycle.confirmedAt
				self.nextRebirthRequestAt = network.nextRequestAt
				self.successfulRebirths = self.successfulRebirths + 1
				self.validRebirthSamples[#self.validRebirthSamples + 1] = {
					at = cycle.confirmedAt, duration = cycle.interval or cycle.confirmedAt - cycle.startedAt, delta = cycle.delta,
				}
				if #self.validRebirthSamples > 9 then table.remove(self.validRebirthSamples, 1) end
				if cycle.delta < self.expectedRebirthDelta then
					self.lastError = "Rebirth confirmado con incremento menor a +"
						.. tostring(self.expectedRebirthDelta) .. ": +" .. tostring(cycle.delta)
					self:FinishRebirthCycle("unexpected_delta")
					self:Stop(true)
					return false
				end
				self.lastError = nil
				return true
			end
			self.failedRebirths = self.failedRebirths + 1
			self.lastError = operation.accepted and "Falta confirmación de Rebirths" or "Rebirth rechazado"
			task.wait(0.35 * attempt)
		end
		return false
	end


	function FastFarm:Stop(restoreFrames, preserveSession)
		self:FinishRebirthCycle("cancelled")
		self:CleanBootstrapTool()
		if self.strengthConnection then
			self.strengthConnection:Disconnect()
			self.strengthConnection = nil
		end
		local keepSizeOne = self.mode ~= nil
		self.generation = self.generation + 1
		self.mode = nil
		State.fastFarmMode = nil
		self.lockCFrame = nil
		self.lockCharacter = nil
		self.machine = nil
		self.machineSeat = nil
		self.machineDefinition = nil
		self.lastMachineSelection = nil
		self.bootstrapAutoWeight = false
		self.nextMachineAcquireAt = 0
		self.nextRebirthRequestAt = nil
		self.startedAt = nil
		self.startStats = nil
		if not preserveSession then self.sessionStartedAt = nil end
		if FastFarm.UpdateStrengthFramesControl then
			FastFarm.UpdateStrengthFramesControl(false)
		end
		for _, key in ipairs({
			"fastFarmSize", "fastFarmLock", "fastFarmMachine",
			"fastFarmRebirth", "fastFarmStrength", "fastFarmVisual",
		}) do
			stopThread(key)
		end
		if keepSizeOne then
			leaveMachine()
		end
		local humanoid = getHumanoid()
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
		end
		if keepSizeOne then
			holdSizeOne(CONFIG.FastFarm.SizeReleaseDuration)
			State.setAutoEgg(false, "fastFarm")
		end
		if restoreFrames and self.hideFramesOwned then
			self.frameReleaseGeneration = self.frameReleaseGeneration + 1
			local releaseGeneration = self.frameReleaseGeneration
			task.delay(CONFIG.FastFarm.FramesReleaseDuration, function()
				if State.running and self.mode == nil
					and self.frameReleaseGeneration == releaseGeneration and self.hideFramesOwned then
					setFarmFrames(false)
					self.hideFramesOwned = false
				end
			end)
		end
	end


	function FastFarm:Start(mode)
		if mode ~= "rebirth" and mode ~= "strength" then
			return false
		end
		if self.mode == mode then
			return true
		end
		if mode == "rebirth" and (State.rebirth.autoTarget or State.rebirth.infinite
			or State.rebirth.fastWeight or State.rebirth.autoLift or State.autoWeight
			or LP:GetAttribute("AutoLiftEnabled") == true) then
			self.lastError = "Apagá los otros autos de entrenamiento y rebirth antes de Fast Rebirth"
			return false
		end
		self.packCache = {}
		local strengthAvailable, rebirthAvailable = self:LoadPack(true)
		if not strengthAvailable or self.strengthPackCount < 1 then
			self.lastError = "No se encontró un pack de fuerza compatible"
			return false
		end
		if mode == "rebirth" and (not rebirthAvailable or self.rebirthPackCount < 1
			or self.expectedRebirthDelta < 1) then
			self.lastError = "Fast Rebirth requiere al menos un pet con bonus de rebirth"
			return false
		end
		local previousSessionStartedAt = self.sessionStartedAt
		self:Stop(false, true)
		self.frameReleaseGeneration = self.frameReleaseGeneration + 1
		self.sizeReleaseGeneration = self.sizeReleaseGeneration + 1
		disableOtherFarmControls()
		self.mode = mode
		State.fastFarmMode = mode
		if mode == "rebirth" then
			self.sessionStartedAt = nil
		else
			self.sessionStartedAt = previousSessionStartedAt or os.clock()
		end
		self.generation = self.generation + 1
		local generation = self.generation
		self.startedAt = self.sessionStartedAt or os.clock()
		self.startStats = readStats()
		self.packCount = 0
		self:GetPetSlotCapacity()
		self.requiredPackCount = math.max(1, math.min(
			self.petSlotCapacity,
			mode == "rebirth" and math.min(self.strengthPackCount, self.rebirthPackCount)
				or self.strengthPackCount
		))
		self.cycleCount = 0
		self.successfulRebirths = 0
		self.failedRebirths = 0
		self.validRebirthSamples = {}
		self.validStrengthSamples = {}
		self.lastSuccessfulRebirthAt = nil
		self.rebirthMeasurementStartedAt = os.clock()
		self.nextRebirthRequestAt = nil
		self.lastStrengthSampleAt = realNow()
		self.lastStrengthSampleValue = self.startStats.strength
		self.lastRequiredStrength = 0
		self.lastTargetStrength = 0
		self.cycleStrengthGain = 0
		self.lastRebirthAccepted = false
		self.lastError = nil
		self.cachedPing = getPing()
		self.rebirthIdlePing = self.cachedPing
		self.machineCharacter = nil
		self.rebirthDiagnostics = {}
		self.pingCheckedAt = time()
		self.pingPaused = false
		self.resumeSamples = 0
		self.strengthBatch = CONFIG.FastFarm.StrengthStartBatch
		self.lastBatchAdjust = time()
		self.machineFailureCooldowns = {}
		self.bootstrapAutoWeight = false
		self.nextMachineAcquireAt = 0
		if not State.hideFrames then
			self.hideFramesOwned = true
		end
		setFarmFrames(true)
		if FastFarm.UpdateStrengthFramesControl then
			FastFarm.UpdateStrengthFramesControl(mode == "strength")
		end
		State.setAutoEgg(mode == "strength", "fastFarm")
		setSizeOne()
		startThread("fastFarmSize", function()
			while State.running and self.mode == mode and self.generation == generation do
				setSizeOne()
				task.wait(0.1)
			end
		end)
		startThread("fastFarmVisual", function()
			local lastVisualRep = 0
			while State.running and self.mode == mode and self.generation == generation do
				local machine = self.machine
				local seat = self.machineSeat
				local humanoid = getHumanoid()
				if machine and seat and machineIsActive(machine, seat, humanoid) then
					FastFarm.MachineVisuals.playIdle(machine)
					local visualDelay = machineRepDelay(machine)
					if time() - lastVisualRep >= visualDelay then
						if FastFarm.MachineVisuals.playRep(machine) then
							lastVisualRep = time()
						end
					end
				else
					if FastFarm.MachineVisuals.activeMachine then
						FastFarm.MachineVisuals.stopAnimations(0.1)
					end
					lastVisualRep = 0
				end
				task.wait(0.05)
			end
			FastFarm.MachineVisuals.stopAnimations(0.1)
		end)

		if mode == "rebirth" then
			startThread("fastFarmLock", function()
				while State.running and self.mode == mode and self.generation == generation do
					local character = getCharacter()
					local root = getRoot()
					if root and self.lockCFrame and self.lockCharacter == character then
						self.lockCFrame = self.SafeMachineLockCFrame(self.lockCharacter, self.lockCFrame) or self.lockCFrame
						root.CFrame = self.lockCFrame
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
					elseif root and character then
						local expectedY = tonumber(character:GetAttribute("MachineStandHrpY"))
						if expectedY and root.Position.Y < expectedY - 0.15 then
							root.CFrame = root.CFrame + Vector3.new(0, expectedY - root.Position.Y, 0)
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
						end
					end
					RunService.PreRender:Wait()
				end
			end)
			startThread("fastFarmRebirth", function()
				while State.running and self.mode == mode and self.generation == generation do
					local ok, success = pcall(self.RunRebirthCycle, self, generation)
					if not ok then self.lastError = tostring(success) end
					self:CleanBootstrapTool()
					self:FinishRebirthCycle(ok and success and "confirmed" or self.lastError or "interrupted")
					if self.mode ~= mode or self.generation ~= generation then break end
					if not ok or not success then task.wait(0.75) end
				end
			end)
		else
			startThread("fastFarmStrength", function()
				setSizeOne()
				task.wait(0.3)
				unequipAllPets()
				self.packCount = equipSetup(self.strengthSetup, self.strengthPack)
				local pendingStats = readStats()
				self.lastStrengthSampleAt = realNow()
				self.lastStrengthSampleValue = pendingStats.strength
				if self:BootstrapToIndustrial(generation, mode) then
					FastFarm.AcquireStrengthMachine(generation)
				end
				setSizeOne()
				local lastStartCheck = 0
				local lastMachineAttempt = time()
				local lastCharacter = getCharacter()
				local lastStrengthValue = pendingStats.strength
				local lastStrengthGainAt = time()
				while State.running and self.mode == mode and self.generation == generation do
					if lastCharacter ~= getCharacter() then
						lastCharacter = getCharacter()
						self.startedAt = nil
						self.startStats = nil
						self.machine = nil
						self.machineSeat = nil
						self.machineDefinition = nil
						setSizeOne()
						task.wait(0.3)
						unequipAllPets()
						self.packCount = equipSetup(self.strengthSetup, self.strengthPack)
						pendingStats = readStats()
						lastStrengthValue = pendingStats.strength
						lastStrengthGainAt = time()
						if self:BootstrapToIndustrial(generation, mode) then
							FastFarm.AcquireStrengthMachine(generation)
						end
						setSizeOne()
						lastMachineAttempt = time()
					end
					local humanoid = getHumanoid()
					local machineReady = self.machine and self.machineSeat
						and machineIsActive(self.machine, self.machineSeat, humanoid)
					local currentStats = readStats()
					if currentStats.strength > lastStrengthValue then
						local sampleAt = realNow()
						local sampleDuration = sampleAt - (self.lastStrengthSampleAt or sampleAt)
						local sampleDelta = currentStats.strength
							- (self.lastStrengthSampleValue or lastStrengthValue)
						if sampleDuration >= 0.05 and sampleDuration <= 30 and sampleDelta > 0 then
							self.validStrengthSamples[#self.validStrengthSamples + 1] = {
								at = sampleAt,
								duration = sampleDuration,
								delta = sampleDelta,
							}
							if #self.validStrengthSamples > 12 then table.remove(self.validStrengthSamples, 1) end
						end
						self.lastStrengthSampleAt = sampleAt
						self.lastStrengthSampleValue = currentStats.strength
						lastStrengthValue = currentStats.strength
						lastStrengthGainAt = time()
					elseif machineReady and time() - lastStrengthGainAt >= 6.5 then
						local failedDefinition = self.machineDefinition
						if failedDefinition then
							self.machineFailureCooldowns[failedDefinition.instance or failedDefinition] = time() + 10
						end
						leaveMachine()
						self.machine = nil
						self.machineSeat = nil
						self.machineDefinition = nil
						machineReady = false
						lastStrengthGainAt = time()
					end
					if not machineReady and time() - lastMachineAttempt >= 1.2 then
						if self.machine or self.machineSeat then
							leaveMachine()
							self.machine = nil
							self.machineSeat = nil
							self.machineDefinition = nil
						end
						setSizeOne()
						if self:BootstrapToIndustrial(generation, mode) then
							FastFarm.AcquireStrengthMachine(generation)
						end
						setSizeOne()
						lastMachineAttempt = time()
					end
					local delay = adaptiveRepDelay("strength", self.machineSeat)
					if not self.startedAt and time() - lastStartCheck >= 0.15 then
						lastStartCheck = time()
						if currentStats.strength > pendingStats.strength then
							self.startedAt = realNow()
							self.startStats = pendingStats
						end
					end
					task.wait(delay)
				end
			end)
		end
		return true
	end
end



FarmTab:CreateDivider({text="Rebirth / Strength Rapido"})
local ffStrengthToggle = nil
local ffRebirthToggle = nil
FarmTab:CreateDropdown({
	Name = "Pack",
	Options = { "Auto", "Ultra Titanes", "Senores del Caos" },
	CurrentOption = "Auto",
	Callback = function(o)
		if o == "Ultra Titanes" then
			FastFarm.packMode = "ultra"
		elseif o == "Senores del Caos" then
			FastFarm.packMode = "chaos"
		else
			FastFarm.packMode = nil
		end
		local m = FastFarm.mode
		if m then
			FastFarm:Stop(true)
			if not FastFarm:Start(m) then
				Window:Notify({Title="La momoneta Hub", Content=tostring(FastFarm.lastError or "Sin pack"), Duration=3})
			end
		end
	end
})
ffRebirthToggle = FarmTab:CreateToggle({
	Name = "Fast Rebirth",
	CurrentValue = false,
	Flag = "FFFastRebirth",
	Callback = function(v)
		if v then
			if ffStrengthToggle then pcall(function() ffStrengthToggle:Set(false) end) end
			FastFarm.packMode = nil
			local ok = FastFarm:Start("rebirth")
			if not ok then
				pcall(function() ffRebirthToggle:Set(false) end)
				Window:Notify({Title="La momoneta Hub", Content=tostring(FastFarm.lastError or "No se pudo iniciar"), Duration=3})
			else
				Window:Notify({Title="La momoneta Hub", Content="Fast Rebirth ON", Duration=2})
			end
		else
			if FastFarm.mode == "rebirth" then FastFarm:Stop(true) end
			Window:Notify({Title="La momoneta Hub", Content="Fast Rebirth OFF", Duration=2})
		end
	end
})
FarmTab:CreateDivider({text="Calculadora"})
local ffStatusLabel = FarmTab:CreateText({Name="Estado: detenido"})
local ffPackLabel = FarmTab:CreateText({Name="Pack: -"})
local ffTimeLabel = FarmTab:CreateText({Name="Tiempo: 0d 0h 0m 0s"})
local ffCalcLabel = FarmTab:CreateText({Name="Calculadora: 0/h  •  0/d  •  0/w"})
local ffStrengthCounterLabel = FarmTab:CreateText({Name="Strength: 0"})
local ffRebirthCounterLabel = FarmTab:CreateText({Name="Rebirths: 0"})
local function ffElapsedText(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%dd %dh %dm %ds", days, hours, minutes, secs)
end
local ffSession = { key = nil, startedAt = 0, startStrength = 0, startRebirths = 0, samples = {}, lastValue = nil, lastAt = 0 }
task.spawn(function()
	while true do
		task.wait(0.5)
		local ok = pcall(function()
			local stats = FastFarm:ReadStats()
			local key = FastFarm.mode or (superRepOn and "super") or (fastRepOn and "fast") or nil
			if key ~= ffSession.key then
				ffSession.key = key
				ffSession.startedAt = os.clock()
				ffSession.startStrength = stats.strength
				ffSession.startRebirths = stats.rebirths
				ffSession.samples = {}
				ffSession.lastValue = stats.strength
				ffSession.lastAt = os.clock()
			end
			local strengthGain = 0
			local rebirthGain = 0
			if ffSession.key then
				if ffSession.key == "rebirth" then
					strengthGain = math.max(0, FastFarm.cycleStrengthGain or 0)
					rebirthGain = math.max(0, stats.rebirths - ffSession.startRebirths)
				else
					strengthGain = math.max(0, stats.strength - ffSession.startStrength)
					rebirthGain = math.max(0, stats.rebirths - ffSession.startRebirths)
				end
				-- muestras de fuerza para el ritmo (sirve a strength, super y fast)
				local now = os.clock()
				if stats.strength > (ffSession.lastValue or stats.strength) then
					local dur = math.max(0.05, now - (ffSession.lastAt or now))
					if dur <= 30 then
						ffSession.samples[#ffSession.samples + 1] = { duration = dur, delta = stats.strength - (ffSession.lastValue or stats.strength), at = now }
						if #ffSession.samples > 12 then table.remove(ffSession.samples, 1) end
					end
				end
				ffSession.lastValue = stats.strength
				ffSession.lastAt = now
			end
			pcall(function() ffStrengthCounterLabel:Set("Strength: " .. formatExact(stats.strength) .. " (+" .. formatExact(strengthGain) .. ")") end)
			pcall(function() ffRebirthCounterLabel:Set("Rebirths: " .. formatExact(stats.rebirths) .. " (+" .. formatExact(rebirthGain) .. ")") end)
			if ffSession.key then
				local elapsed = math.max(0, os.clock() - ffSession.startedAt)
				local status = ""
				if FastFarm.pingPaused then status = " (pausado)" end
				pcall(function() ffTimeLabel:Set("Tiempo: " .. ffElapsedText(elapsed) .. status) end)
				local rate = nil
				if ffSession.key == "rebirth" then
					rate = (tonumber(FastFarm.expectedRebirthDelta) or 0) / CONFIG.FastFarm.RateCycle * 3600
					if not (rate and rate > 0) then rate = nil end
				else
					if #ffSession.samples >= 3 then
						local totalDur, totalDelta = 0, 0
						for _, s in ipairs(ffSession.samples) do totalDur = totalDur + s.duration totalDelta = totalDelta + s.delta end
						if totalDur >= 2 and totalDelta > 0 then rate = totalDelta / totalDur * 3600 end
					end
					if rate == nil and elapsed >= 5 and strengthGain > 0 then
						rate = strengthGain / math.max(1, elapsed) * 3600
					end
				end
				if rate == nil then
					pcall(function() ffCalcLabel:Set("Calculadora: calibrando...") end)
				else
					local perHour = rate
					local perDay = perHour * 24
					pcall(function()
						ffCalcLabel:Set("Calculadora: " .. FastFarm:FormatCompact(perHour) .. "/h  •  " .. FastFarm:FormatCompact(perDay) .. "/d  •  " .. FastFarm:FormatCompact(perHour * 168) .. "/w")
					end)
				end
			else
				pcall(function() ffTimeLabel:Set("Tiempo: 0d 0h 0m 0s") end)
				pcall(function() ffCalcLabel:Set("Calculadora: 0/h  •  0/d  •  0/w") end)
			end
		end)
		if not ok then task.wait(1) end
	end
end)
local function ffDragonBusy()
	if FastFarm.mode ~= 'rebirth' then return false end
	local ph = FastFarm.phase
	return ph == 'rebirth_pack' or ph == 'cooldown' or ph == 'request' or ph == 'confirmation' or ph == 'pending'
end
task.spawn(function()
	while true do
		if FastFarm.mode == 'rebirth' and not ffDragonBusy() then
			applyRepTimeZero()
			local rc = LocalPlayer.Character
			local rh = rc and rc:FindFirstChildOfClass('Humanoid')
			if rh and rh.Health > 0 then
				local seat = getSeat(rh)
				local hasX2 = LocalPlayer:FindFirstChild('ownedGamepasses') and LocalPlayer.ownedGamepasses:FindFirstChild('x2 Rep Time')
				local effective = superRepInterval
				if hasX2 then effective = effective * 0.5 end
				for i = 1, superRepBatch do
					if FastFarm.mode ~= 'rebirth' or ffDragonBusy() then break end
					if seat then
						pcall(function() muscleEvent:FireServer('rep', seat) end)
					else
						pcall(function() muscleEvent:FireServer('rep') end)
					end
				end
				task.wait(effective)
			else
				task.wait(0.2)
			end
		else
			task.wait(0.25)
		end
	end
end)
task.spawn(function()
	while true do
		task.wait(1)
		if ffStatusLabel then
			if FastFarm.mode == "strength" then
				pcall(function()
					ffStatusLabel:Set("Estado: farmeando fuerza")
					ffPackLabel:Set("Pack: " .. tostring(FastFarm.packMode or "-") .. " | " .. tostring(FastFarm.machine and FastFarm.machine.Name or "-"))
				end)
			elseif FastFarm.mode == "rebirth" then
				pcall(function()
					ffStatusLabel:Set("Estado: ciclo rebirth #" .. tostring(FastFarm.cycleCount or 0) .. " OK:" .. tostring(FastFarm.successfulRebirths or 0))
					ffPackLabel:Set("Pack: " .. tostring(FastFarm.packMode or "-") .. " | " .. tostring(FastFarm.machine and FastFarm.machine.Name or "-"))
				end)
			else
				pcall(function()
					ffStatusLabel:Set("Estado: detenido")
					ffPackLabel:Set("Pack: -")
				end)
			end
		end
	end
end)

-- ============ PROTECCION BOSS RARE (solo boss rare, sin golem) ============
FarmTab:CreateDivider({text="Proteccion Pets"})
bossRareStatusLabel = FarmTab:CreateText({Name="Equipadas: 0 boss rare"})
local function rbCountBossRaras()
	local n = 0
	local folder = LocalPlayer:FindFirstChild("petsFolder")
	if folder then
		for _, cat in ipairs(folder:GetChildren()) do
			if cat:IsA("Folder") then
				for _, pet in ipairs(cat:GetChildren()) do
					if pet:IsA("StringValue") and isBossRara(pet) then
						n = n + 1
					end
				end
			end
		end
	end
	return n
end
local function rbCountBossRarasEquipped()
	local n = 0
	local eq = LocalPlayer:FindFirstChild("equippedPets")
	if eq then
		for _, slot in ipairs(eq:GetChildren()) do
			local ref = slot:FindFirstChild("petReference") or slot
			local pet = ref and ref:IsA("ObjectValue") and ref.Value or nil
			if pet and pet:IsA("StringValue") and isBossRara(pet) then
				n = n + 1
			end
		end
	end
	return n
end
local function refreshProtLabel()
	local eq = rbCountBossRarasEquipped()
	pcall(function() bossRareStatusLabel:Set('Equipadas: ' .. tostring(eq) .. ' boss rare') end)
	return eq
end

FarmTab:CreateToggle({
	Name = "No desequipar boss rare",
	CurrentValue = true,
	Flag = "ProtectBossRare",
	Callback = function(v)
		protectBossRareOn = v
		refreshProtLabel()
		Window:Notify({Title="La momoneta Hub", Content=v and "Boss rare protegidas" or "Boss rare sin proteccion", Duration=2})
	end
})
FarmTab:CreateButton({
	Name = "Contar equipadas",
	Callback = function()
		local eq = refreshProtLabel()
		Window:Notify({Title="La momoneta Hub", Content="Boss rare equipadas: " .. tostring(eq), Duration=2})
	end
})

-- Guardian: si el servidor/juego saca una boss rare (limite de slots, muerte,
-- rebirth, cambio de pj), la re-equipa sola sin tocar el pack de farmeo.
task.spawn(function()
	local remote = nil
	while true do
		task.wait(5)
		if not protectBossRareOn then continue end
		if remote == nil then
			local ev = ReplicatedStorage:FindFirstChild("rEvents")
			remote = ev and ev:FindFirstChild("equipPetEvent") or nil
		end
		local petsFolder = LocalPlayer:FindFirstChild("petsFolder")
		local equippedPets = LocalPlayer:FindFirstChild("equippedPets")
		if remote == nil or petsFolder == nil or equippedPets == nil then continue end
		-- junta boss rare no equipadas
		local equippedSet = {}
		for _, slot in ipairs(equippedPets:GetChildren()) do
			local ref = slot:FindFirstChild("petReference") or slot
			local pet = ref and ref:IsA("ObjectValue") and ref.Value or nil
			if pet then equippedSet[pet] = true end
		end
		local missing = {}
		for _, cat in ipairs(petsFolder:GetChildren()) do
			if cat:IsA("Folder") then
				for _, pet in ipairs(cat:GetChildren()) do
					if pet:IsA("StringValue") and isBossRara(pet) and not equippedSet[pet] then
						missing[#missing + 1] = pet
					end
				end
			end
		end
		if #missing == 0 then
			refreshProtLabel()
			continue
		end
		-- solo re-equipa si hay slot libre real; jamas saca otras para hacer hueco
		local cap = 0
		pcall(function() cap = FastFarm:GetPetSlotCapacity() end)
		local used = #equippedPets:GetChildren()
		local free = math.max(0, (tonumber(cap) or used) - used)
		if free < 1 then continue end
		table.sort(missing, function(a, b)
			return (tonumber(a:GetAttribute("MomentumSeconds")) or 0) > (tonumber(b:GetAttribute("MomentumSeconds")) or 0)
		end)
		for i = 1, math.min(free, #missing) do
			pcall(remote.FireServer, remote, "equipPet", missing[i])
			task.wait(0.15)
		end
		refreshProtLabel()
	end
end)


-- ============ BOSS (reemplazo Young0x ) ============
local Boss = {
	active = false,
	generation = 0,
	status = "Sin boss activo",
	originalPivot = nil,
	originalSize = 2,
	engagedBoss = nil,
	confirmedDamage = 0,
	attacks = 0,
	hitInterval = 0.31,
	antiLag = false,
	antiLagOriginals = {},
	antiLagConnection = nil,
	safeAttackPosition = nil,
	cameraFocusPosition = nil,
	cameraStableCFrame = nil,
	cameraSaved = nil,
	cameraRenderName = "MomonetaBossStableCamera",
	lastPlayerHealth = nil,
}

local bossThread = nil
local bossAntiLagOn = false
local bossStatusLabel = nil
local bossHealthLabel = nil
local bossToggle = nil

local function bossHealth()
	return math.max(0, tonumber(Workspace:GetAttribute("BossHealth")) or 0)
end

local function findBoss()
	for _, boss in ipairs(CollectionService:GetTagged("BossEventBoss")) do
		if boss and boss.Parent then
			local part = boss:FindFirstChild("BossDamageHitbox", true)
				or boss.PrimaryPart
				or boss:FindFirstChild("Boss", true)
				or boss:FindFirstChild("Head", true)
				or boss:FindFirstChildWhichIsA("BasePart", true)
			if part and part:IsA("BasePart") then
				local target = boss:FindFirstChild("Boss")
					or boss:FindFirstChild("Head", true)
					or boss.PrimaryPart
					or part
				if not target:IsA("BasePart") then target = part end
				return boss, part, target
			end
		end
	end
	return nil, nil, nil
end

local function setSize(size)
	size = math.clamp(math.floor((tonumber(size) or 2) + 0.5), 1, 100)
	if not changeSpeedSizeRemote then return false end
	if changeSpeedSizeRemote:IsA("RemoteEvent") then
		return pcall(changeSpeedSizeRemote.FireServer, changeSpeedSizeRemote, "changeSize", size)
	elseif changeSpeedSizeRemote:IsA("RemoteFunction") then
		return pcall(changeSpeedSizeRemote.InvokeServer, changeSpeedSizeRemote, "changeSize", size)
	end
	return false
end

local function readSize()
	local c = LocalPlayer.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local height = h and h:FindFirstChild("BodyHeightScale")
	return math.clamp(math.floor(((height and height.Value) or 2) + 0.5), 1, 100)
end

local function equipPunch()
	local c = LocalPlayer.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local bp = LocalPlayer:FindFirstChild("Backpack")
	local punch = c and c:FindFirstChild("Punch") or (bp and bp:FindFirstChild("Punch"))
	if punch and h and punch.Parent ~= c then
		pcall(h.EquipTool, h, punch)
		RunService.Heartbeat:Wait()
	end
	local at = punch and punch:FindFirstChild("attackTime")
	if at and at:IsA("ValueBase") then at.Value = 0 end
	return punch
end

function Boss:ApplyAntiLagObject(object)
	if not self.antiLag or not object then return end
	local prop = nil
	if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
		or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles")
		or object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight")
		or object:IsA("Highlight") then
		prop = "Enabled"
	elseif object:IsA("BasePart") then
		prop = "CastShadow"
	end
	if prop and self.antiLagOriginals[object] == nil then
		self.antiLagOriginals[object] = { property = prop, value = object[prop] }
		pcall(function() object[prop] = false end)
	end
end

function Boss:SetAntiLag(enabled)
	enabled = enabled == true
	self.antiLag = enabled
	if self.antiLagConnection then self.antiLagConnection:Disconnect() self.antiLagConnection = nil end
	if not enabled then
		for obj, saved in pairs(self.antiLagOriginals) do
			if obj and obj.Parent then pcall(function() obj[saved.property] = saved.value end) end
			self.antiLagOriginals[obj] = nil
		end
		return true
	end
	local events = Workspace:FindFirstChild("Events")
	local arena = events and events:FindFirstChild("BossArena")
	if not arena then self.antiLag = false return false end
	for _, o in ipairs(arena:GetDescendants()) do self:ApplyAntiLagObject(o) end
	self.antiLagConnection = arena.DescendantAdded:Connect(function(o)
		task.defer(function() self:ApplyAntiLagObject(o) end)
	end)
	return true
end

function Boss:StartStableCamera()
	pcall(RunService.UnbindFromRenderStep, RunService, self.cameraRenderName)
	local cam = Workspace.CurrentCamera
	if cam then
		self.cameraSaved = { cameraType = cam.CameraType, subject = cam.CameraSubject, cframe = cam.CFrame, focus = cam.Focus }
		cam.CameraType = Enum.CameraType.Scriptable
		RunService:BindToRenderStep(self.cameraRenderName, Enum.RenderPriority.Camera.Value + 50, function(delta)
			local focus = self.cameraFocusPosition
			local cur = Workspace.CurrentCamera
			if not self.engagedBoss or not focus or not cur then return end
			local desired = CFrame.lookAt(focus + Vector3.new(0, 34, 48), focus + Vector3.new(0, -5, 0))
			self.cameraStableCFrame = self.cameraStableCFrame
				and self.cameraStableCFrame:Lerp(desired, math.clamp(delta * 4, 0.04, 0.22)) or desired
			cur.CameraType = Enum.CameraType.Scriptable
			cur.CFrame = self.cameraStableCFrame
			cur.Focus = CFrame.new(focus)
		end)
	end
end

function Boss:StopStableCamera()
	pcall(RunService.UnbindFromRenderStep, RunService, self.cameraRenderName)
	local cam = Workspace.CurrentCamera
	local saved = self.cameraSaved
	if cam and saved then
		pcall(function()
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = saved.cframe
			cam.Focus = saved.focus
			if saved.subject and saved.subject.Parent then cam.CameraSubject = saved.subject end
			cam.CameraType = saved.cameraType
		end)
	end
	self.cameraSaved = nil
	self.cameraFocusPosition = nil
	self.cameraStableCFrame = nil
end

function Boss:UpdateUi()
	if bossStatusLabel then
		pcall(function() bossStatusLabel:Set("Estado: " .. self.status) end)
	end
	if bossHealthLabel then
		local h = bossHealth()
		local maxH = math.max(h, tonumber(Workspace:GetAttribute("BossMaxHealth")) or 0)
		if maxH > 0 and Workspace:GetAttribute("BossActive") == true then
			pcall(function() bossHealthLabel:Set("Vida: " .. tostring(math.floor(h)) .. " / " .. tostring(math.floor(maxH))) end)
		else
			pcall(function() bossHealthLabel:Set("Vida: --") end)
		end
	end
end

function Boss:WaitReady(timeout)
	local deadline = os.clock() + (tonumber(timeout) or 8)
	local sc, sr, sat = nil, nil, nil
	while self.active and os.clock() < deadline do
		local c = LocalPlayer.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		local machine = LocalPlayer:FindFirstChild("machineInUse")
		local rebirthing = c and (c:GetAttribute("IsRebirthing") == true or c:GetAttribute("LastMapCFrame") ~= nil)
		local mounted = (machine and machine.Value ~= nil) or (hum and hum.SeatPart ~= nil)
		if c and root and hum and hum.Health > 0 and not rebirthing and not mounted then
			if c ~= sc or root ~= sr then sc, sr, sat = c, root, os.clock()
			elseif os.clock() - sat >= 0.18 then return c, root, hum end
		else
			sc, sr, sat = nil, nil, nil
		end
		task.wait(0.05)
	end
	return nil, nil, nil
end

function Boss:BeginBattle(boss)
	if self.engagedBoss == boss then return true end
		if not fastPunch then
			self.status = 'Activa Fast Punch para el boss'
			self:UpdateUi()
			return false
		end
	local c, root = self:WaitReady(8)
	if not c or not root or boss.Parent == nil or Workspace:GetAttribute("BossActive") ~= true then
		self:RestoreBattle()
		return false
	end
	self.originalPivot = c:GetPivot()
	self.originalSize = readSize()
	self.engagedBoss = boss
	self.confirmedDamage = 0
	self.attacks = 0
	self.lastPlayerHealth = nil
	self.safeAttackPosition = nil
	self:StartStableCamera()
	setSize(5)
	task.wait(0.55)
	local hum = c:FindFirstChildOfClass("Humanoid")
	self.lastPlayerHealth = hum and hum.Health or nil
	if fastPunch ~= true then
		setFastPunch(true)
	end
	return true
end

function Boss:RestoreBattle()
	local c = LocalPlayer.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if c and root and self.originalPivot then
		pcall(function()
			c:PivotTo(self.originalPivot)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end
	if self.originalSize then setSize(self.originalSize) end
	self:StopStableCamera()
	local bp = LocalPlayer:FindFirstChild("Backpack")
	local punch = c and c:FindFirstChild("Punch")
	if punch and bp then punch.Parent = bp end
	self.engagedBoss = nil
	self.lastPlayerHealth = nil
	self.safeAttackPosition = nil
	self.originalPivot = nil
end

function Boss:CollectChest(timeout)
	if type(fireproximityprompt) ~= "function" then return false end
	local opened = false
	local openedConn = nil
	local rf = ReplicatedStorage:FindFirstChild("rEvents")
	local openedEvent = rf and rf:FindFirstChild("bossChestOpenedEvent")
	if openedEvent and openedEvent:IsA("RemoteEvent") then
		openedConn = openedEvent.OnClientEvent:Connect(function() opened = true end)
	end
	local function finish(ok)
		if openedConn then openedConn:Disconnect() end
		return ok
	end
	local deadline = os.clock() + (tonumber(timeout) or 12)
	local pendingWasSeen, attempted, lastAttempt = false, false, 0
	while self.active and os.clock() < deadline do
		if opened then return finish(true) end
		local chestModel, prompt = nil, nil
		for _, cand in ipairs(CollectionService:GetTagged("BossEventChest")) do
			local p = cand:FindFirstChild("bossChestPrompt", true)
			if p then chestModel = cand prompt = p break end
		end
		if not prompt then
			local events = Workspace:FindFirstChild("Events")
			prompt = events and events:FindFirstChild("bossChestPrompt", true)
			chestModel = prompt and prompt:FindFirstAncestorOfClass("Model") or nil
		end
		local eligible = LocalPlayer:GetAttribute("BossChestEligible") == true
		local pending = LocalPlayer:GetAttribute("BossChestPending") == true
		if pending then pendingWasSeen = true
		elseif attempted and pendingWasSeen then return finish(true) end
		local emerging = chestModel and chestModel:GetAttribute("BossChestEmerging") == true
		if prompt and prompt:IsA("ProximityPrompt") and eligible and pending and not emerging then
			local c = LocalPlayer.Character
			local root = c and c:FindFirstChild("HumanoidRootPart")
			local parent = prompt.Parent
			if c and root and parent and parent:IsA("BasePart") then
				c:PivotTo(parent.CFrame * CFrame.new(0, math.max(4, parent.Size.Y * 0.5 + 3), 0))
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				task.wait(0.12)
			end
			if prompt.Enabled and os.clock() - lastAttempt >= 0.45 then
				lastAttempt = os.clock()
				attempted = pcall(fireproximityprompt, prompt) or attempted
			end
		end
		task.wait(0.1)
	end
	return finish(opened or (attempted and pendingWasSeen and LocalPlayer:GetAttribute("BossChestPending") ~= true))
end

function Boss:Fight(boss)
	if not self:BeginBattle(boss) then return end
	local lastHealth = bossHealth()
	local lastAttack = 0
	while self.active and boss.Parent and Workspace:GetAttribute("BossActive") == true do
		if not fastPunch then
			self.status = 'Punch desactivado'
			self:UpdateUi()
			break
		end
		local curBoss, part, target = findBoss()
		if curBoss ~= boss or not part or not target then break end
		local c = LocalPlayer.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		local punch = equipPunch()
		if not c or not root or not hum or hum.Health <= 0 or not punch then
			self.status = "Esperando personaje"
			self:UpdateUi()
			task.wait(0.25)
		else
			if self.lastPlayerHealth and hum.Health < self.lastPlayerHealth then
				self.active = false
				self.status = "Proteccion activada (recibiste dano)"
				self:SetAntiLag(false)
				if bossToggle then pcall(function() bossToggle:Set(false) end) end
				self:UpdateUi()
				break
			end
			self.lastPlayerHealth = hum.Health
			local bossTop = target.Position.Y + target.Size.Y * 0.5
			local clearance = math.max(6, root.Size.Y * 0.5 + 4)
			local desiredPos = Vector3.new(part.Position.X, bossTop + clearance, part.Position.Z)
			if not self.safeAttackPosition or (desiredPos - self.safeAttackPosition).Magnitude > 45 then
				self.safeAttackPosition = desiredPos
			else
				self.safeAttackPosition = self.safeAttackPosition:Lerp(desiredPos, 0.16)
			end
			local attackPos = self.safeAttackPosition
			local aimPos = target.Position + Vector3.new(0, target.Size.Y * 0.32, 0)
			self.cameraFocusPosition = self.cameraFocusPosition
				and self.cameraFocusPosition:Lerp(aimPos, 0.08) or aimPos
			c:PivotTo(CFrame.lookAt(attackPos, aimPos))
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			local now = os.clock()
			if now - lastAttack >= self.hitInterval then
				lastAttack = now
				pcall(punch.Deactivate, punch)
				pcall(punch.Activate, punch)
				self.attacks = self.attacks + 1
			end
			local h = bossHealth()
			if h < lastHealth then self.confirmedDamage = self.confirmedDamage + lastHealth - h end
			lastHealth = h
			self.status = tostring(Workspace:GetAttribute("BossDisplayName") or "Boss") .. " - dano " .. tostring(math.floor(self.confirmedDamage))
			self:UpdateUi()
			task.wait(0.04)
		end
	end
	local defeated = Workspace:GetAttribute("BossActive") ~= true or bossHealth() <= 0
	if defeated and self.active then
		self.status = "Boss derrotado - reclamando recompensa"
		self:UpdateUi()
		self:CollectChest(12)
	end
	self:RestoreBattle()
end

function Boss:Set(enabled)
	enabled = enabled == true
	self.generation = self.generation + 1
	local gen = self.generation
	self.active = enabled
	if bossThread then task.cancel(bossThread) bossThread = nil end
	if not enabled then
		self.status = "Sin boss activo"
		self:RestoreBattle()
		self:SetAntiLag(false)
		self:UpdateUi()
		return true
	end
	local shared = ReplicatedStorage:FindFirstChild("shared")
	local cfg = shared and shared:FindFirstChild("config")
	local bossCfg = cfg and cfg:FindFirstChild("BossEventConfig")
	local ok, values = pcall(function() return bossCfg and require(bossCfg) end)
	if not ok or type(values) ~= "table" or values.ENABLED ~= true then
		self.active = false
		self.status = "El evento del boss no esta disponible"
		self:SetAntiLag(false)
		self:UpdateUi()
		return false
	end
	local strStat = getPlayerStat(LocalPlayer, { 'Strength' })
	local strVal = strStat and tonumber(strStat.Value) or 0
	if strVal <= 0 then
		self.active = false
		self.status = 'Consegui fuerza primero (tenes 0)'
		self:SetAntiLag(false)
		self:UpdateUi()
		return false
	end
	self:SetAntiLag(bossAntiLagOn == true)
	self.hitInterval = math.max(0.31, (tonumber(values.MIN_HIT_INTERVAL) or 0.3) + 0.01)
	bossThread = task.spawn(function()
		while Boss.active and Boss.generation == gen do
			local boss = findBoss()
			if boss and Workspace:GetAttribute("BossActive") == true then
				Boss:Fight(boss)
			else
				Boss.engagedBoss = nil
				Boss.status = "Sin boss activo"
				Boss:UpdateUi()
				task.wait(0.4)
			end
		end
		if Boss.generation == gen then Boss:RestoreBattle() end
	end)
	self:UpdateUi()
	return true
end

FarmTab:CreateDivider({text="Boss Hit"})
bossStatusLabel = FarmTab:CreateText({Name="Estado: Sin boss activo"})
bossHealthLabel = FarmTab:CreateText({Name="Vida: --"})
bossToggle = FarmTab:CreateToggle({
	Name = "Boss - Atacar al boss",
	CurrentValue = false,
	Flag = "Boss",
	Callback = function(v)
		local ok = Boss:Set(v)
		if ok == false then
			if bossToggle then pcall(function() bossToggle:Set(false) end) end
		end
		Window:Notify({Title="La momoneta Hub", Content=v and "Boss ON" or "Boss OFF", Duration=2})
	end
})
FarmTab:CreateToggle({
	Name = "Boss Anti-Lag",
	CurrentValue = false,
	Flag = "BossAntiLag",
	Callback = function(v)
		bossAntiLagOn = v
		Boss:SetAntiLag(v and Boss.active)
		Window:Notify({Title="La momoneta Hub", Content=v and "Boss Anti-Lag ON" or "Boss Anti-Lag OFF", Duration=2})
	end
})


-- ============ ISLANDS INFO + TELEPORTS ============
local islands = {
	{"Tiny Island","Strength: 0",false,false},{"Beach","Strength: 0",false,false},
	{"Frost Gym","Rebirths: 1",false,true},{"Eternal Gym","Rebirths: 5",false,true},
	{"Mythical Gym","Rebirths: 5",false,true},{"Muscle King","Rebirths: 5",false,true},
	{"Legends Gym","Rebirths: 30",false,true},{"Jungle Gym","Rebirths: 60",false,true},
	{"Industrial Gym","Rebirths: 150",false,true},{"Battle Island","Strength: 0",true,false}
}
TravelTab:CreateDivider({text="Islands"})
for _,i in ipairs(islands) do
	TravelTab:CreateText({Name=i[1].." ("..i[2]..")", Description="Farm: "..(i[3] and "Enemies" or (i[4] and "Machines" or "None"))})
end
local curInfo = TravelTab:CreateText({Name="Current: "..currentMap.Value})
currentMap.Changed:Connect(function() curInfo:Set("Current: "..currentMap.Value) end)

TravelTab:CreateDivider({text="Teleports - toca para viajar"})
local teleportSpots = {
	{"Tiny Gym", Vector3.new(50, 7, 1918)},
	{"Beach", Vector3.new(9, 7, 100)},
	{"Frost Gym", Vector3.new(-2650, 7, -393)},
	{"Mythical Gym", Vector3.new(2255, 7, 1071)},
	{"Eternal Gym", Vector3.new(-6768, 7, -1287)},
	{"Legends Gym", Vector3.new(4429, 991, -3880)},
	{"Muscle King", Vector3.new(-8799, 17, -5798)},
	{"Jungle Gym", Vector3.new(-7894, 6, 2386)},
	{"Industrial Gym", Vector3.new(-5165, 57, 4945)},
	{"Secret Area", Vector3.new(1947, 2, 6191)},
	{"Desert Brawl", Vector3.new(960, 17, -7398)},
	{"Lava Brawl", Vector3.new(4471, 119, -8836)},
}
local function safeTeleport(pos)
	local c = LocalPlayer.Character
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
	task.wait(0.3)
	if hrp and hrp.Parent then
		hrp.CFrame = CFrame.new(pos)
	end
end
for _, spot in ipairs(teleportSpots) do
	TravelTab:CreateButton({
		Name = "Ir a " .. spot[1],
		Callback = function()
			safeTeleport(spot[2])
			Window:Notify({Title="La momoneta Hub", Content="Teleported a " .. spot[1], Duration=2})
		end
	})
end

-- ============ PET SHOP + GIFTS ============
local cPetShopRemote = ReplicatedStorage.rEvents:FindFirstChild("cPetShopRemote")
local gemShopFolder = ReplicatedStorage.shared and ReplicatedStorage.shared.runtime and ReplicatedStorage.shared.runtime:FindFirstChild("cPetShopFolder")
local giftRemote = ReplicatedStorage.rEvents:FindFirstChild("giftRemote")

local function playerList()
	local out = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(out, p.Name) end
	end
	table.sort(out)
	return out
end

-- Options must be STRINGS for Rayfield. Keep name->version maps to buy by name.
local petsList, aurasList = {}, {}
local petMap, auraMap = {}, {}
if gemShopFolder then
	for _, it in pairs(gemShopFolder:GetChildren()) do
		if it:IsA("Instance") then
			local price = it:GetAttribute("Price")
			local ptype = it:GetAttribute("PriceType")
			local rarity = it:GetAttribute("Rarity") or "?"
			if typeof(price) == "number" then
				local lbl = string.format("%s | %s", it.Name, tostring(price))
				if it:GetAttribute("IsPowerUp") == true then
					aurasList[#aurasList + 1] = lbl
					auraMap[lbl] = it
				else
					petsList[#petsList + 1] = lbl
					petMap[lbl] = it
				end
			end
		end
	end
	table.sort(petsList)
	table.sort(aurasList)
end

local function buyItem(name)
	local item = petMap[name] or auraMap[name]
	if not item or not cPetShopRemote then return false end
	local ok = pcall(function() cPetShopRemote:InvokeServer(item) end)
	return ok
end

ShopTab:CreateDivider({text="🐾 Pet Shop 🐾"})
ShopTab:CreateText({Name="Tienda: "..#petsList.." pets / "..#aurasList.." auras"})

local selPet = petsList[1]
if #petsList > 0 then
	ShopTab:CreateDropdown({
		Name = "Seleccionar Pet",
		Options = petsList,
		CurrentOption = selPet,
		Callback = function(o) selPet = o end
	})
end
ShopTab:CreateButton({
	Name = "Comprar Pet",
	Callback = function()
		local ok = buyItem(selPet)
		Window:Notify({Title="La momoneta Hub", Content=(ok and "Comprado: " or "No se pudo: ")..(selPet or ""), Duration=3})
	end
})
local autoBuyPet = false
ShopTab:CreateToggle({
	Name = "Auto Comprar Pet",
	CurrentValue = false,
	Flag = "AutoBuyPet",
	Callback = function(v)
		autoBuyPet = v
		if v then task.spawn(function()
			while autoBuyPet do buyItem(selPet) task.wait(0.2) end
		end) end
	end
})

ShopTab:CreateDivider({text="🌌 Auras 🌌"})
local selAura = aurasList[1]
if #aurasList > 0 then
	ShopTab:CreateDropdown({
		Name = "Seleccionar Aura",
		Options = aurasList,
		CurrentOption = selAura,
		Callback = function(o) selAura = o end
	})
end
ShopTab:CreateButton({
	Name = "Comprar Aura",
	Callback = function()
		local ok = buyItem(selAura)
		Window:Notify({Title="La momoneta Hub", Content=(ok and "Comprado: " or "No se pudo: ")..(selAura or ""), Duration=3})
	end
})
local autoBuyAura = false
ShopTab:CreateToggle({
	Name = "Auto Comprar Aura",
	CurrentValue = false,
	Flag = "AutoBuyAura",
	Callback = function(v)
		autoBuyAura = v
		if v then task.spawn(function()
			while autoBuyAura do buyItem(selAura) task.wait(0.2) end
		end) end
	end
})

ShopTab:CreateDivider({text="🎁 Gifts 🎁"})
ShopTab:CreateText({Name="Regalos entre jugadores"})
local selPlayer = playerList()[1]
local list = playerList()
if #list > 0 then
	ShopTab:CreateDropdown({
		Name = "Jugador",
		Options = list,
		CurrentOption = selPlayer,
		Callback = function(o) selPlayer = o end
	})
end

local eggCount = 1
ShopTab:CreateSlider({Name="Cantidad Protein Egg", Range={1,50}, Increment=1, CurrentValue=1, Flag="GiftEggs", Callback=function(v) eggCount=v end})

local giftBusy = false
local function sendGift(kind, count)
	if giftBusy then return end
	if not selPlayer then
		Window:Notify({Title="La momoneta Hub", Content="Selecciona un jugador", Duration=2})
		return
	end
	local tp = Players:FindFirstChild(selPlayer)
	if not tp then
		Window:Notify({Title="La momoneta Hub", Content="Jugador no disponible", Duration=2})
		return
	end
	if not giftRemote then
		Window:Notify({Title="La momoneta Hub", Content="Remote de regalo no disponible", Duration=2})
		return
	end
	giftBusy = true
	local cf = LocalPlayer:FindFirstChild("consumablesFolder")
	local sent = 0
	for _ = 1, count do
		local item
		if cf then
			for _, c in pairs(cf:GetChildren()) do
				if c:IsA("StringValue") and c.Name == kind then item = c break end
			end
		end
		if not item then break end
		pcall(function() giftRemote:InvokeServer("giftRequest", tp, item) end)
		sent = sent + 1
		task.wait(0.12)
		if math.random() < 0.2 then task.wait(0.4) end
	end
	giftBusy = false
	Window:Notify({Title="La momoneta Hub", Content=string.format("Enviados %d %s", sent, kind), Duration=3})
end

ShopTab:CreateButton({
	Name = "Enviar Protein Egg",
	Callback = function() sendGift("Protein Egg", eggCount) end
})
local shakeCount = 1
ShopTab:CreateSlider({Name="Cantidad Tropical Shake", Range={1,50}, Increment=1, CurrentValue=1, Flag="GiftShakes", Callback=function(v) shakeCount=v end})
ShopTab:CreateButton({
	Name = "Enviar Tropical Shake",
	Callback = function() sendGift("Tropical Shake", shakeCount) end
})

-- ============ MISC ============
local MiscTab = Window:CreateTab({ name = "Misc" })

-- Anti Lag
local antiLagOn = false
local lagSaved = {}
local function setAntiLag(on)
	antiLagOn = on
	if on then
		if next(lagSaved) == nil then
			lagSaved = { GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd, Brightness = Lighting.Brightness }
		end
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1000000000
		Lighting.Brightness = 0
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
	else
		if next(lagSaved) ~= nil then
			for k, v in pairs(lagSaved) do pcall(function() Lighting[k] = v end) end
		end
	end
end
MiscTab:CreateToggle({ Name="Anti Lag", CurrentValue=false, Flag="AntiLag", Callback=function(v) setAntiLag(v) end })

-- Fly
local flyOn = false
local flyGyro, flyVel = nil, nil
local function setFly(on)
	flyOn = on
	local c = LocalPlayer.Character
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not on then
		if flyGyro then flyGyro:Destroy() flyGyro=nil end
		if flyVel then flyVel:Destroy() flyVel=nil end
		if h then h.PlatformStand = false end
		return
	end
	if not hrp then return end
	flyGyro = Instance.new("BodyGyro")
	flyGyro.P = 12000
	flyGyro.MaxTorque = Vector3.new(9000000000,9000000000,9000000000)
	flyGyro.Parent = hrp
	flyVel = Instance.new("BodyVelocity")
	flyVel.P = 15000
	flyVel.MaxForce = Vector3.new(9000000000,9000000000,9000000000)
	flyVel.Parent = hrp
	if h then h.PlatformStand = true end
end
RunService.Heartbeat:Connect(function()
	if flyOn and flyGyro and flyVel then
		local cam = Workspace.CurrentCamera
		local c = LocalPlayer.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if cam and hrp and h then
			flyGyro.CFrame = cam.CFrame
			local dir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
			local up = 0
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = 1 end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then up = -1 end
			local speed = 160
			if dir.Magnitude > 0 then dir = dir.Unit end
			flyVel.Velocity = dir * speed + Vector3.new(0, up*speed, 0)
		end
	end
end)
MiscTab:CreateToggle({ Name="Fly", CurrentValue=false, Flag="Fly", Callback=function(v) setFly(v) end })

-- Fast Speed
local fastSpeedOn = false
local savedWalkSpeed = nil
MiscTab:CreateToggle({ Name="Fast Speed", CurrentValue=false, Flag="FastSpeed", Callback=function(v)
	fastSpeedOn = v
	local c = LocalPlayer.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if h then
		if v then
			savedWalkSpeed = savedWalkSpeed or h.WalkSpeed
			h.WalkSpeed = 1000
		else
			h.WalkSpeed = savedWalkSpeed or 16
			savedWalkSpeed = nil
		end
	end
end })

-- Walk on Water
local walkWaterOn = false
local waterFloor = nil
local waterConn = nil
local function setWalkWater(on)
	walkWaterOn = on
	if waterConn then waterConn:Disconnect() waterConn=nil end
	if waterFloor then waterFloor:Destroy() waterFloor=nil end
	if not on then return end
	waterFloor = Instance.new("Part")
	waterFloor.Name = "MomWaterFloor"
	waterFloor.Size = Vector3.new(2048,1,2048)
	waterFloor.Anchored = true
	waterFloor.CanCollide = true
	waterFloor.CanTouch = false
	waterFloor.CanQuery = false
	waterFloor.Transparency = 1
	waterFloor.CastShadow = false
	waterFloor.Parent = Workspace
	waterConn = RunService.Heartbeat:Connect(function()
		if not walkWaterOn or not waterFloor or not waterFloor.Parent then return end
		local c = LocalPlayer.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if hrp then
			waterFloor.Position = Vector3.new(math.floor(hrp.Position.X/256+0.5)*256, -9.5, math.floor(hrp.Position.Z/256+0.5)*256)
		end
	end)
end
MiscTab:CreateToggle({ Name="Walk on Water", CurrentValue=false, Flag="WalkWater", Callback=function(v) setWalkWater(v) end })

-- No Clip
local noclipOn = false
local savedCollide = {}
local function setNoclip(on)
	noclipOn = on
	local c = LocalPlayer.Character
	if not on then
		for part, orig in pairs(savedCollide) do
			if part and part.Parent then part.CanCollide = orig end
		end
		table.clear(savedCollide)
		return
	end
	if c then
		for _, part in ipairs(c:GetDescendants()) do
			if part:IsA("BasePart") then
				if savedCollide[part] == nil then savedCollide[part] = part.CanCollide end
				part.CanCollide = false
			end
		end
	end
end
MiscTab:CreateToggle({ Name="No Clip", CurrentValue=false, Flag="Noclip", Callback=function(v) setNoclip(v) end })

-- Anti Knockback
local antiKbOn = false
local kbVel = nil
MiscTab:CreateToggle({ Name="Anti Knockback", CurrentValue=false, Flag="AntiKb", Callback=function(v)
	antiKbOn = v
	if not v then
		if kbVel then kbVel:Destroy() kbVel=nil end
		return
	end
	local c = LocalPlayer.Character
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	kbVel = Instance.new("BodyVelocity")
	kbVel.P = 25000
	kbVel.MaxForce = Vector3.new(1000000000, 0, 1000000000)
	kbVel.Parent = hrp
end })

-- Spin
local spinOn = false
local spinPart = nil
local spinAutoRotate = nil
MiscTab:CreateToggle({ Name="Spin", CurrentValue=false, Flag="Spin", Callback=function(v)
	spinOn = v
	if not v then
		if spinPart then spinPart:Destroy() spinPart=nil end
		local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if h and spinAutoRotate ~= nil then h.AutoRotate = spinAutoRotate end
		return
	end
	local c = LocalPlayer.Character
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not hrp then return end
	spinAutoRotate = h and h.AutoRotate
	if h then h.AutoRotate = false end
	spinPart = Instance.new("BodyAngularVelocity")
	spinPart.AngularVelocity = Vector3.new(0,7,0)
	spinPart.MaxTorque = Vector3.new(0,9000000000,0)
	spinPart.P = 6000
	spinPart.Parent = hrp
end })

-- Infinite Jump
local infJumpOn = false
UserInputService.JumpRequest:Connect(function()
	if infJumpOn then
		local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)
MiscTab:CreateToggle({ Name="Infinite Jump", CurrentValue=false, Flag="InfiniteJump", Callback=function(v) infJumpOn=v end })

-- FullBright
local fullBrightOn = false
local fbSaved = {}
MiscTab:CreateToggle({ Name="FullBright", CurrentValue=false, Flag="FullBright", Callback=function(v)
	fullBrightOn = v
	if v then
		if next(fbSaved)==nil then fbSaved = {ClockTime=Lighting.ClockTime, Brightness=Lighting.Brightness, Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, GlobalShadows=Lighting.GlobalShadows} end
		Lighting.ClockTime = 14
		Lighting.Brightness = 3
		Lighting.Ambient = Color3.fromRGB(178,178,178)
		Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
		Lighting.GlobalShadows = false
	else
		if next(fbSaved)~=nil then
			for k,val in pairs(fbSaved) do pcall(function() Lighting[k]=val end) end
		end
	end
end })

-- No Fog
local noFogOn = false
local fogSaved = {}
MiscTab:CreateToggle({ Name="Quitar Niebla", CurrentValue=false, Flag="NoFog", Callback=function(v)
	noFogOn = v
	if v then
		if next(fogSaved)==nil then fogSaved = {FogStart=Lighting.FogStart, FogEnd=Lighting.FogEnd, FogColor=Lighting.FogColor} end
		Lighting.FogStart = 100000
		Lighting.FogEnd = 1000000
	else
		if next(fogSaved)~=nil then
			for k,val in pairs(fogSaved) do pcall(function() Lighting[k]=val end) end
		end
	end
end })

-- FOV
local fovVal = 70
local fovOn = false
local fovSaved = nil
local function applyFov()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if fovOn then
		if not fovSaved then fovSaved = cam.FieldOfView end
		cam.FieldOfView = fovVal
	else
		if fovSaved then cam.FieldOfView = fovSaved end
		fovSaved = nil
	end
end
MiscTab:CreateSlider({ Name="FOV", Range={40,120}, Increment=1, CurrentValue=70, Flag="FOV", Callback=function(v) fovVal=v if fovOn then applyFov() end end })
MiscTab:CreateToggle({ Name="Aplicar FOV", CurrentValue=false, Flag="FOVToggle", Callback=function(v) fovOn=v applyFov() end })

-- Zoom
local zoomOn = false
local savedZoom = nil
MiscTab:CreateToggle({ Name="Zoom extendido", CurrentValue=false, Flag="Zoom", Callback=function(v)
	zoomOn = v
	if v then
		savedZoom = savedZoom or LocalPlayer.CameraMaxZoomDistance
		LocalPlayer.CameraMaxZoomDistance = 100000
	else
		if savedZoom then LocalPlayer.CameraMaxZoomDistance = savedZoom end
		savedZoom = nil
	end
end })

-- Click TP
local clickTpOn = false
UserInputService.InputBegan:Connect(function(input, gpe)
	if clickTpOn and not gpe and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local cam = Workspace.CurrentCamera
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if cam and hrp then
			local ray = cam:ScreenPointToRay(input.Position.X, input.Position.Y)
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = {LocalPlayer.Character}
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.IgnoreWater = true
			local hit = Workspace:Raycast(ray.Origin, ray.Direction*100000, params)
			if hit then
				hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end)
MiscTab:CreateToggle({ Name="Click TP", CurrentValue=false, Flag="ClickTP", Callback=function(v) clickTpOn=v end })

-- Hide Players
local hidePlayersOn = false
MiscTab:CreateToggle({ Name="Ocultar Jugadores", CurrentValue=false, Flag="HidePlayers", Callback=function(v)
	hidePlayersOn = v
	if not v then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				for _, part in ipairs(p.Character:GetDescendants()) do
					if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 end
				end
			end
		end
		return
	end
	task.spawn(function()
		while hidePlayersOn do
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character then
					for _, part in ipairs(p.Character:GetDescendants()) do
						if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end })

-- Hide Pets
local hidePetsOn = false
local function isPetModel(m)
	return m:IsA("Model") and m:FindFirstChild("petMovementScript", true) ~= nil
end
local function setAllPetsTransparency(val)
	for _, m in ipairs(Workspace:GetDescendants()) do
		if isPetModel(m) then
			for _, part in ipairs(m:GetDescendants()) do
				if part:IsA("BasePart") then part.LocalTransparencyModifier = val end
			end
		end
	end
end
MiscTab:CreateToggle({ Name="Ocultar Pets", CurrentValue=false, Flag="HidePets", Callback=function(v)
	hidePetsOn = v
	if not v then setAllPetsTransparency(0) return end
	task.spawn(function()
		while hidePetsOn do
			setAllPetsTransparency(1)
			task.wait(0.5)
		end
	end)
end })

-- FPS Unlock
MiscTab:CreateToggle({ Name="FPS Unlock", CurrentValue=false, Flag="FpsUnlock", Callback=function(v)
	if v then pcall(function() setfpscap(0) end)
	else pcall(function() setfpscap(60) end) end
end })

-- Headless
local headlessOn = false
MiscTab:CreateToggle({ Name="Headless", CurrentValue=false, Flag="Headless", Callback=function(v)
	headlessOn = v
	local c = LocalPlayer.Character
	if not c then return end
	local head = c:FindFirstChild("Head")
	if head then head.LocalTransparencyModifier = v and 1 or 0 end
end })

-- Day/Night
MiscTab:CreateDropdown({ Name="Dia/Noche", Options={"Day","Night"}, CurrentOption="Day", Callback=function(o)
	if o == "Night" then Lighting.ClockTime = 0 else Lighting.ClockTime = 14 end
end })

-- Fortune Wheel
local openFortuneWheelRemote = ReplicatedStorage.rEvents:FindFirstChild("openFortuneWheelRemote")
local fortuneChances = ReplicatedStorage.shared and ReplicatedStorage.shared.catalogs and ReplicatedStorage.shared.catalogs:FindFirstChild("fortuneWheelChances")
MiscTab:CreateButton({ Name="Girar Fortuna", Callback=function()
	local wheel = fortuneChances and fortuneChances:FindFirstChild("Fortune Wheel")
	if openFortuneWheelRemote and wheel then
		pcall(function() openFortuneWheelRemote:InvokeServer("openFortuneWheel", wheel) end)
	end
end })

-- Remove AD Portal
local removePortalOn = false
local portalConn = nil
local function setRemovePortal(on)
	removePortalOn = on
	if portalConn then portalConn:Disconnect() portalConn=nil end
	if on then
		portalConn = Workspace.DescendantAdded:Connect(function(o)
			if o.Name == "RobloxForwardPortals" and o.Parent then o.Parent = nil end
		end)
		for _, o in ipairs(Workspace:GetDescendants()) do
			if o.Name == "RobloxForwardPortals" and o.Parent then o.Parent = nil end
		end
	end
end
MiscTab:CreateToggle({ Name="Quitar Portal AD", CurrentValue=false, Flag="RemovePortal", Callback=function(v) setRemovePortal(v) end })

Window:Notify({Title="La momoneta Hub", Content="Loaded", Duration=4})
