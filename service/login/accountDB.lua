local skynet = require "skynet"

require("functions")
local M = {}

local MongoLib = require "mongolib"
local utils = require "utils"

local mongo_host = "127.0.0.1"
local mongo_db = "ms_server"

local dbconf = {
    host="127.0.0.1",
    port=27017,
    db="game",
--    username="yun",
--    --    password="yun",
--    --    authmod="mongodb_cr"
}

-- account,passwd,nickname
function M:init()
    self.mongo = MongoLib.new()
    self.mongo:connect(dbconf)
    self.mongo:use(mongo_db)
    self.account_tbl = {}
    self:load_all()
    print("do account_mgr:init()")
end

function M:load_all()
    local it = self.mongo:find("account",{},{_id = false})

    if not it then
        return
    end

    while it:hasNext() do
        local obj = it:next()
        self.account_tbl[obj.account] = obj
    end
end

function M:get_by_account(source,account)
    return self.account_tbl[account]
end

function M:save_player(source,obj)
	self.mongo:insert("account", obj)
	self.account_tbl[obj.account] = obj
end


-- 验证账号密码
function M:verify(source,account, passwd)
    print("db verify",account,passwd)
    --dump(self.account_tbl)
    local info = self.account_tbl[account]
    if not info then
    	--print("veriry return",false,"account not exist")
        return false, "account not exist"
    end

    if info.passwd ~= passwd then
    	--print("veriry return",false,"wrong pass")
        return false, "wrong password"
    end
    --print("veriry return",true)
    return true
end

-- 注册账号
function M:register(source,account, passwd)
    print("db register",account,passwd)
    if self.account_tbl[account] then
	--dump(self.account_tbl)
        return false, "account exists"
    end

    local info = {account = account, passwd = passwd}
    self.account_tbl[account] = info
    self.mongo:insert("account", info)

    return true
end


skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		print("accountDB dispatch",source,command,...)
		local f = assert(M[command])
		skynet.ret(skynet.pack( f(M,source, ...)) )
	end)

end)
