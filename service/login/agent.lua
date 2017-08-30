local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local proto = require("proto")
require("CMD")
require("GDef")
require("functions")
local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd
local account = nil

local function send_package(pack)
        print("send_package",pack)
        local package = string.pack(">s2", pack)
        socket.write(client_fd, package)
end

function REQUEST:get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	local ret = skynet.call(module,"lua","player","set_room_id",account,nil,nil)
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

function REQUEST.login(args)
	print("login",args.user,args.pass)
	local user = args.user
	local password = args.pass
	local server = args.server
	local db = skynet.queryservice(true,"accountDB")
        local success, errmsg = skynet.call(db,"lua","verify",user,password)
        print("verify:",success, errmsg)
        if not success then
		success,errmsg = skynet.call(db,"lua","register",user,password)
                print("register",success,errmsg)
		if success then
                	return { msg = "register success",code = 0}
		else
			return { msg = errmsg,code = 2}
		end

	end
	return { msg = "login success",code = 0}
end

function REQUEST.inroom(args)
	--dump(args,"inroom")
	print("inroom",account)
	local module = skynet.queryservice(true,"player_module")
        local pret = skynet.call(module,"lua","player","get_player_info",account)
	local ingame = false
	if pret.state == RoomState_Ingame then
		ingame = true
	end
	local ret = 0
	if not ingame then
		local module = skynet.queryservice(true,"room_module")
        	ret = skynet.call(module,"lua","mgr","get_account",args.roomid,args.idx)
		if ret == nil then
			local module = skynet.queryservice(true,"player_module")
			ret = skynet.call(module,"lua","player","set_room_id",account,args.roomid,args.idx)
		else
			ret = -2 --already have other account
		end
	else
		ret = -3
	end
	if not ret then
		ret = -1
	end
	--cp:set_room_id(args.roomid)
	--print("ret",ret)
	if ret > -1 then
		local module = skynet.queryservice(true,"room_module")
	        local ret = skynet.call(module,"lua","mgr","set_account",args.roomid,args.idx,account)

		return { msg = "success",code = 0}
	elseif ret == -2 then
		return { msg = "already have one",code = 2}
	elseif ret == -3 then
		return { msg = "already ingame",code = 2}
	else
		return { msg = "error",code = 1}
	end
end

function REQUEST.ready(args)
	local module = skynet.queryservice(true,"player_module")
        local ret = skynet.call(module,"lua","player","get_room_state",account)
	print("ready state",ret)
	if ret == RoomState_Sit then
		local ret = skynet.call(module,"lua","player","set_room_state",account,RoomState_Ready)
		return { msg = "ok",code = 0}
	else
		return { msg = "no sit",code = 1}
	end
end

function REQUEST.draw(args)
	local ret =  skynet.call(skynet.self(),"lua","get_roommates")
	skynet.call(WATCHDOG,"lua","sendtomates",account,"matedraw",account,args.x,args.y)
	return false
end

function REQUEST.drawbegan(args)
	local ret =  skynet.call(skynet.self(),"lua","get_roommates")
	skynet.call(WATCHDOG,"lua","sendtomates",account,"matedrawbegan",account,args.x,args.y)
	return false
end

function REQUEST.closedraw(args)
	local module = skynet.queryservice(true,"player_module")
	local ret = skynet.call(module,"lua","player","set_room_state",account,RoomState_Sit)

	return {code = ret,msg = "closedraw"}
end

local function request(name, args, response)
	print("request",name,args,response)
	--dump(args)
	local f = assert(REQUEST[name],name,args)
	local r = f(args)
	--print("r",r)
	if response and r then
		return response(r)
	end
end


