ngx.header["Content-Type"] = 'text/plain'
local args = ngx.req.get_uri_args()
local sleep = tonumber(args['sleep'] or 1)
ngx.sleep(sleep)
ngx.say('ok')

