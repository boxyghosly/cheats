if not game:IsLoaded() then game.Loaded:Wait() end
local RunService = game:GetService("RunService")

-- EDIT THIS to your own GitHub repo (Library.lua at root, addons in /addons/)
local repo = "https://raw.githubusercontent.com/boxyghosly/cheats/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = getgenv().Options
local Toggles = getgenv().Toggles

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

-- Spoofer tab
local SpooferLeft = Tabs.Spoofer:AddLeftGroupbox("Spoofer left")
SpooferLeft:AddLabel("Placeholder groupbox. Add your controls here.", true)

local SpooferRight = Tabs.Spoofer:AddRightGroupbox("Spoofer right")
SpooferRight:AddLabel("Placeholder groupbox. Add your controls here.", true)

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
	WatermarkConnection:Disconnect()
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
