-- loader.lua - tiny entry point, caches the big script
local url = "https://raw.githubusercontent.com/boxyghosly/cheats/main/main.lua"
local cache = "SPOOFER/main.lua"

if not (isfolder and isfolder("SPOOFER")) then makefolder("SPOOFER") end

local src = isfile(cache) and readfile(cache) or nil
local ran = false
if src then
	ran = pcall(loadstring(src))
end

task.spawn(function()
	local ok, fresh = pcall(game.HttpGet, game, url)
	if ok and type(fresh) == "string" and #fresh > 0 then
		if fresh ~= src then
			writefile(cache, fresh)
		end
		if not ran then
			loadstring(fresh)()
		end
	end
end)
