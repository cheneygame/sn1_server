local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 100 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

get 2 {
	request {
		what 0 : string
	}
	response {
		result 0 : string
	}
}

set 3 {
	request {
		what 0 : string
		value 1 : string
	}
}

login 1003 {
	request {
		user 0 : string
		pass 1 : string
		server 2 : string
	}
	response {
		msg 0  : string
		code 1 : integer
	}
}

inroom 1004 {
	request {
		roomid 0 : integer
		idx 1 : integer
	}
	response {
		msg 0  : string
		code 1 : integer
	}
}

ready 1005 {
	response {
		msg 0  : string
		code 1 : integer
	}
}

draw 1006 {
	request {
		x 0 : integer
		y 1 : integer
	}
}

closedraw 1007 {
	response {
		msg 0  : string
		code 1 : integer
	}
}

drawbegan 1008 {
	request {
		x 0 : integer
		y 1 : integer
	}
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 100 : integer
}

heartbeat 1 {}

.room {
	roomid 0 : integer
	idx 1 : integer
	account 2 : integer
	state 3 : integer
}

room_info 2 {
	request {
		rooms 0 : *room
	}
}

intogame 3 {}

matedraw 4 {
	request {
		account 0 : string
		x 1 : integer
		y 2 : integer
	}
}

matedrawbegan 5 {
	request {
		account 0 : string
		x 1 : integer
		y 2 : integer
	}
}

]]

return proto
