require "ngx" --ngx库

local config = require "config"
local tools = require "tools"
local ck = require "resty.cookie"


function doSetCookie()
		--参数
		local args = ngx.req.get_uri_args()
		local did = args['did']
		if not did then
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
			httponly = true,
			max_age = config.sessionMaxAge
		})
		local resStr = tools.jsonp('1')
		tools.jsonpSay(resStr)
		return

end

doSetCookie()
