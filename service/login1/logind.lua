local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"
--local account_mgr = require "account_mgr"

--print("logind params:",...)
--local db = tonumber(...)

local server = {
	--host = "127.0.0.1",
	host = "0.0.0.0",
	port = 8001,
	multilogin = false,	-- disallow multilogin
	name = "login_master",
}

local server_list = {}
local user_online = {}
local user_login = {}

--called by loginserver
function server.auth_handler(token)
	-- the token is base64(user)@base64(server):base64(password)
	local user, server, password = token:match("([^@]+)@([^:]+):(.+)")
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	print("auth_handler,user,server,password:",user,server,password)
	local db = skynet.queryservice(true,"accountDB")
	local success, errmsg = skynet.call(db,"lua","verify",user,password)
    	print("verify:",success, errmsg)
	if not success then
        	--return {errmsg = errmsg}
		local success = skynet.call(db,"lua","register",user,password)
           	--local success = account_mgr:register(user, password)
		print("register",success)
	end
	--[[
	account_mgr:init() --should redesign this ! to much init
	local success, errmsg = account_mgr:verify(user, password)
    	print("verify:",success, errmsg)
	if not success then
        	--return {errmsg = errmsg}
           	local success = account_mgr:register(user, password)
		print("register",success)
	end
	]]
	assert(password == "password", "Invalid password")
	return server, user
end

--called by loginserver
function server.login_handler(server, uid, secret)
	print(string.format("%s@%s is login, secret is %s in logind.lua", uid, server, crypt.hexencode(secret)))
	local gameserver = assert(server_list[server], "Unknown server")
	-- only one can login, because disallow multilogin
	local last = user_online[uid]
	if last then
	--will trigger gated.lua kick_handler
		skynet.call(last.address, "lua", "kick", uid, last.subid)
	end
	if user_online[uid] then
		error(string.format("user %s is already online", uid))
	end
	--will trigger gated.lua login_handler
	local subid = tostring(skynet.call(gameserver, "lua", "login", uid, secret))
	user_online[uid] = { address = gameserver, subid = subid , server = server}
	return subid
end

local CMD = {}

--called by gated
function CMD.register_gate(server, address)
	print("register_gate in logind.lua")
	server_list[server] = address
end

--called by gated
function CMD.logout(uid, subid)
	local u = user_online[uid]
	if u then
		print(string.format("%s@%s is logout", uid, u.server))
		user_online[uid] = nil
	end
end

--msg dispatched by loginserver.lua form other services(gated.lua)
function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

login(server)
