local cjson = require "cjson"

ngx.header["Content-Type"] = 'text/plain'
local args = ngx.req.get_uri_args()

--如果要求打印请求头
if printHeader then
	local ngxHeader = ngx.req.get_headers() or {}
	ngx.say(cjson.encode(ngxHeader))
else
	ngx.say('hello world')
end



