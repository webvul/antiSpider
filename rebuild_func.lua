require "ngx" --ngx库

local config = require "config"
local tools = require "tools"

ngx.header["Content-Type"] = 'text/html';
local remoteIp = ngx.var.remote_addr
local result = false
for i,v in ipairs(config.internalList) do
		--如果在白名单中，则把开关关闭
		if v == remoteIp then
			result = tools.rebuildCacheDict(nil, true)
			break
		end
end


if result then
	ngx.say('ok')
else
	ngx.say('fail')
end
