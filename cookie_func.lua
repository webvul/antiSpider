require "ngx" --ngx库

local config = require "config"
local tools = require "tools"
local ck = require "resty.cookie"


ngx.header["P3P"] = 'CP="CURa ADMa DEVa PSAo PSDo OUR BUS UNI PUR INT DEM STA PRE COM NAV OTC NOI DSP COR"'

function doSetCookie()
		--参数
		local args = ngx.req.get_uri_args()
		local did = args['did']
		if not did then
			ngx.log(ngx.ERR, string.format("not have did param in request, remoteIp : %s", tools.getRealIp()))
			local resStr = tools.jsonp('0')
			tools.jsonpSay(resStr)
			return
		end
		
		local did = ngx.escape_uri(did)
		
		--设置加密cookie
		local cookie, err = ck:new()
		local ok, err = cookie:set({
			key = config.deviceIdCookieName,
			value = did,
			path = "/",
			httponly = true
		})
		local resStr = tools.jsonp('1')
		tools.jsonpSay(resStr)
		return

end

doSetCookie()
