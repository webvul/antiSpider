require "ngx" --ngx库

local config = require "config"
local tools = require "tools"

ngx.header["Content-Type"] = 'text/html';

local result = tools.rebuildCacheDict()
if result then
	ngx.say('ok')
else
	ngx.say('fail')
end
