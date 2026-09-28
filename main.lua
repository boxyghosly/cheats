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
local libCache = "MyScriptHub/libcache"

local function fetch(name)
	local path = libCache .. "/" .. name
	local ok, result
	if isfile and isfile(path) then
		ok, result = pcall(function() return loadstring(readfile(path))() end)
		if ok then return result end
	end
	ok, result = pcall(function()
		local src = game:HttpGet(repo .. name)
		if writefile then
			pcall(function()
				if not (isfolder and isfolder("MyScriptHub")) then makefolder("MyScriptHub") end
				if not (isfolder and isfolder(libCache)) then makefolder(libCache) end
				writefile(path, src)
			end)
		end
		return loadstring(src)()
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

RightGroup:AddDivider()

-- Skin changer: unlock all cosmetics (client-side only)
local SkinChanger = { want = false, weapons = false, busy = false }
do
	local http = game:GetService("HttpService")
	local reps = game:GetService("ReplicatedStorage")
	local lps = lp.PlayerScripts

	local elib, clib, ilib, dctrl, fctrl, citem, cvm, cent, vpmod
	local coss
	local equip, favs, fcache, finv = {}, {}, {}, {}
	local cwep, vprof, lwep
	local oget, ogetwep, ocvm, ogw, onew, ogvi, ofetch, ofin, onc
	local hooked = false
	local allWeapons = nil

	local function buildWeapons()
		if allWeapons then return end
		allWeapons = {}
		if ilib and ilib.Items then
			for name in ilib.Items do
				if type(name) == "string" and name ~= "MISSING_WEAPON" then
					allWeapons[#allWeapons + 1] = name
				end
			end
		end
	end

	local _wProxy, _wProxyAt, _wProxyLen = nil, 0, -1
	local function invalidateWeapons()
		_wProxy, _wProxyAt, _wProxyLen = nil, 0, -1
	end

	local function weaponProxy(data)
		if not allWeapons then return data end
		local dlen = type(data) == "table" and #data or 0
		local now = tick()
		if _wProxy and _wProxyLen == dlen and (now - _wProxyAt) < 1 then
			return _wProxy
		end
		local proxy = {}
		local n = 0
		if type(data) == "table" then
			for k, v in data do
				proxy[k] = v
				if type(k) == "number" and k > n then n = k end
			end
		end
		local owned = {}
		for _, v in pairs(proxy) do
			if type(v) == "table" and type(v.Name) == "string" then owned[v.Name] = true end
		end
		for _, name in ipairs(allWeapons) do
			if not owned[name] then
				n = n + 1
				proxy[n] = { Name = name, Level = 1, XP = 0, Prestige = 0 }
			end
		end
		_wProxy, _wProxyAt, _wProxyLen = proxy, now, dlen
		return proxy
	end

	local savef = "SkinChanger/config.json"

	local function banned(n)
		if type(n) ~= "string" then return true end
		return n:find("MISSING_") or n:find("Bubblegum") or n:find("Ragdoll") or n:find("Fall Apart") or n:find("Every Finisher Ever")
	end

	local function toenum(n)
		if not elib then return nil end
		local ok, id = pcall(elib.ToEnum, elib, n)
		return ok and id or nil
	end

	local function clonecos(name, ctype, inv, favonly)
		if banned(name) then return nil end
		local base = coss[name]
		if not base then return nil end
		local d = table.clone(base)
		d.Name = name
		d.Type = d.Type or ctype
		d.Seed = d.Seed or math.random(1, 1000000)
		local eid = toenum(name)
		if eid then
			d.Enum = eid
			d.ObjectID = d.ObjectID or eid
		end
		if inv ~= nil then d.Inverted = inv end
		if favonly ~= nil then d.OnlyUseFavorites = favonly end
		return d
	end

	local function savecfg()
		if not writefile then return end
		pcall(function()
			local cfg = { equipped = {}, favorites = favs }
			for wep, cos in equip do
				local slot = {}
				cfg.equipped[wep] = slot
				for ct, cd in cos do
					if cd and cd.Name and not banned(cd.Name) then
						slot[ct] = { name = cd.Name, seed = cd.Seed, inverted = cd.Inverted }
					end
				end
			end
			makefolder("SkinChanger")
			writefile(savef, http:JSONEncode(cfg))
		end)
	end

	local function loadcfg()
		if not readfile or not isfile or not isfile(savef) then return end
		pcall(function()
			local cfg = http:JSONDecode(readfile(savef))
			if cfg.equipped then
				for wep, cos in cfg.equipped do
					equip[wep] = {}
					for ct, cd in cos do
						if not banned(cd.name) then
							local cl = clonecos(cd.name, ct, cd.inverted)
							if cl then
								cl.Seed = cd.seed
								equip[wep][ct] = cl
							end
						end
					end
				end
			end
			favs = cfg.favorites or {}
		end)
	end

	local _cProxy, _cProxyAt = nil, 0
	local function rebuildinv()
		table.clear(finv)
		for name in coss do
			if not banned(name) then finv[name] = true end
		end
		for _, cos in equip do
			for _, cd in cos do
				if cd and cd.Name and not banned(cd.Name) then finv[cd.Name] = true end
			end
		end
		_cProxy, _cProxyAt = nil, 0
	end

	local function saferep(key)
		if not dctrl then return end
		pcall(function()
			local cdata = dctrl.CurrentData
			if cdata then cdata:Replicate(key) end
		end)
	end

	local function getewep()
		if not fctrl then return nil end
		local fighter = fctrl:GetFighter(lp)
		if not fighter or not fighter.Items then return nil end
		for _, item in fighter.Items do
			if item.IsEquipped then return item.Name end
		end
		return nil
	end

	local function init()
		if dctrl then return true end
		local rmods = reps:FindFirstChild("Modules")
		local ctrls = lps:FindFirstChild("Controllers")
		if not (rmods and ctrls) then return false end
		pcall(function() elib = require(rmods:WaitForChild("EnumLibrary", 10)) end)
		if elib then pcall(function() elib:WaitForEnumBuilder() end) end
		local clibOk, clibRes = pcall(function() return require(rmods:WaitForChild("CosmeticLibrary", 10)) end)
		local ilibOk, ilibRes = pcall(function() return require(rmods:WaitForChild("ItemLibrary", 10)) end)
		local dctrlOk, dctrlRes = pcall(function() return require(ctrls:WaitForChild("PlayerDataController", 10)) end)
		if not (clibOk and clibRes and ilibOk and ilibRes and dctrlOk and dctrlRes) then return false end
		clib, ilib, dctrl = clibRes, ilibRes, dctrlRes
		coss = clib.Cosmetics
		if not coss then return false end
		pcall(function() fctrl = require(ctrls:WaitForChild("FighterController", 10)) end)
		pcall(function() citem = require(lps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)
		pcall(function()
			local vmmod = lps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
			if vmmod then cvm = require(vmmod) end
		end)
		pcall(function() cent = require(lps.Modules.ClientReplicatedClasses.ClientEntity) end)
		pcall(function() vpmod = require(lps.Modules.Pages.ViewProfile) end)
		return true
	end

	local function enable()
		if not init() then return false end
		buildWeapons()
		if hooked then return true end
		hooked = true

		oget = dctrl.Get
		dctrl.Get = function(self, key)
			local data = oget(self, key)
			if SkinChanger.weapons and key == "WeaponInventory" and allWeapons then
				return weaponProxy(data)
			end
			if SkinChanger.want and key == "CosmeticInventory" then
				local now = tick()
				if _cProxy and (now - _cProxyAt) < 1 then
					return _cProxy
				end
				local proxy = {}
				if data then
					for k, v in data do
						if not banned(k) then proxy[k] = v end
					end
				end
				for name in finv do proxy[name] = true end
				_cProxy, _cProxyAt = proxy, now
				return proxy
			end
			if SkinChanger.want and key == "FavoritedCosmetics" then
				local res = data and table.clone(data) or {}
				for wep, fv in favs do
					local slot = res[wep] or {}
					res[wep] = slot
					for name, isfav in fv do
						if not banned(name) then slot[name] = isfav end
					end
				end
				return res
			end
			return data
		end

		ogetwep = dctrl.GetWeaponData
		dctrl.GetWeaponData = function(self, wname)
			local data = ogetwep(self, wname)
			if not data then return nil end
			local merged = table.clone(data)
			merged.Name = wname
			if SkinChanger.want then
				local weq = equip[wname]
				if weq then for ct, cd in weq do merged[ct] = cd end end
			end
			return merged
		end

		if hookmetamethod and getnamecallmethod then
			local rems = reps:FindFirstChild("Remotes")
			local drems = rems and rems:FindFirstChild("Data")
			local eqrem = drems and drems:FindFirstChild("EquipCosmetic")
			local favrem = drems and drems:FindFirstChild("FavoriteCosmetic")
			local rrems = rems and rems:FindFirstChild("Replication")
			local frems = rrems and rrems:FindFirstChild("Fighter")
			local uirem = frems and frems:FindFirstChild("UseItem")

			onc = hookmetamethod(game, "__namecall", function(self, ...)
				if getnamecallmethod() ~= "FireServer" then return onc(self, ...) end
				if not SkinChanger.want then return onc(self, ...) end
				local args = { ... }

				if uirem and self == uirem and fctrl then
					pcall(function()
						local fighter = fctrl:GetFighter(lp)
						if fighter and fighter.Items then
							local oid = args[1]
							for _, item in fighter.Items do
								if item:Get("ObjectID") == oid then
									lwep = item.Name
									break
								end
							end
						end
					end)
				end

				if self == eqrem then
					local wname, ctype, cname, opts = args[1], args[2], args[3], args[4] or {}
					if not cname or cname == "None" or cname == "" then
						equip[wname] = equip[wname] or {}
						equip[wname][ctype] = nil
						if not next(equip[wname]) then equip[wname] = nil end
						rebuildinv()
						task.defer(function()
							saferep("WeaponInventory")
							task.wait(0.2)
							savecfg()
						end)
						return onc(self, ...)
					end
					if banned(cname) then return onc(self, ...) end
					local rdata = oget(dctrl, "CosmeticInventory")
					if rdata and type(rdata[cname]) ~= "boolean" and rdata[cname] ~= nil then
						return onc(self, ...)
					end
					equip[wname] = equip[wname] or {}
					local cloned = clonecos(cname, ctype, opts.IsInverted, opts.OnlyUseFavorites)
					if cloned then equip[wname][ctype] = cloned end
					if ctype == "Finisher" then fcache[wname] = cname end
					rebuildinv()
					task.defer(function()
						saferep("WeaponInventory")
						task.wait(0.2)
						savecfg()
					end)
					return
				end

				if self == favrem then
					local fwep, fname, fstate = args[1], args[2], args[3]
					if not fname or fname == "None" or fname == "" then return onc(self, ...) end
					if banned(fname) then return onc(self, ...) end
					favs[fwep] = favs[fwep] or {}
					favs[fwep][fname] = fstate or nil
					savecfg()
					task.spawn(saferep, "FavoritedCosmetics")
					return
				end

				return onc(self, ...)
			end)
		end

		if citem and citem._CreateViewModel then
			ocvm = citem._CreateViewModel
			citem._CreateViewModel = function(self, vmref)
				local wname = self.Name
				local wplr = self.ClientFighter and self.ClientFighter.Player
				cwep = (wplr == lp) and wname or nil
				if SkinChanger.want and wplr == lp and equip[wname] and equip[wname].Skin and vmref then
					local skin = equip[wname].Skin
					local dk = self:ToEnum("Data")
					if vmref[dk] then
						vmref[dk][self:ToEnum("Skin")] = skin
						vmref[dk][self:ToEnum("Name")] = skin.Name
					elseif vmref.Data then
						vmref.Data.Skin = skin
						vmref.Data.Name = skin.Name
					end
				end
				local res = ocvm(self, vmref)
				cwep = nil
				return res
			end
		end

		if cvm then
			if cvm.GetWrap then
				ogw = cvm.GetWrap
				cvm.GetWrap = function(self)
					local ci = self.ClientItem
					local wname = ci and ci.Name
					local wplr = ci and ci.ClientFighter and ci.ClientFighter.Player
					local weq = SkinChanger.want and wname and wplr == lp and equip[wname]
					return (weq and weq.Wrap) or ogw(self)
				end
			end
			onew = cvm.new
			cvm.new = function(rdata, cliitm)
				local wplr = cliitm.ClientFighter and cliitm.ClientFighter.Player
				local wname = cwep or cliitm.Name
				if SkinChanger.want and wplr == lp and equip[wname] then
					pcall(function()
						local rcls = require(reps.Modules.ReplicatedClass)
						local dk = rcls:ToEnum("Data")
						rdata[dk] = rdata[dk] or {}
						local cos = equip[wname]
						local slot = rdata[dk]
						if cos.Skin then slot[rcls:ToEnum("Skin")] = cos.Skin end
						if cos.Wrap then slot[rcls:ToEnum("Wrap")] = cos.Wrap end
						if cos.Charm then slot[rcls:ToEnum("Charm")] = cos.Charm end
					end)
				end
				local res = onew(rdata, cliitm)
				if SkinChanger.want and wplr == lp and equip[wname] and equip[wname].Wrap and res._UpdateWrap then
					res:_UpdateWrap()
					task.delay(0.1, function() if not res._destroyed then res:_UpdateWrap() end end)
				end
				return res
			end
		end

		if ilib and ilib.GetViewModelImageFromWeaponData then
			ogvi = ilib.GetViewModelImageFromWeaponData
			ilib.GetViewModelImageFromWeaponData = function(self, wdata, hires)
				if not SkinChanger.want or not wdata then return ogvi(self, wdata, hires) end
				local wname = wdata.Name
				local weq = equip[wname]
				if weq and weq.Skin and (wdata.Skin == weq.Skin or vprof == lp) then
					local sinfo = self.ViewModels[weq.Skin.Name]
					if sinfo then return sinfo[hires and "ImageHighResolution" or "Image"] or sinfo.Image end
				end
				return ogvi(self, wdata, hires)
			end
		end

		if vpmod and vpmod.Fetch then
			ofetch = vpmod.Fetch
			vpmod.Fetch = function(self, tplr)
				vprof = tplr
				return ofetch(self, tplr)
			end
		end

		if cent and cent._PlayFinisher then
			ofin = cent._PlayFinisher
			cent._PlayFinisher = function(self, fname, ...)
				if not SkinChanger.want then return ofin(self, fname, ...) end
				local ewep = getewep()
				local tfin = ewep and (fcache[ewep] or (equip[ewep] and equip[ewep].Finisher and equip[ewep].Finisher.Name))
				return ofin(self, tfin or fname, ...)
			end
		end

		loadcfg()
		rebuildinv()
		for wname, wdata in equip do
			if wdata.Finisher and wdata.Finisher.Name then
				fcache[wname] = wdata.Finisher.Name
			end
		end
		saferep("CosmeticInventory")
		saferep("FavoritedCosmetics")
		saferep("WeaponInventory")
		return true
	end

	local function disable()
		if onc then
			pcall(function() hookmetamethod(game, "__namecall", onc) end)
			onc = nil
		end
		if citem and ocvm then citem._CreateViewModel = ocvm; ocvm = nil end
		if cvm then
			if ogw then cvm.GetWrap = ogw; ogw = nil end
			if onew then cvm.new = onew; onew = nil end
		end
		if ilib and ogvi then ilib.GetViewModelImageFromWeaponData = ogvi; ogvi = nil end
		if vpmod and ofetch then vpmod.Fetch = ofetch; ofetch = nil end
		if cent and ofin then cent._PlayFinisher = ofin; ofin = nil end
		if dctrl then
			if oget then dctrl.Get = oget; oget = nil end
			if ogetwep then dctrl.GetWeaponData = ogetwep; ogetwep = nil end
		end
		table.clear(equip)
		table.clear(fcache)
		table.clear(finv)
		cwep, vprof, lwep = nil, nil, nil
		invalidateWeapons()
		_cProxy, _cProxyAt = nil, 0
		hooked = false
		saferep("CosmeticInventory")
		saferep("FavoritedCosmetics")
		saferep("WeaponInventory")
	end

	SkinChanger.enable = enable
	SkinChanger.disable = disable
	SkinChanger.refresh = function()
		invalidateWeapons()
		saferep("WeaponInventory")
		if SkinChanger.want then
			saferep("CosmeticInventory")
			saferep("FavoritedCosmetics")
		end
	end
	SkinChanger.invalidate = function()
		invalidateWeapons()
	end
end

local function skinsOrWeaponsOn()
	return SkinChanger.want or SkinChanger.weapons
end

local function ensureSkinHooks(okMsg)
	if SkinChanger.busy then return end
	SkinChanger.busy = true
	task.spawn(function()
		local ok = SkinChanger.enable()
		SkinChanger.busy = false
		if not ok then
			if skinsOrWeaponsOn() then
				notify("Skin changer failed to load (wrong game or still loading - try again)")
				if SkinChanger.want then Toggles.UnlockAllSkins:SetValue(false) end
				if SkinChanger.weapons then Toggles.UnlockAllWeapons:SetValue(false) end
			end
			return
		end
		if not skinsOrWeaponsOn() then
			SkinChanger.disable()
			return
		end
		if okMsg then notify(okMsg) end
	end)
end

local function turnOff()
	if not skinsOrWeaponsOn() then
		SkinChanger.disable()
	else
		SkinChanger.refresh()
	end
end

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

local outfitBusy = {}
local applyRigToChar
local function outfit(char, userId)
	generations[char] = (generations[char] or 0) + 1
	local generation = generations[char]
	restoreCharacter(char)
	if not userId then return end
	local rig = rigs[userId]
	if rig then applyRigToChar(char, rig, generation); return end
	if outfitBusy[userId] then
		if running then notify("Avatar is still loading, please wait...") end
		return
	end
	outfitBusy[userId] = true
	if running then notify("Loading avatar " .. tostring(userId) .. "...") end
	task.spawn(function()
		local fetched = nil
		local th
		th = task.spawn(function()
			local ok, value = pcall(function() return Players:CreateHumanoidModelFromUserId(userId) end)
			if ok then fetched = value end
		end)
		local ticks = 0
		local TIMEOUT = 80
		while not fetched and running do
			task.wait(0.1)
			ticks = ticks + 1
			if ticks > TIMEOUT then break end
		end
		outfitBusy[userId] = nil
		if not fetched then
			if th then pcall(function() task.cancel(th) end) end
			if running then notify("Avatar load took too long, cancelled. Try again.") end
			return
		end
		rig = fetched
		if not running then pcall(function() rig:Destroy() end); return end
		if rigs[userId] then pcall(function() rig:Destroy() end); rig = rigs[userId] else rigs[userId] = rig end
		applyRigToChar(char, rig, generation)
	end)
end

applyRigToChar = function(char, rig, generation)
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
end

local headSwapBusy = {}
local headBackups = {}
local function swapHead(char, userId)
	if not char or not char.Parent then return end
	if headSwapBusy[userId] then return end
	headSwapBusy[userId] = true
	if running then notify("Loading head...") end
	task.spawn(function()
		local rig = rigs[userId]
		if not rig then
			local fetched = nil
			local th = task.spawn(function()
				local ok, v = pcall(function() return Players:CreateHumanoidModelFromUserId(userId) end)
				if ok then fetched = v end
			end)
			local t, TO = 0, 80
			while not fetched and running do task.wait(0.1); t = t + 1; if t > TO then break end end
			if not fetched then
				if th then pcall(function() task.cancel(th) end) end
				headSwapBusy[userId] = nil
				if running then notify("Head load took too long, cancelled.") end
				return
			end
			rig = fetched
			if rigs[userId] then pcall(function() rig:Destroy() end); rig = rigs[userId] else rigs[userId] = rig end
		end
		if not running or not char.Parent then headSwapBusy[userId] = nil; return end
		local sourceHead = rig:FindFirstChild("Head")
		local liveHead = char:FindFirstChild("Head")
		if not sourceHead or not liveHead then headSwapBusy[userId] = nil; return end
		local srcMesh, srcTex = nil, nil
		pcall(function() srcMesh = sourceHead.MeshId; srcTex = sourceHead.TextureID end)
		if not srcMesh or srcMesh == "" then headSwapBusy[userId] = nil; return end
		local bk = headBackups[char]
		if not bk then
			bk = {}
			pcall(function() bk.meshId = liveHead.MeshId; bk.textureId = liveHead.TextureID end)
			local dhm = liveHead:FindFirstChild("DefaultHeadMesh")
			if dhm then
				bk.dhmTransparency = dhm.Transparency
				local dec = dhm:FindFirstChild("Decal")
				if dec then bk.decTransparency = dec.Transparency end
			end
			headBackups[char] = bk
		end
		pcall(function()
			liveHead.MeshId = srcMesh
			if srcTex and srcTex ~= "" then liveHead.TextureID = srcTex end
		end)
		local dhm = liveHead:FindFirstChild("DefaultHeadMesh")
		if dhm then
			pcall(function() dhm.Transparency = 1 end)
			local dec = dhm:FindFirstChild("Decal")
			if dec then pcall(function() dec.Transparency = 1 end) end
		end
		headSwapBusy[userId] = nil
		if running then notify("Head applied.") end
	end)
end

local function restoreHead(char)
	local bk = headBackups[char]
	if not bk then return end
	local liveHead = char:FindFirstChild("Head")
	if liveHead then
		pcall(function()
			if bk.meshId then liveHead.MeshId = bk.meshId end
			if bk.textureId then liveHead.TextureID = bk.textureId end
		end)
		local dhm = liveHead:FindFirstChild("DefaultHeadMesh")
		if dhm then
			pcall(function() dhm.Transparency = bk.dhmTransparency or 0 end)
			local dec = dhm:FindFirstChild("Decal")
			if dec then pcall(function() dec.Transparency = bk.decTransparency or 0 end) end
		end
	end
	headBackups[char] = nil
end



SpooferLeft:AddLabel("Copies clothing, accessories and face; keeps body geometry.", true)
SpooferLeft:AddInput("ExtraAvatarUserId", { Text = "Avatar user ID", Default = tostring(lp.UserId), Numeric = true, Finished = true, Callback = function(v)
	local id = tonumber(v)
	if id and id > 0 and id % 1 == 0 then
		cfg.userId = id
		if cfg.avatar then outfit(lp.Character, cfg.userId) end
		if cfg.headSwap and lp.Character then swapHead(lp.Character, cfg.userId) end
		refreshProfileImages()
	end
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
SpooferLeft:AddDivider()
SpooferLeft:AddLabel("Head swap (experimental)", true)
SpooferLeft:AddToggle("HeadDescEnabled", { Text = "Swap head (mesh + face)", Default = false, Callback = function(v)
	cfg.headSwap = v
	if v and lp.Character then
		swapHead(lp.Character, cfg.userId)
	else
		if lp.Character then restoreHead(lp.Character) end
	end
end })

connect(lp.CharacterAdded, function(char)
	task.delay(1, function()
		if running and cfg.avatar then outfit(char, cfg.userId) end
		if running and cfg.headSwap then task.wait(0.2); swapHead(char, cfg.userId) end
	end)
end)

table.insert(restorers, function()
	cfg.avatar = false
	cfg.headSwap = false
	if lp.Character then
		restoreCharacter(lp.Character)
		restoreHead(lp.Character)
	end
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

-- CustomLeaderstats folder drives the Roblox top-right playerlist
local _clCreated = false
local _clOrig = {}
local function clSync()
	local w = nil
	if running then
		if Spoof.LevelEnabled then w = w or {}; w["Level"] = math.floor(tonumber(Spoof.Level) or 100) end
		if Spoof.EloEnabled then w = w or {}; w["Current ELO"] = math.floor(tonumber(Spoof.Elo) or 2400) end
		if Spoof.WinStreakEnabled then w = w or {}; w["Win Streak"] = math.floor(tonumber(Spoof.WinStreak) or 25) end
	end
	local folder = lp:FindFirstChild("CustomLeaderstats")
	if not w then
		if folder then
			if _clCreated then
				pcall(function() folder:Destroy() end)
				_clCreated = false
			else
				for name, val in pairs(_clOrig) do
					local iv = folder:FindFirstChild(name)
					if iv then pcall(function() iv.Value = val end) end
				end
			end
		end
		_clOrig = {}
		return
	end
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CustomLeaderstats"
		folder.Parent = lp
		_clCreated = true
	end
	for name, v in pairs(w) do
		local iv = folder:FindFirstChild(name)
		if not iv then
			iv = Instance.new("IntValue")
			iv.Name = name
			iv.Parent = folder
		elseif _clOrig[name] == nil then
			_clOrig[name] = iv.Value
		end
		if iv.Value ~= v then pcall(function() iv.Value = v end) end
	end
end

local function updatePlayerSpoofer()
	if not anySpoofOn() then unpinAll(); clSync(); return end
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
	clSync()
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

local clSyncLast = 0
connect(game:GetService("RunService").Heartbeat, function()
	local now = tick()
	if (now - clSyncLast) > 2 then
		clSyncLast = now
		pcall(clSync)
	end
end)

table.insert(restorers, function()
	if _clCreated then
		pcall(function()
			local folder = lp:FindFirstChild("CustomLeaderstats")
			if folder then folder:Destroy() end
		end)
		_clCreated = false
	end
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
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Unlock All")
MiscGroup:AddLabel("Client-side only. Server still validates real ownership.", true)

MiscGroup:AddToggle("UnlockAllSkins", {
	Text = "Unlock all skins",
	Default = false,
	Callback = function(Value)
		SkinChanger.want = Value
		if Value then
			ensureSkinHooks("All cosmetics unlocked (local only)")
		else
			turnOff()
		end
	end,
})

MiscGroup:AddToggle("UnlockAllWeapons", {
	Text = "Unlock all weapons",
	Default = false,
	Callback = function(Value)
		SkinChanger.weapons = Value
		if Value then
			ensureSkinHooks("All weapons unlocked (client-side)")
		else
			turnOff()
		end
	end,
})

table.insert(restorers, function()
	SkinChanger.want = false
	SkinChanger.weapons = false
	pcall(SkinChanger.disable)
end)

-- Watermark
Library:SetWatermarkVisibility(true)

local FrameTimer, FrameCounter, FPS = tick(), 0, 60
local function GetPing()
	return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
end
local CanDoPing = pcall(GetPing)

local WmTimer, WmPing = tick(), 0
local WatermarkConnection = RunService.RenderStepped:Connect(function()
	FrameCounter += 1
	local now = tick()
	if (now - FrameTimer) >= 1 then
		FPS = FrameCounter
		FrameTimer = now
		FrameCounter = 0
	end
	if (now - WmTimer) >= 0.25 then
		WmTimer = now
		if CanDoPing then
			WmPing = GetPing()
			Library:SetWatermark(("My UI | %d fps | %d ms"):format(math.floor(FPS), WmPing))
		else
			Library:SetWatermark(("My UI | %d fps"):format(math.floor(FPS)))
		end
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
