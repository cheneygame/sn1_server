local player = require("player")
local M = {}

--M.__index = M

function M.create(...)
    --local o = {}
    --setmetatable(o, {__index = M})

    --M.init(o, ...)
    --return o
    M.init(M,...)
    return M
end


function M:init(wdog)
	self.wdog = wdog
	self.players = {}
end

function M:get_player(account)
	return self.players[account]
end

function M:create_player(account)
	if self:get_player(account) then
		return self:get_player(account)
	end
	local one = player.create(account)
	self.players[account] = one
	return one
end

function M:del_player(account)
	if self:get_player(account) then
		self.players[account] = nil
		return true
	end
	return false
end

return M
