local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local player_mgr_tbl = require("player_mgr")
require("functions")
local wdog = tonumber(...)
print("player_module/main",wdog)
local player_mgr = nil
local CMD = {}
function CMD.get_player_mgr()
        --return CMD.player_mgr
        return player_mgr
end

--operate player_mgr
function CMD.mgr(source,func,...)
	--print("oprate player_mgr",source,func,...)
	--dump(player_mgr)
	return player_mgr[func](player_mgr,...)
end

--operate player
function CMD.player(source,func,account,...)
	--print("operate player",source,account,func,...)
	--dump(player_mgr)
	local player = player_mgr:get_player(account)
	if player then
		return player[func](player,...)
	else
		skynet.error("nil player in player main",account)
	end
	return player_mgr[func](player_mgr,...)
end

skynet.start(function()
	skynet.error("player main booted.............")
	--CMD.player_mgr = player_mgr.create(wdog)
	player_mgr = player_mgr_tbl.create(wdog)
	--dump(getmetatable(player_mgr),"CMD.player_mgr")
	--print(player_mgr.create_player,player_mgr.__index)
        skynet.dispatch("lua", function(session, source, command, ...)
                --print("dispatch",session,source,command,...)
		local f = assert(CMD[command])
                skynet.ret(skynet.pack(f(source, ...)))
        end)

end)
