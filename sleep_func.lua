local tools = require "tools"

ngx.header["Content-Type"] = 'text/plain'
local args = ngx.req.get_uri_args()
local sleepArgs = args['sleep']
sleepArgs = tonumber(sleepArgs) or 0.1

local sleep = tonumber(sleepArgs)
ngx.sleep(sleep)
ngx.say('ok')





