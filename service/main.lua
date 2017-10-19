local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
require("functions")
local max_client = 64

skynet.start(function()
	skynet.error("Server start")
	local db = skynet.uniqueservice(true,"accountDB")
        skynet.call(db,"lua","init")
	print("mongodb",db)

	skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	skynet.newservice("simpledb")
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	--will trigger room_module/main.lua, more detail in config.lua
	local room = skynet.uniqueservice(true,"room_module",watchdog) --room/main.lua
	local player = skynet.uniqueservice(true,"player_module",watchdog) --player/main.lua
	skynet.error("Watchdog listen on", 8888)
	skynet.exit()
end)
