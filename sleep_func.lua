-- lua_shared_dict testCache 10m;

ngx.header["Content-Type"] = 'text/plain'
local args = ngx.req.get_uri_args()
local sleepArgs = tonumber(args['sleep']) or 0.1
local size = tonumber(args['size']) or 10
local sleep = tonumber(sleepArgs)

local cache = ngx.shared.testCache

if not cache:get('1k') then
	local s = ''
	
	for i = 1, 1024 do
		s = s .. 'x'
	end
	cache:set('1k',s)
	
	s = ''
	for i = 1, 1024*50 do
		s = s .. 'x'
	end
	cache:set('50k',s)
	
	s = ''
	for i = 1, 1024*500 do
		s = s .. 'x'
	end
	cache:set('500k',s)
	
end

ngx.sleep(sleep)

if size == 1 then
	ngx.say(cache:get('1k'))
elseif size == 50 then
	ngx.say(cache:get('10k'))
elseif size	 == 500 then
    ngx.say(cache:get('500k'))
else
	ngx.say(tostring(size) or 'ok')
end






