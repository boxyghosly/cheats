if not game:IsLoaded() then game.Loaded:Wait() end
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local cloneref = cloneref or function(x) return x end

local running = true
local connections, restorers = {}, {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end
	local notify

local repo = "https://raw.githubusercontent.com/boxyghosly/cheats/main/"

local function fetch(name)
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(repo .. name))()
	end)
	if ok then return result end
	return nil
end

local Library = fetch("Library.lua")
local ThemeManager = fetch("ThemeManager.lua")
local SaveManager = fetch("SaveManager.lua")

if not (Library and ThemeManager and SaveManager) then
	warn("Failed to load library files - check the repo URL and that Library.lua, ThemeManager.lua and SaveManager.lua are uploaded.")
	return
end

local Options = getgenv().Options
local Toggles = getgenv().Toggles

notify = function(message)
	Library:Notify(tostring(message), 5)
end

local Window = Library:CreateWindow({
	Title = "My UI",
	Center = true,
	AutoShow = true,
	Resizable = true,
	TabPadding = 8,
	MenuFadeTime = 0.2,
	MinSize = Vector2.new(470, 380),
	MaxSize = Vector2.new(740, 720),
})

local Tabs = {
	Main = Window:AddTab("Main"),
	Visuals = Window:AddTab("Visuals"),
	Spoofer = Window:AddTab("Spoofer"),
	Misc = Window:AddTab("Misc"),
	["UI Settings"] = Window:AddTab("UI Settings"),
}

-- Main tab
local LeftGroup = Tabs.Main:AddLeftGroupbox("Left groupbox")
local RightGroup = Tabs.Main:AddRightGroupbox("Right groupbox")

LeftGroup:AddToggle("MasterToggle", {
	Text = "Enable feature",
	Default = false,
	Callback = function(Value)
		print("[cb] MasterToggle:", Value)
	end,
})

local Depbox = LeftGroup:AddDependencyBox()
Depbox:AddSlider("ExampleSlider", {
	Text = "Example slider",
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		print("[cb] ExampleSlider:", Value)
	end,
})
Depbox:SetupDependencies({
	{ Toggles.MasterToggle, true },
})

LeftGroup:AddDivider()

LeftGroup:AddLabel("Keybind example"):AddKeyPicker("ExampleKeybind", {
	Default = "MB2",
	Mode = "Toggle",
	Text = "Example keybind",
	NoUI = false,
	Callback = function(Value)
		print("[cb] ExampleKeybind:", Value)
	end,
})

RightGroup:AddDropdown("ExampleDropdown", {
	Text = "Example dropdown",
	Values = { "Option 1", "Option 2", "Option 3" },
	Default = 1,
	Callback = function(Value)
		print("[cb] ExampleDropdown:", Value)
	end,
})

RightGroup:AddInput("ExampleInput", {
	Text = "Example input",
	Default = "",
	Placeholder = "Type here...",
	Finished = true,
	Callback = function(Value)
		print("[cb] ExampleInput:", Value)
	end,
})

RightGroup:AddDivider()

RightGroup:AddButton({
	Text = "Example button",
	Func = function()
		Library:Notify("Button pressed")
	end,
})

-- Visuals tab (tabbox example)
local TabBox = Tabs.Visuals:AddLeftTabbox()
local Tab1 = TabBox:AddTab("Tab 1")
local Tab2 = TabBox:AddTab("Tab 2")

Tab1:AddToggle("Tab1Toggle", {
	Text = "Tab 1 toggle",
	Default = false,
	Callback = function(Value)
		print("[cb] Tab1Toggle:", Value)
	end,
})

Tab2:AddToggle("Tab2Toggle", {
	Text = "Tab 2 toggle",
	Default = false,
	Callback = function(Value)
		print("[cb] Tab2Toggle:", Value)
	end,
})

local VisualsRight = Tabs.Visuals:AddRightGroupbox("Visuals right")
VisualsRight:AddLabel("Placeholder groupbox. Add your controls here.", true)

-- Spoofer tab: local outfit preview
local SpooferLeft = Tabs.Spoofer:AddLeftGroupbox("Avatar outfit")
local cfg = { avatar=false, userId=lp.UserId }
local refreshProfileImages = function() end

