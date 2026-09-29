local url = "https://raw.githubusercontent.com/boxyghosly/cheats/main/main.lua"
local cache = "MyScriptHub/main.lua"

if not isfolder("MyScriptHub") then makefolder("MyScriptHub") end

local src = isfile(cache) and readfile(cache) or nil
if src then loadstring(src)() end

task.spawn(function()
    local fresh = game:HttpGet(url)
    writefile(cache, fresh)
    if not src then loadstring(fresh)() end
end)