local function request_finish(name, args, response)
	if name == "login" then
		--login finish
		local module = skynet.queryservice(true,"player_module")
		local cp = skynet.call(module,"lua","mgr","create_player",args.user)
		account = args.user
		--dump(cp)
		--dump(getmetatable(mgr),"mgr")
		--print(mgr.create_player)
		--mgr:create_player(args.account)
		--print("get_player_mgr",mgr)
		skynet.call(WATCHDOG,"lua","broad_room_info")
	elseif name == "inroom" then 
		print("request_finish inroom")
		skynet.call(WATCHDOG,"lua","broad_room_info")
		--send_room_info()
	elseif name == "quit" then
		print("request_finish quit")
	elseif name == "ready" then
		local module = skynet.queryservice(true,"player_module")
		local pret = skynet.call(module,"lua","player","get_player_info",account)
		if pret then
			local module = skynet.queryservice(true,"room_module")
                	local ret = skynet.call(module,"lua","mgr","get_room_info",pret.roomid)
			skynet.call(skynet.self(),"lua","broad_intogame",ret)
		end 
		skynet.call(WATCHDOG,"lua","broad_room_info")
	elseif name == "closedraw" then
                print("request_finish closedraw")
                skynet.call(WATCHDOG,"lua","broad_room_info")
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz) --host:c2s request
	end,
	dispatch = function (_, _, type, ...)--params form unpack
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			print("ok,result",ok,result)
			if ok then
				if result then
					send_package(result)
				end
				request_finish(...)
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	--host = sprotoloader.load(1):host "package"
	--send_request = host:attach(sprotoloader.load(2))
	--another write mode than above
	host = sproto.new(proto.c2s):host "package"
	send_request = host:attach(sproto.new(proto.s2c))
	--[[	
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)
	]]
	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.get_roommates()
	
	local module = skynet.queryservice(true,"player_module")
        local pret = skynet.call(module,"lua","player","get_player_info",account)
        if pret then
                local module = skynet.queryservice(true,"room_module")
                local ret = skynet.call(module,"lua","mgr","get_room_info",pret.roomid)
                --skynet.call(skynet.self(),"lua","broad_intogame",ret)
                return ret
        end
	return nil
end

function CMD.broad_intogame(t)
	--print("broad_intogame",t)
	if #t ~= 2 then return end
	
	for k,v in pairs(t) do
		if v.state ~= RoomState_Ready then
			return 
		end
	end
	for k,v in pairs(t) do
		local str = send_request("intogame",CMD_INTOGAME)
		--sendto each one count intogame
 	        skynet.call(WATCHDOG,"lua","sendtoaccount",v.account,"send_request",str)
		--set room state
		local module = skynet.queryservice(true,"player_module")
		local ret = skynet.call(module,"lua","player","set_room_state",v.account,RoomState_Ingame)

	end
end

function CMD.matedraw(pa,px,py)
	local info = {account = pa,x = px,y = py}
	local str = send_request("matedraw",info,CMD_MATEDRAW)
        skynet.call(skynet.self(),"lua","send_request",str)

end

function CMD.matedrawbegan(pa,px,py)
	local info = {account = pa,x = px,y = py}
	local str = send_request("matedrawbegan",info,CMD_MATEDRAWBEGAN)
        skynet.call(skynet.self(),"lua","send_request",str)

end

function CMD.broad_room_info()
	local module = skynet.queryservice(true,"room_module")
	local rooms_info = skynet.call(module,"lua","mgr","get_rooms_info")
	local info = {rooms = rooms_info}
	--dump(info)
	--some bug about socket,timeout to deal temp
	skynet.timeout(0,function()
                local str = send_request("room_info",info,CMD_ROOMINFO)		
		skynet.call(WATCHDOG,"lua","broadcast","send_request",str)
		--send_package(send_request("room_info",info,CMD_ROOMINFO))
        end)
end

function CMD.send_request(...)
	send_package(...)
end

function CMD.disconnect()
	-- todo: do something before exit
	local module = skynet.queryservice(true,"room_module")
        local ret = skynet.call(module,"lua","mgr","del_account",account)

	local module = skynet.queryservice(true,"player_module")
        local cp = skynet.call(module,"lua","mgr","del_player",account)

	account = nil
	skynet.exit()
end

function CMD.getaccount()
	return account
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
