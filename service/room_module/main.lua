local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local room_mgr_tbl = require("room_mgr")
local wdog = tonumber(...)
print("room/main",wdog)

local room_mgr = nil
local CMD = {}
function CMD.get_room_mgr()
	return CMD.room_mgr
end

--operate room_mgr
function CMD.mgr(source,func,...)
	--print("oprate room_mgr",source,func,...)
	--dump(player_mgr)
	return room_mgr[func](room_mgr,...)
end

--operate room
function CMD.room(source,func,...)
	
end

skynet.start(function()
	skynet.error("room main booted.............")
	room_mgr = room_mgr_tbl.create(wdog)
	skynet.dispatch("lua", function(session, source, command, ...)
                local f = assert(CMD[command])
                skynet.ret(skynet.pack(f(source, ...)))
        end)

end)
