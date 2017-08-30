local skynet = require "skynet"
--local account_mgr = require "account_mgr"

skynet.start(function()
	--account_mgr:init()
	local db = skynet.uniqueservice(true,"accountDB")
	print("db",db)
	local loginserver = skynet.newservice("logind",db)
	local gate = skynet.newservice("gated", loginserver)
	skynet.call(db,"lua","init")
	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})
end)
