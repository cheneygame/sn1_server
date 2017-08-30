local skynet = require("skynet")
local room = require("room")
local M = {}

local ROOM_NUM = 6
M.__index = M

function M.create(...)
    --[[
    local o = {}
    setmetatable(o, M)

    M.init(o, ...)
    return o
    ]]
	M.init(M,...)
	return M
end


function M:init(wdog)
	self.wdog = wdog
	self.rooms = {}
	for i=1,ROOM_NUM do
		local one = room.create(i)
		table.insert(self.rooms,one)
	end
end

function M:get_rooms_info()
	local infos = {}
	for i=1,ROOM_NUM do
		local one = self:get_room(i)
		for k,v in pairs(one.players) do
			local t = {}
			t.roomid = i
			t.idx = k
			t.account = v
			local module = skynet.queryservice(true,"player_module")
        		local ret = skynet.call(module,"lua","player","get_room_state",t.account)
			t.state = ret

			--print("one info",i,k,v,ret)
			table.insert(infos,t)
		end
        end
	return infos
end

function M:get_room_info(i)
	local infos = {}
	local one = self:get_room(i)
	for k,v in pairs(one.players) do
		local t = {}
		t.roomid = i
		t.idx = k
		t.account = v
		local module = skynet.queryservice(true,"player_module")
        	local ret = skynet.call(module,"lua","player","get_room_state",t.account)
		t.state = ret

		--print("one info",i,k,v,ret)
		table.insert(infos,t)
	end
	return infos
end

function M:check_is_allready(i)
end

function M:get_room(i)
	return self.rooms[i]
end

function M:del_account(account)
	for k,v in pairs(self.rooms) do
		v:del_account(account)
	end
end

--del,and then set 
function M:set_account(room_id,idx,account)
	self:del_account(account)
	local room = self:get_room(room_id)
	if room then
		room:set_player(idx,account)
	else
		skynet.error("set_account error room_id",room_id)
	end
	--self:print_rooms()
end

function M:get_account(room_id,idx)
	local room = self:get_room(room_id)
	if room then
		return room:get_player(idx)
	end
	return nil
end

function M:print_rooms()
	for k,v in pairs(self.rooms) do
		for m,n in pairs(v.players) do
			 print("room info",k,m,n)
		end
	end

end


return M
