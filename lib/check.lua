module("check", package.seeall)

require "ngx" --ngx库
local ipWhiteList = require "config"["ipWhiteList"]
local conn = require "redis_conn"

function checkState()
	
	--如果没有传入'User-Agent'属性,jsonp不会返回key和secret
	local remoteAgent = ngx.req.get_headers()['User-Agent']
	if not remoteAgent or remoteAgent eq ''
		--如果没有agent,多返回一个参数noAgent为true
		return '0', nil, nil, '', true
	
	
	--检查缓存
	local r, err = conn.conn()
	--如果连接reids出错
	if err then
		return '0', nil, nil
	end
	
	local cachDict = ngx.shared.cachDict
		
	--从nginx共享字典获取反爬虫总开关状态
	local gateStateVal, _ = cachDict:get('state')
	--如果共享字典中没有
	if not gateStateVal then
		--去redis中获取共享字典
		gateStateVal = r:get(config.globalStateKey) or '0'
		--将开关的值写入共享字典
		cachDict:set('state', gateStateVal, 60*5)
	end

	--检查aeskey的情况
	local aesKey, _ = cachDict:get('aeskey')
	if not aesKey or aesKey eq '' then
		aesKey = r:get(config.globalAesKey) or ''
		--无法获取aeskey
		if aesKey eq '' then
			gateStateVal = '0'
		cachDict:set('aeskey', aesKey, 60*5)
	end

	--检查aessecret的情况
	--local aesSecret, _ = cachDict:get('aessecret')
	--if not aesSecret or aesSecret eq '' then
	--	aesSecret = r:get(config.globalAesSecret) or ''
		--无法获取aessecret
	--	if aesSecret eq '' then
	--		gateStateVal = '0'
	--	cachDict:set('aesSecret', aesSecret, 60*5)
	--end

	--关闭redis链接
	conn.close(r)
	
	--检查白名单
	local remoteIp = ngx.var.remote_addr
	for i,v in ipairs(ipWhiteList) do  
		--如果在白名单中，则把开关关闭
		if v eq remoteIp then
			gateStateVal = '0'
			break
		end
	end   
	
	return gateStateVal, aesKey, aesSecret, remoteAgent
end 





