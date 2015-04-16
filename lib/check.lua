module("check", package.seeall)

require "cjson"	--cjson库
require "ngx" --ngx库
local ipWhiteList = require "config"["ipWhiteList"]
local blackAgent = require "config"["blackAgent"]
local config = require "config"
local conn = require "redis_conn"
local tools = require "tools"

function checkState(isGetKey)
	
	--重建缓存
	local result = tools.rebuildCacheDict(isGetKey)
	if not result then
		--如果重建缓存出错，直接放过
		tools.forceCloseSystem()
		return '0', '', nil, '', true
	end
	
	--缓存字典对象
	local cachDict = ngx.shared.cachDict
	
	local ngxHeader = ngx.req.get_headers() or {}
	--如果没有传入'User-Agent'属性,jsonp不会返回key和secret
	local remoteAgent = tools.trim(ngxHeader['User-Agent'] or '')
	local referer = tools.trim(ngxHeader['referer'] or ngxHeader['referrer'] or '')
	
	--检查agent
	if not remoteAgent or remoteAgent == '' then
	--如果没有agent,多返回一个参数noAgent为true，出错并记录
		ngx.log(ngx.ERR, string.format("checkState not have  User-Agent"))
		return '0', '', nil, '', true
	end
	
	--检查agent
	for i=1, #(blackAgent) do
		local res, _ = string.find(remoteAgent, blackAgent[i])
		--表示有敏感的agent,出错并记录
		if res ~= nil then
			ngx.log(ngx.ERR, string.format("checkState User-Agent have :%s, User-Agent: %s", blackAgent[i], remoteAgent))
			return '0', '', nil, '', true
		end
	end 
	
	--检查referrer
	if not referer or referer == '' then
		--如果没有referer,出错记录
		ngx.log(ngx.ERR, string.format("checkState not have referer or referrer"))
		return '0', '', nil, '', true
	end
	
	--检查referrer
	local refererFound = 0
	for i=1,#(config.referrerList) do
		local pos, _ = string.find(referer, config.referrerList[i],1,true)
		if pos and pos >= 1 then
			refererFound = refererFound + 1
			break
		end
	end
	if refererFound == 0 then
		ngx.log(ngx.ERR, string.format("checkState referer not in white list"))
		return '0', '', nil, '', true
	end


	--去获取共享字典中的总开关状态
	local gateStateVal = cachDict:get(config.globalStateKey) or '0'

	--去获取共享字典中的全局key
	local aesKey = cachDict:get(config.globalAesKey) or ''

	--检查白名单
	local remoteIp = ngx.var.remote_addr
	for i,v in ipairs(ipWhiteList) do
		--如果在白名单中，则把开关关闭
		if v == remoteIp then
			gateStateVal = '0'
			break
		end
	end

	return gateStateVal, aesKey, nil, remoteAgent

end





