module("check", package.seeall)

require "cjson"	--cjson库
require "ngx" --ngx库
local ipWhiteList = require "config"["ipWhiteList"]
local conn = require "redis_conn"
local tools = require "tools"

function checkState()

	--如果没有传入'User-Agent'属性,jsonp不会返回key和secret
	local remoteAgent = tools.trim(ngx.req.get_headers()['User-Agent'] or '')
	
	if not remoteAgent or remoteAgent == '' then
		--如果没有agent,多返回一个参数noAgent为true
		return '0', '', nil, '', true
	end

	--检查缓存
	local r, err = conn.conn()
	--如果连接reids出错
	if err then
		return '0', '', nil
	end

	--去redis中获取共享字典
	local gateStateVal, err = r:get(config.globalStateKey) or '0'
	--如果连接reids出错
	if err then
		return '0', '', nil
	end	
	--如果redis没有找到，则关闭,redis返回的nil必须使用ngx.null
	if gateStateVal == ngx.null or not gateStateVal or gateStateVal == '' then
		gateStateVal = '0'
	end

	
	local aesKey, err = r:get(config.globalAesKey) or ''
	--如果连接reids出错
	if err then
		return '0', '', nil
	end
	if aesKey == ngx.null or aesKey == '' then
		gateStateVal = '0'
		aesKey = ''
	end

	--关闭redis链接
	conn.close(r)

	--检查白名单
	local remoteIp = ngx.var.remote_addr
	for i,v in ipairs(ipWhiteList) do
		--如果在白名单中，则把开关关闭
		if v == remoteIp then
			gateStateVal = '0'
			break
		end
	end

	return gateStateVal, aesKey, aesSecret, remoteAgent

end





