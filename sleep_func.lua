local tools = require "tools"

ngx.header["Content-Type"] = 'text/plain'
local args = ngx.req.get_uri_args()
local sleepArgs = args['sleep'] or '1'
if tools.isdigit(sleepArgs) then
	local sleep = tonumber(sleepArgs)
	ngx.sleep(sleep)
	ngx.say('ok')
else
	ngx.say('fail')
end





