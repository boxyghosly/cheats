if not game:IsLoaded() then game.Loaded:Wait() end
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

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

-- Spoofer tab: names, thumbnails and local outfit preview
local SpooferLeft = Tabs.Spoofer:AddLeftGroupbox("Names and thumbnails")
local SpooferRight = Tabs.Spoofer:AddRightGroupbox("Local outfit preview")

local cfg = { anonymous=false, avatar=false, userId=lp.UserId, display=false, username=false, displayName=lp.DisplayName, userName=lp.Name }
local tracked = setmetatable({}, { __mode = "k" })
local fakeNames = {}
local refresh, refreshAvatars

local function replacePlain(text, old, new)
	if old == "" then return text end
	local pattern = old:gsub("([^%w])", "%%%1")
	return (text:gsub(pattern, function() return new end))
end

local function desiredText(original)
	local text = original
	if cfg.anonymous then
		for _, player in ipairs(Players:GetPlayers()) do
			if not fakeNames[player.UserId] then fakeNames[player.UserId] = "Player" .. tostring(player.UserId % 100000) end
			text = replacePlain(text, player.DisplayName, fakeNames[player.UserId])
			text = replacePlain(text, player.Name, fakeNames[player.UserId])
		end
	else
		if cfg.display then text = replacePlain(text, lp.DisplayName, cfg.displayName) end
		if cfg.username then text = replacePlain(text, lp.Name, cfg.userName) end
	end
	return text
end

local function applyObject(obj, saved)
	if not obj.Parent or saved.writing then return end
	local value = saved.original
	if saved.property == "Text" then
		value = desiredText(value)
	else
		if cfg.anonymous then
			for _, player in ipairs(Players:GetPlayers()) do
				value = value:gsub("%f[%d]" .. tostring(player.UserId) .. "%f[%D]", "6942067")
			end
		elseif cfg.avatar then
			value = value:gsub("%f[%d]" .. tostring(lp.UserId) .. "%f[%D]", tostring(cfg.userId))
		end
	end
	if obj[saved.property] ~= value then
		saved.writing = true; obj[saved.property] = value; saved.writing = false
	end
end

local function register(obj)
	if tracked[obj] then return end
	local property
	if obj:IsA("TextLabel") or obj:IsA("TextButton") then property = "Text"
	elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then property = "Image" end
	if not property then return end
	local saved = { property = property, original = obj[property] }
	tracked[obj] = saved
	saved.connection = obj:GetPropertyChangedSignal(property):Connect(function()
		if saved.writing then return end
		saved.original = obj[property]
		applyObject(obj, saved)
	end)
	applyObject(obj, saved)
end

local roots = {}
local function scan()
	local gui = lp:FindFirstChildOfClass("PlayerGui")
	if gui and not roots[gui] then
		roots[gui] = true
		for _, obj in ipairs(gui:GetDescendants()) do register(obj) end
		connect(gui.DescendantAdded, register)
	end
end

refresh = function()
	scan()
	for obj, saved in pairs(tracked) do applyObject(obj, saved) end
end

SpooferLeft:AddInput("ExtraDisplayName", { Text = "Display name", Default = lp.DisplayName, Finished = true, Callback = function(v) cfg.displayName = v; refresh() end })
SpooferLeft:AddToggle("ExtraDisplayNameEnabled", { Text = "Override display name", Default = false, Callback = function(v) cfg.display = v; refresh() end })
SpooferLeft:AddInput("ExtraUsername", { Text = "Username", Default = lp.Name, Finished = true, Callback = function(v) cfg.userName = v; refresh() end })
SpooferLeft:AddToggle("ExtraUsernameEnabled", { Text = "Override username", Default = false, Callback = function(v) cfg.username = v; refresh() end })

SpooferRight:AddLabel("Copies clothing, accessories and face; keeps body geometry.", true)

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
			local ok, value = pcall(Players.CreateHumanoidModelFromUserId, Players, userId)
			if not ok then if running then notify("Avatar preview unavailable: " .. tostring(value)) end; return end
			rig = value
			if not running then pcall(function() rig:Destroy() end); return end
			if rigs[userId] then rig:Destroy(); rig = rigs[userId] else rigs[userId] = rig end
		end
		if not running or not char.Parent or generations[char] ~= generation then return end
		local saved = { removed = {}, added = {}, colors = {} }
		backups[char] = saved
		for _, obj in ipairs(char:GetChildren()) do
			if clothing(obj) then saved.removed[#saved.removed + 1] = { object = obj, parent = char }; obj.Parent = nil end
			if obj:IsA("BasePart") then saved.colors[obj] = obj.Color end
		end
		local head = char:FindFirstChild("Head")
		if head then
			for _, obj in ipairs(head:GetChildren()) do
				if obj:IsA("Decal") then saved.removed[#saved.removed + 1] = { object = obj, parent = head }; obj.Parent = nil end
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
		local sourceHead = rig:FindFirstChild("Head")
		if head and sourceHead then
			for _, obj in ipairs(sourceHead:GetChildren()) do
				if obj:IsA("Decal") then local copy = obj:Clone(); copy.Parent = head; saved.added[#saved.added + 1] = copy end
			end
		end
	end)
end

refreshAvatars = function()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			outfit(player.Character, cfg.anonymous and 6942067 or (player == lp and cfg.avatar and cfg.userId or nil))
		end
	end
end

SpooferRight:AddInput("ExtraAvatarUserId", { Text = "Avatar user ID", Default = tostring(lp.UserId), Numeric = true, Finished = true, Callback = function(v)
	local id = tonumber(v)
	if id and id > 0 and id % 1 == 0 then cfg.userId = id; if cfg.avatar then refreshAvatars(); refresh() end end
end })
SpooferRight:AddToggle("ExtraAvatarEnabled", { Text = "Enable local outfit", Default = false, Callback = function(v) cfg.avatar = v; refreshAvatars(); refresh() end })
SpooferLeft:AddToggle("ExtraAnonymous", { Text = "Anonymous names, thumbnails and outfits", Default = false, Callback = function(v)
	cfg.anonymous = v; refresh(); refreshAvatars()
end })

local function watch(player)
	connect(player.CharacterAdded, function(char)
		task.delay(0.5, function()
			if running then outfit(char, cfg.anonymous and 6942067 or (player == lp and cfg.avatar and cfg.userId or nil)) end
		end)
	end)
end
for _, player in ipairs(Players:GetPlayers()) do watch(player) end
connect(Players.PlayerAdded, function(player) watch(player); if cfg.anonymous then refresh() end end)

table.insert(restorers, function()
	cfg.anonymous = false; cfg.avatar = false; cfg.display = false; cfg.username = false
	for obj, saved in pairs(tracked) do
		if saved.connection then pcall(function() saved.connection:Disconnect() end) end
		if obj.Parent then pcall(function() obj[saved.property] = saved.original end) end
	end
	for char in pairs(backups) do restoreCharacter(char) end
	for _, rig in pairs(rigs) do pcall(function() rig:Destroy() end) end
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