local backups = setmetatable({}, { __mode = "k" })
local generations = setmetatable({}, { __mode = "k" })
local rigs = {}

local function clothing(obj)
	return obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors")
end

local function restoreCharacter(char)
	local saved = backups[char]
	if not saved then return end
	for _, obj in ipairs(saved.added) do pcall(function() obj:Destroy() end) end
	for _, entry in ipairs(saved.removed) do
		if entry.parent and entry.parent.Parent then pcall(function() entry.object.Parent = entry.parent end) end
	end
	if char.Parent then
		for part, color in pairs(saved.colors) do if part.Parent then pcall(function() part.Color = color end) end end
	end
	backups[char] = nil
end

local function outfit(char, userId)
	generations[char] = (generations[char] or 0) + 1
	local generation = generations[char]
	restoreCharacter(char)
	if not userId then return end
	task.spawn(function()
		local rig = rigs[userId]
		if not rig then
			local ok, value = pcall(function()
				return Players:CreateHumanoidModelFromUserId(userId)
			end)
			if not ok then if running then notify("Avatar preview unavailable: " .. tostring(value)) end; return end
			rig = value
			if not running then pcall(function() rig:Destroy() end); return end
			if rigs[userId] then pcall(function() rig:Destroy() end); rig = rigs[userId] else rigs[userId] = rig end
		end
		if not running or not char.Parent or generations[char] ~= generation then return end
		task.wait()
		local saved = { removed = {}, added = {}, colors = {} }
		backups[char] = saved
		for _, obj in ipairs(char:GetChildren()) do
			if clothing(obj) then saved.removed[#saved.removed + 1] = { object = obj, parent = char }; obj.Parent = nil end
			if obj:IsA("BasePart") then saved.colors[obj] = obj.Color end
		end
		local head = char:FindFirstChild("Head") or char:FindFirstChild("HitboxHead")
		local sourceHead = rig:FindFirstChild("Head")
		if head and sourceHead then
			for _, obj in ipairs(head:GetChildren()) do
				if obj:IsA("Decal") or obj:IsA("SurfaceAppearance") or obj:IsA("SpecialMesh") or obj:IsA("Texture") then
					saved.removed[#saved.removed + 1] = { object = obj, parent = head }; obj.Parent = nil
				end
			end
		end
		for _, obj in ipairs(rig:GetChildren()) do
			if clothing(obj) then
				local copy = obj:Clone()
				for _, part in ipairs(copy:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false; part.Massless = true end
				end
				copy.Parent = char
				saved.added[#saved.added + 1] = copy
				if copy:IsA("Accessory") then
					local handle = copy:FindFirstChild("Handle")
					if handle then
						local old = handle:FindFirstChild("AccessoryWeld"); if old then old:Destroy() end
						local attachment = handle:FindFirstChildOfClass("Attachment")
						local target = attachment and char:FindFirstChild(attachment.Name, true)
						if target and target:IsDescendantOf(copy) then target = nil end
						if not target and attachment then
							for _, part in ipairs(char:GetChildren()) do
								if part:IsA("BasePart") then target = part:FindFirstChild(attachment.Name); if target then break end end
							end
						end
						if target and not target:IsA("Attachment") then target = nil end
						if target or head then
							local weld = Instance.new("Weld")
							weld.Part0 = handle
							weld.Part1 = target and target.Parent or head
							weld.C0 = attachment and attachment.CFrame or copy.AttachmentPoint
							weld.C1 = target and target.CFrame or CFrame.new(0, 0.5, 0)
							weld.Parent = handle
						end
					end
				end
			end
		end
		if head and sourceHead then
			for _, obj in ipairs(sourceHead:GetChildren()) do
				if obj:IsA("Decal") or obj:IsA("SurfaceAppearance") or obj:IsA("SpecialMesh") or obj:IsA("Texture") then
					local copy = obj:Clone(); copy.Parent = head; saved.added[#saved.added + 1] = copy
				end
			end
		end
	end)
end

SpooferLeft:AddLabel("Copies clothing, accessories and face; keeps body geometry.", true)
SpooferLeft:AddInput("ExtraAvatarUserId", { Text = "Avatar user ID", Default = tostring(lp.UserId), Numeric = true, Finished = true, Callback = function(v)
	local id = tonumber(v)
	if id and id > 0 and id % 1 == 0 then cfg.userId = id; if cfg.avatar then outfit(lp.Character, cfg.userId) end; refreshProfileImages() end
end })
SpooferLeft:AddToggle("ExtraAvatarEnabled", { Text = "Enable local outfit", Default = false, Callback = function(v)
	cfg.avatar = v
	if v and lp.Character then
		outfit(lp.Character, cfg.userId)
	else
		if lp.Character then restoreCharacter(lp.Character) end
	end
	refreshProfileImages()
end })

connect(lp.CharacterAdded, function(char)
	task.delay(1, function()
		if running and cfg.avatar then outfit(char, cfg.userId) end
	end)
end)

table.insert(restorers, function()
	cfg.avatar = false
	if lp.Character then restoreCharacter(lp.Character) end
	for _, rig in pairs(rigs) do pcall(function() rig:Destroy() end) end
end)

-- Profile display spoof: stat texts, player attributes, thumbnail image
local Profile = Tabs.Spoofer:AddRightGroupbox("Profile display")
Profile:AddLabel("Display-only overrides for the local profile card.", true)

local Spoof = {
	NameEnabled = false, Name = "ProPlayer", DisplayName = "ProPlayer",
	LevelEnabled = false, Level = 100,
	EloEnabled = false, Elo = 2400,
	CasualWinsEnabled = false, CasualWins = 500,
	RankedWinsEnabled = false, RankedWins = 250,
	WinPercentEnabled = false, WinPercent = 75,
	WinStreakEnabled = false, WinStreak = 25,
	FavMapEnabled = false, FavMap = "Arena",
}

local _spooferActive = false
local _spooferConns = {}
local _isSpoofing = {}
local _origText = {}

local function anySpoofOn()
	return Spoof.NameEnabled or Spoof.LevelEnabled or Spoof.CasualWinsEnabled
		or Spoof.RankedWinsEnabled or Spoof.EloEnabled
		or Spoof.WinPercentEnabled or Spoof.WinStreakEnabled
		or Spoof.FavMapEnabled
end

local function escPat(s) return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")) end
local function escRep(s) return (s:gsub("%%", "%%%%")) end

local function belongsToLp(obj)
	local node, depth = obj, 0
	while node ~= nil and node ~= game and depth < 12 do
		if node:IsA("BillboardGui") then
			local anchor = node.Adornee or node.Parent
			while anchor ~= nil and not anchor:IsA("Model") do anchor = anchor.Parent end
			if anchor ~= nil then
				local plr = Players:GetPlayerFromCharacter(anchor)
				if plr ~= nil then return plr == lp end
			end
		elseif node:IsA("Model") then
			local plr = Players:GetPlayerFromCharacter(node)
			if plr ~= nil then return plr == lp end
		end
		local asId = tonumber(node.Name)
		if asId ~= nil and Players:GetPlayerByUserId(asId) ~= nil then return asId == lp.UserId end
		node = node.Parent; depth = depth + 1
	end
	return true
end

local ALLOWED_TEXT_NAMES = {
	DisplayName = true, Username = true, Name = true, Handle = true, Nametag = true,
	Title = true, TitleText = true, Value = true, Text = true, Label = true,
	Wins = true, WinRate = true, Streak = true, WinStreak = true, ELO = true, Level = true,
}

local function applyTextSpoof(obj)
	if not (obj and obj.Parent) then return end
	if _isSpoofing[obj] then return end
	local text = obj.Text
	if not text or #text == 0 then return end
	local newText = text
	local changed = false
	if Spoof.NameEnabled then
		local fakeName = Spoof.Name or "ProPlayer"
		local fakeDisp = Spoof.DisplayName or fakeName
		local realName = lp.Name
		local realDisp = lp.DisplayName
		if realDisp and #realDisp > 0 and newText:find(realDisp, 1, true) then
			newText = newText:gsub(escPat(realDisp), escRep(fakeDisp))
			changed = true
		end
		if realName and #realName > 0 and newText:find(realName, 1, true) then
			newText = newText:gsub(escPat(realName), escRep(fakeName))
			changed = true
		end
	end
	local pn = obj.Parent and obj.Parent.Name or ""
	local on = obj.Name
	local isVal = (on == "Value" or on == "Text")
	local is_level = (pn == "Level" or pn == "LevelContainer") and (isVal or on == "Level")
	local is_wins = (on == "Wins" or pn == "Wins" or pn == "WinsContainer") and (isVal or on == "Wins")
	local is_elo = (pn == "ELO" or pn == "RankedElo" or pn == "Rating" or pn == "Rank") and (isVal or on == "ELO")
	local is_winrate = (on == "WinRate" or on == "win rate" or pn == "WinRate") and (isVal or on == "WinRate")
	local is_streak = (pn == "Streak" or pn == "WinStreak" or pn == "StreakContainer" or on == "Streak" or on == "WinStreak")
		and (isVal or on == "Streak" or on == "WinStreak")
	if (is_level or is_wins or is_elo or is_winrate or is_streak) and belongsToLp(obj) then
		local sVal = nil
		if Spoof.LevelEnabled and is_level then sVal = tostring(Spoof.Level or 100)
		elseif Spoof.CasualWinsEnabled and is_wins then sVal = tostring(Spoof.CasualWins or 500)
		elseif Spoof.EloEnabled and is_elo then sVal = tostring(Spoof.Elo or 2400)
		elseif Spoof.WinPercentEnabled and is_winrate then sVal = tostring(Spoof.WinPercent or 75) .. "%"
		elseif Spoof.WinStreakEnabled and is_streak then sVal = tostring(Spoof.WinStreak or 25)
		end
		if sVal ~= nil and newText ~= sVal then newText = sVal; changed = true end
	end
	if changed and newText ~= text then
		if _origText[obj] == nil then _origText[obj] = text end
		_isSpoofing[obj] = true
		pcall(function() obj.Text = newText end)
		_isSpoofing[obj] = nil
	end
end

local function registerTextObj(obj)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
	if _spooferConns[obj] ~= nil then return end
	local txt = nil
	pcall(function() txt = obj.Text end)
	local mine = type(txt) == "string" and #txt > 0
		and ((#lp.Name > 0 and txt:find(lp.Name, 1, true) ~= nil)
			or (#lp.DisplayName > 0 and txt:find(lp.DisplayName, 1, true) ~= nil))
	if not ALLOWED_TEXT_NAMES[obj.Name] and not mine then return end
	applyTextSpoof(obj)
	_spooferConns[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function() applyTextSpoof(obj) end)
	obj.Destroying:Once(function()
		local c = _spooferConns[obj]
		if c ~= nil then pcall(function() c:Disconnect() end) end
		_spooferConns[obj] = nil; _origText[obj] = nil; _isSpoofing[obj] = nil
	end)
end

local function stopGuiNameSpoofer()
	for k, c in pairs(_spooferConns) do
		pcall(function() c:Disconnect() end)
		_spooferConns[k] = nil
	end
	for obj, t in pairs(_origText) do
		pcall(function()
			if obj.Parent ~= nil then
				_isSpoofing[obj] = true; obj.Text = t; _isSpoofing[obj] = nil
			end
		end)
		_origText[obj] = nil
	end
	_isSpoofing = {}
	_spooferActive = false
end

local function startGuiNameSpoofer()
	if _spooferActive or not anySpoofOn() then return end
	_spooferActive = true
	local pGui = lp:FindFirstChildOfClass("PlayerGui")
	if pGui then
		for _, inst in ipairs(pGui:GetDescendants()) do registerTextObj(inst) end
		_spooferConns["pGuiDesc"] = pGui.DescendantAdded:Connect(registerTextObj)
	end
	pcall(function()
		local cGui = cloneref(game:GetService("CoreGui"))
		if cGui then
			for _, inst in ipairs(cGui:GetDescendants()) do registerTextObj(inst) end
			_spooferConns["cGuiDesc"] = cGui.DescendantAdded:Connect(registerTextObj)
		end
	end)
	if Spoof.NameEnabled then
		_spooferConns["wsDesc"] = workspace.DescendantAdded:Connect(function(inst)
			if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
				for _, child in ipairs(inst:GetDescendants()) do registerTextObj(child) end
				if _spooferConns[inst] == nil then
					_spooferConns[inst] = inst.DescendantAdded:Connect(registerTextObj)
				end
			end
		end)
	end
end

local function refreshGuiNameSpoofer()
	if not anySpoofOn() then stopGuiNameSpoofer(); return end
	if not _spooferActive then startGuiNameSpoofer(); return end
	for obj in pairs(_spooferConns) do
		if typeof(obj) == "Instance" then pcall(applyTextSpoof, obj) end
	end
end

local _savedAttrs = {}
local _pinnedAttrs = {}
local _pinConns = {}
local function pinAttr(attrName, val)
	if not _savedAttrs[attrName] then _savedAttrs[attrName] = { value = lp:GetAttribute(attrName) } end
	_pinnedAttrs[attrName] = val
	if not _pinConns[attrName] then
		_pinConns[attrName] = lp:GetAttributeChangedSignal(attrName):Connect(function()
			local targetVal = _pinnedAttrs[attrName]
			if targetVal ~= nil and lp:GetAttribute(attrName) ~= targetVal then
				pcall(function() lp:SetAttribute(attrName, targetVal) end)
			end
		end)
	end
	pcall(function() lp:SetAttribute(attrName, val) end)
end
local function unpinAttr(attrName)
	_pinnedAttrs[attrName] = nil
	if _pinConns[attrName] then
		_pinConns[attrName]:Disconnect()
		_pinConns[attrName] = nil
	end
	local saved = _savedAttrs[attrName]
	if saved then
		_savedAttrs[attrName] = nil
		pcall(function() lp:SetAttribute(attrName, saved.value) end)
	end
end
local function unpinAll()
	local names = {}
	for k in pairs(_pinConns) do names[#names + 1] = k end
	for _, k in ipairs(names) do unpinAttr(k) end
end
local function updatePlayerSpoofer()
	if not anySpoofOn() then unpinAll(); return end
	pcall(function()
		local sLev = tonumber(Spoof.Level) or 100
		local sElo = tonumber(Spoof.Elo) or 2400
		local sCWins = tonumber(Spoof.CasualWins) or 500
		local sRWins = tonumber(Spoof.RankedWins) or 250
		local sWP = (tonumber(Spoof.WinPercent) or 75) / 100
		local sStreak = tonumber(Spoof.WinStreak) or 25
		local sMap = tostring(Spoof.FavMap or "Arena")
		if Spoof.LevelEnabled then pinAttr("Level", sLev) else unpinAttr("Level") end
		if Spoof.EloEnabled then
			pinAttr("DisplayELO", sElo)
			pinAttr("RankedCurrentELO", sElo)
		else
			unpinAttr("DisplayELO")
			unpinAttr("RankedCurrentELO")
		end
		if Spoof.CasualWinsEnabled then
			pinAttr("CasualWins", sCWins)
			pinAttr("StatisticDuelsWins", sCWins)
		else
			unpinAttr("CasualWins")
			unpinAttr("StatisticDuelsWins")
		end
		if Spoof.RankedWinsEnabled then pinAttr("RankedWins", sRWins) else unpinAttr("RankedWins") end
		if Spoof.WinPercentEnabled then
			pinAttr("CasualWinPercent", sWP)
			pinAttr("RankedWinPercent", sWP)
			pinAttr("StatisticDuelsWinRate", sWP * 100)
			pinAttr("WinRate", sWP * 100)
		else
			unpinAttr("CasualWinPercent")
			unpinAttr("RankedWinPercent")
			unpinAttr("StatisticDuelsWinRate")
			unpinAttr("WinRate")
		end
		if Spoof.WinStreakEnabled then
			pinAttr("StatisticDuelsWinStreak", sStreak)
			pinAttr("WinStreak", sStreak)
			pinAttr("CurrentWinStreak", sStreak)
		else
			unpinAttr("StatisticDuelsWinStreak")
			unpinAttr("WinStreak")
			unpinAttr("CurrentWinStreak")
		end
		if Spoof.FavMapEnabled then pinAttr("FavoriteMap", sMap) else unpinAttr("FavoriteMap") end
	end)
end

-- Thumbnail image spoof (profile card picture)
local imgTracked = setmetatable({}, { __mode = "k" })
local function applyImageSpoof(obj, saved)
	if not obj.Parent or saved.writing then return end
	local value = saved.original
	if type(value) ~= "string" or #value == 0 then return end
	local new = value
	if cfg.avatar then
		new = value:gsub("%f[%d]" .. tostring(lp.UserId) .. "%f[%D]", tostring(cfg.userId))
	end
	if new ~= obj.Image then
		saved.writing = true; obj.Image = new; saved.writing = false
	end
end
local function registerImageObj(obj)
	if imgTracked[obj] then return end
	if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then return end
	local img = obj.Image
	if type(img) ~= "string" or #img == 0 then return end
	if not img:find(tostring(lp.UserId), 1, true) then return end
	local saved = { original = img }
	imgTracked[obj] = saved
	saved.connection = obj:GetPropertyChangedSignal("Image"):Connect(function()
		if saved.writing then return end
		saved.original = obj.Image
		applyImageSpoof(obj, saved)
	end)
	applyImageSpoof(obj, saved)
end
local imgRoots = {}
local function scanImages()
	for _, root in ipairs({ lp:FindFirstChildOfClass("PlayerGui"), workspace }) do
		if root and not imgRoots[root] then
			imgRoots[root] = true
			for _, obj in ipairs(root:GetDescendants()) do registerImageObj(obj) end
			connect(root.DescendantAdded, registerImageObj)
		end
	end
end
refreshProfileImages = function()
	scanImages()
	for obj, saved in pairs(imgTracked) do applyImageSpoof(obj, saved) end
end

-- Profile UI controls
Profile:AddToggle("SpooferNameEnabled", { Text = "Spoof name", Default = false, Callback = function(v)
	Spoof.NameEnabled = v; refreshGuiNameSpoofer()
end })
local nameDep = Profile:AddDependencyBox()
nameDep:AddInput("SpooferName", { Default = "ProPlayer", Text = "Username", Finished = true, Callback = function(v)
	Spoof.Name = tostring(v); refreshGuiNameSpoofer()
end })
nameDep:AddInput("SpooferDisplayName", { Default = "ProPlayer", Text = "Display name", Finished = true, Callback = function(v)
	Spoof.DisplayName = tostring(v); refreshGuiNameSpoofer()
end })
nameDep:SetupDependencies({ { Toggles.SpooferNameEnabled, true } })

Profile:AddToggle("SpooferLevelEnabled", { Text = "Spoof level", Default = false, Callback = function(v)
	Spoof.LevelEnabled = v; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
local levelDep = Profile:AddDependencyBox()
levelDep:AddInput("SpooferLevel", { Default = "100", Text = "Level", Numeric = true, Finished = true, Callback = function(v)
	Spoof.Level = tonumber(v) or 100; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
levelDep:SetupDependencies({ { Toggles.SpooferLevelEnabled, true } })

Profile:AddToggle("SpooferRankedEloEnabled", { Text = "Spoof ELO", Default = false, Callback = function(v)
	Spoof.EloEnabled = v; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
local eloDep = Profile:AddDependencyBox()
eloDep:AddInput("SpooferRankedElo", { Default = "2400", Text = "ELO rating", Numeric = true, Finished = true, Callback = function(v)
	Spoof.Elo = tonumber(v) or 2400; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
eloDep:SetupDependencies({ { Toggles.SpooferRankedEloEnabled, true } })

Profile:AddToggle("SpooferCasualWinsEnabled", { Text = "Spoof casual wins", Default = false, Callback = function(v)
	Spoof.CasualWinsEnabled = v; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
local cwDep = Profile:AddDependencyBox()
cwDep:AddInput("SpooferCasualWins", { Default = "500", Text = "Casual wins", Numeric = true, Finished = true, Callback = function(v)
	Spoof.CasualWins = tonumber(v) or 500; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
cwDep:SetupDependencies({ { Toggles.SpooferCasualWinsEnabled, true } })

Profile:AddToggle("SpooferRankedWinsEnabled", { Text = "Spoof ranked wins", Default = false, Callback = function(v)
	Spoof.RankedWinsEnabled = v; updatePlayerSpoofer()
end })
local rwDep = Profile:AddDependencyBox()
rwDep:AddInput("SpooferRankedWins", { Default = "250", Text = "Ranked wins", Numeric = true, Finished = true, Callback = function(v)
	Spoof.RankedWins = tonumber(v) or 250; updatePlayerSpoofer()
end })
rwDep:SetupDependencies({ { Toggles.SpooferRankedWinsEnabled, true } })

Profile:AddToggle("SpooferWinPercentEnabled", { Text = "Spoof winrate", Default = false, Callback = function(v)
	Spoof.WinPercentEnabled = v; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
local wpDep = Profile:AddDependencyBox()
wpDep:AddInput("SpooferWinPercent", { Default = "75", Text = "Winrate %", Numeric = true, Finished = true, Callback = function(v)
	Spoof.WinPercent = tonumber(v) or 75; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
wpDep:SetupDependencies({ { Toggles.SpooferWinPercentEnabled, true } })

Profile:AddToggle("SpooferWinStreakEnabled", { Text = "Spoof win streak", Default = false, Callback = function(v)
	Spoof.WinStreakEnabled = v; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
local wsDep = Profile:AddDependencyBox()
wsDep:AddInput("SpooferWinStreak", { Default = "25", Text = "Win streak", Numeric = true, Finished = true, Callback = function(v)
	Spoof.WinStreak = tonumber(v) or 25; updatePlayerSpoofer(); refreshGuiNameSpoofer()
end })
wsDep:SetupDependencies({ { Toggles.SpooferWinStreakEnabled, true } })

Profile:AddToggle("SpooferFavoriteMapEnabled", { Text = "Spoof favorite map", Default = false, Callback = function(v)
	Spoof.FavMapEnabled = v; updatePlayerSpoofer()
end })
local mapDep = Profile:AddDependencyBox()
mapDep:AddInput("SpooferFavoriteMap", { Default = "Arena", Text = "Map name", Finished = true, Callback = function(v)
	Spoof.FavMap = tostring(v); updatePlayerSpoofer()
end })
mapDep:SetupDependencies({ { Toggles.SpooferFavoriteMapEnabled, true } })

table.insert(restorers, function()
	for obj, saved in pairs(imgTracked) do
		if saved.connection then pcall(function() saved.connection:Disconnect() end) end
		if obj.Parent and type(saved.original) == "string" then
			pcall(function() obj.Image = saved.original end)
		end
	end
	stopGuiNameSpoofer()
	unpinAll()
end)


-- Misc tab
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc")
MiscGroup:AddLabel("Placeholder groupbox. Add your controls here.", true)

-- Watermark
Library:SetWatermarkVisibility(true)

local FrameTimer, FrameCounter, FPS = tick(), 0, 60
local function GetPing()
	return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
end
local CanDoPing = pcall(GetPing)

local WatermarkConnection = RunService.RenderStepped:Connect(function()
	FrameCounter += 1
	if (tick() - FrameTimer) >= 1 then
		FPS = FrameCounter
		FrameTimer = tick()
		FrameCounter = 0
	end

	if CanDoPing then
		Library:SetWatermark(("My UI | %d fps | %d ms"):format(math.floor(FPS), GetPing()))
	else
		Library:SetWatermark(("My UI | %d fps"):format(math.floor(FPS)))
	end
end)

-- UI Settings tab
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open keybind menu",
	Callback = function(Value)
		Library.KeybindFrame.Visible = Value
	end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

Library:OnUnload(function()
	running = false
	pcall(function() WatermarkConnection:Disconnect() end)
	for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	for i = #restorers, 1, -1 do pcall(restorers[i]) end
end)

-- Addons
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
