--local player = require("onePlayer")

local M = {}

M.__index = M

function M.create(...)
    local o = {}
    setmetatable(o, M)

    M.init(o, ...)
    return o
end


function M:init(id)
	self.id = id
	self.players = {}
end

function M:get_player(idx)
	return self.players[idx]
end

function M:set_player(idx,account)
	self.players[idx] = account
end

function M:del_account(account)
	for k,v in pairs(self.players) do
		if v == account then
			self.players[k] = nil
			return
		end
	end
end

return M
