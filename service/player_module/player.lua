local skynet = require("skynet")
require("GDef")
local M = {}

M.__index = M

function M.create(...)
    local o = {}
    setmetatable(o, M)

    M.init(o, ...)
    return o
end


function M:init(account)
	self.account = account
	self.room_state = RoomState_None
	--get_by_account
	local mdb = skynet.queryservice(true,"accountDB")
        --local success, errmsg = skynet.call(db,"lua","verify",user,password)
	self.db = skynet.call(mdb,"lua","get_by_account",account)
	--self.rooms = {}
end

function M:set_room_id(id,idx)
	self.room_id = id
	self.room_idx = idx -- left or right
	if id then
		self.room_state = RoomState_Sit
	else
		self.room_state = RoomState_None
	end
	return id
end

function M:get_player_info()
	local info = {}
	info.account = self.account
	info.roomid = self.room_id
	info.idx = self.room_idx
	info.state = self.room_state
	return info
end

function M:set_room_state(v)
	self.room_state = v
end

function M:get_room_state()
	return self.room_state
end

function M:is_state_sit()
	return self.room_state == RoomState_Sit
end

function M:is_state_ready()
	return self.room_state == RoomState_Ready
end

function M:is_state_ingame()
	return self.room_state == RoomState_Ingame
end

function M:is_state_none()
	return self.room_state == RoomState_None
end


return M
