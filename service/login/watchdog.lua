local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local proto = require("proto")
require("CMD")
require("functions")
local host
local send_request

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	agent[fd] = skynet.newservice("agent")
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
	skynet.call(skynet.self(),"lua","broad_room_info")
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

function CMD.broadcast(cmd,...)
	for k,v in pairs(agent) do
		skynet.call(v,"lua",cmd,...)
	end	
end

function CMD.broad_room_info()
	local module = skynet.queryservice(true,"room_module")
	local rooms_info = skynet.call(module,"lua","mgr","get_rooms_info")
	local info = {rooms = rooms_info}
	--dump(info)
	--some bug about socket,timeout to deal temp
	skynet.timeout(0,function()
                local str = send_request("room_info",info,CMD_ROOMINFO)		
		skynet.call(skynet.self(),"lua","broadcast","send_request",str)
		--send_package(send_request("room_info",info,CMD_ROOMINFO))
        end)
end

function CMD.sendtoaccount(account,cmd,...)
	for k,v in pairs(agent) do
		--print("sendtoaccount",v.account,account)
		local va = skynet.call(v,"lua","getaccount")
		--print("getaccount",va,account,type(va),type(account))
		if va == account then
			skynet.call(v,"lua",cmd,...)
		end
        end

end

function CMD.sendtomates(account,cmd,...)
	for k,v in pairs(agent) do
		--print("sendtoaccount",v.account,account)
		local va = skynet.call(v,"lua","getaccount")
		--print("getaccount",va,account,type(va),type(account))
		if va ~= account then
			skynet.call(v,"lua",cmd,...)
		end
        end

end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
	host = sproto.new(proto.c2s):host "package"
        send_request = host:attach(sproto.new(proto.s2c))

	gate = skynet.newservice("gate")
end)
