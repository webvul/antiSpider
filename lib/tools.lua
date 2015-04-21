module("tools", package.seeall)

require "ngx" --ngx库

local ck = require "resty.cookie"
local resty_sha256 = require "resty.sha256"
local resty_md5 = require "resty.md5"
local aes = require "resty.aes"
local str = require "resty.string"
local config = require "config"
local conn = require "redis_conn"
require "cjson"	--cjson库




-- Compatibility: Lua-5.1
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


function isdigit(str)
	if str == nil then
		return nil, "the string parameter is nil"
	end
	local len = string.len(str)
	for i = 1, len do
		local ch = string.sub(str, i, i)
		if ch < '0' or ch > '9' then
			return false
		end
	end
	return true
end


--获取真实ip
function getRealIp()
	
	local header = ngx.req.get_headers()

	--如果没有 x-forwarded-for 头
	if not header['x-forwarded-for'] then
		local realIp = ngx.var.remote_addr or '127.0.0.1'
		return realIp
	end
	--截取真实ip
	local realIp = split(header['x-forwarded-for'], ',')[1]
	return realIp

end

function trim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end

--获得当前时间戳
function getNowTs()
	return tonumber(os.time())
end

--sha256方法
function sha256(strParam)
	local sha256 = resty_sha256:new()
	sha256:update(strParam)
	local digest = sha256:final()
	return str.to_hex(digest)
end




--aes128加密算法
function aes128Encrypt(strParm, frontAesKey)
	
	local md5 = resty_md5:new()
	md5:update(frontAesKey)
	local digest = md5:final()
	local aes_iv_key = digest
	
	local md5 = resty_md5:new()
	md5:update(config.globalAesIv)
	local digest = md5:final()
	local aes_iv_val = digest
	
	local aes_iv = aes:new(aes_iv_key, nil, aes.cipher(128,"cbc"), {iv=aes_iv_val})
	local encryptStr = aes_iv:encrypt(strParm) 
	
	return ngx.encode_base64(encryptStr)
		
end

--aes128解密算法
function aes128Decrypt(encryptedStrParm, frontAesKey)
	
	local md5 = resty_md5:new()
	md5:update(frontAesKey)
	local digest = md5:final()
	local aes_iv_key = digest
	
	local md5 = resty_md5:new()
	md5:update(config.globalAesIv)
	local digest = md5:final()
	local aes_iv_val = digest
	
	--ngx.log(ngx.ERR, string.format("##################_%s",encryptedStrParm))
	--ngx.log(ngx.ERR, string.format("##################_%s",ngx.decode_base64(encryptedStrParm)))
	--ngx.log(ngx.ERR, string.format("##################_%s",frontAesKey))
		
	local aes_iv = aes:new(aes_iv_key, nil, aes.cipher(128,"cbc"), {iv=aes_iv_val})
	local decryptStr 
	
	local status, err = pcall(function() decryptStr = aes_iv:decrypt(ngx.decode_base64(encryptedStrParm)) or '' end)
			
	if err then
		ngx.log(ngx.ERR, string.format("aes128Decrypt Decrypt error: %s, encryptedStrParm:%s",err,encryptedStrParm))
		return false
	end
		
	return decryptStr

end

--jsonp方法返回
function jsonp(aesKey, encryptStr, cbName)
	local globalAesIv = config.globalAesIv
	local callbackName
	--如果aeskey是空，则都返回空或者'0'
	if aesKey == '' or encryptStr == '0' or aesKey == '1' then
		globalAesIv = ''
		encryptStr = ''
	end
	if not cbName or cbName == nil then
		local args = ngx.req.get_uri_args()
		callbackName = args['callback'] or 'callback'
	else
		callbackName = cbName
	end
	
	return string.format(';%s(["%s","%s","%s"]);', callbackName, aesKey, globalAesIv, encryptStr)
end





--验证加密cookie是否合法
function verifySessionCookie()
	
	local remoteIp = getRealIp()
	local cookie, err = ck:new()
	--出错了
	if not cookie then
		return nil, err
	end
	local sessionVal, err = cookie:get(config.sessionName)
	
	--出错了
	if err then
		ngx.log(ngx.ERR, string.format("verifySessionCookie get cookie err: %s,  or no cookie name: %s", err, config.sessionName))
		return false, nil
	end
	if sessionVal == ngx.null or  not sessionVal or sessionVal == '' then
		ngx.log(ngx.ERR, string.format("verifySessionCookie not have sessionVal, remoteip: %s", remoteIp))
		return false, nil
	end

	--检查sessionCookie是否合法
	--base64解码
	sessionVal = ngx.decode_base64(sessionVal)
	if not sessionVal or sessionVal == '' then
		ngx.log(ngx.ERR, string.format("verifySessionCookie not valid base64, remoteip: %s", remoteIp))
		return false, nil
	end
	
	local sessionTimestamp = string.sub(sessionVal,1,10)
	local sessionSign = string.sub(sessionVal,12, -1)
	local trueSign = sha256(sessionTimestamp..config.md5Gap..config.sessionKey)
	if trueSign ~= sessionSign then
		ngx.log(ngx.ERR, string.format("verifySessionCookie sign not valid, sessionval : %s, remoteip: %s", sessionVal, remoteIp))
		return false, nil
	elseif getNowTs() - tonumber(sessionTimestamp) > 3600*48 then
		ngx.log(ngx.ERR, string.format("verifySessionCookie timestamp expire sessionval : %s, remoteip: %s", sessionVal, remoteIp))
		return false, nil
	else
		return true, nil
	end
end

--验证deviceid是否合法
function simpleVerifyDeviceId()
	local cookie, err = ck:new()
	local remoteIp = getRealIp()
	if not cookie then
		return nil, err
	end
	local deviceId, err = cookie:get(config.deviceIdCookieName)
	--出错了
	if err then
		ngx.log(ngx.ERR, string.format("simpleVerifyDeviceId get cookie err: %s,  or no cookie name: %s", err, config.deviceIdCookieName))
		return false, nil
	end
	--判断deviceid是否存在
	if not deviceId or deviceId == '' then
		ngx.log(ngx.ERR, string.format("verifyDeviceId not have deviceId, remoteip: %s", remoteIp))
		return false, nil
	else
		deviceId = ngx.unescape_uri(deviceId)
		return deviceId
	end
end


function jsonpSay(jsStr)
	ngx.header["Content-Type"] = 'application/x-javascript';
	ngx.header['Cache-Control'] = 'nocache';
	ngx.header['Pragma']= 'no-cache';
	ngx.header['Expires']= '-1';
	ngx.say(jsStr)
end

--重建所有缓存
function rebuildCacheDict(isGetKey, isForceRebuild)
	local cachDict = ngx.shared.cachDict
	local lastUpdateTs = tonumber(cachDict:get('lastUpdateTs') or 0)
	local nowTs = getNowTs()
	
	
	if not isForceRebuild then --只有在不强制重建缓存才会去判断
	
		--配置失效时间小于10分钟,则不去更新更新缓存
		if nowTs - lastUpdateTs < 60*10 then
			ngx.log(ngx.INFO, string.format("rebuildCacheDict kiss cache, globalStateKey %s", cachDict:get(config.globalStateKey)))
			return true
		end
		
		
		--缓存失效，先去看看有没有线程去获取缓存了，获取缓存的key还在不在
		local getCacheKey = cachDict:get('getCacheKey') or '0'
		if getCacheKey == '1' then --表示已经有线程去获取缓存了
			ngx.log(ngx.INFO, string.format("rebuildCacheDict other thread get cache, getCacheKey 0"))
			return true
		end
	
	end
	
	--拿走'getCacheKey'
	cachDict:set('getCacheKey', '1', 120)
	
	--大于10分钟后，就开始重建缓存了
	--打开redis连接
	local r, err = conn.conn()
	if err then
		cachDict:set('getCacheKey', '0') --出错放回getCacheKey
		ngx.log(ngx.ERR, string.format("tools rebuildCacheDict redis connect error %s", err))
		--如果连接reids出错
		--如果是获取key要求重建缓存，但是又出错的话
		if isGetKey then
			return true
		end
		return false
	end
	
	--全局状态
	local gateStateVal, err = r:get(config.globalStateKey) or '0'
	--如果连接reids出错
	if err then
		cachDict:set('getCacheKey', '0') --出错放回getCacheKey
		ngx.log(ngx.ERR, string.format("rebuildCacheDict redis connect gateStateVal error %s", err))
		--如果是获取key要求重建缓存，但是又出错的话
		if isGetKey then
			return true
		end
		return false
	end	
	--如果redis没有找到，则关闭,redis返回的nil必须使用ngx.null
	if gateStateVal == ngx.null or not gateStateVal or gateStateVal == '' then
		gateStateVal = '0'
	end
	
	
	
	local aesKey, err = r:get(config.globalAesKey) or ''
	--如果连接reids出错
	if err then
	
		cachDict:set('getCacheKey', '0') --出错放回getCacheKey
		ngx.log(ngx.ERR, string.format("rebuildCacheDict redis connect r:get(config.globalAesKey) error %s", err))
		--如果是获取key要求重建缓存，但是又出错的话
		if isGetKey then
			return true
		end
		return false
	end
	if aesKey == ngx.null or aesKey == '' then
		gateStateVal = '0'
		aesKey = ''
	end
	
	
	--上一个key缓存
	local lastAesKey, err = r:get(config.lastGlobalAesKey) or ''
	--如果连接reids出错
	if err then
		cachDict:set('getCacheKey', '0') --出错放回getCacheKey
		ngx.log(ngx.ERR, string.format("rebuildCacheDict redis connect r:get(config.lastGlobalAesKey) error %s", err))
		return false
	end
	if lastAesKey == ngx.null or lastAesKey == '' then
		ngx.log(ngx.ERR, string.format("rebuildCacheDict lastAesKey is empty"))
		lastAesKey = ''
	end
	
	
	--更新缓存，更新缓存时间戳
	cachDict:set(config.globalStateKey, gateStateVal)
	cachDict:set(config.globalAesKey, aesKey)
	cachDict:set(config.lastGlobalAesKey, lastAesKey)
	cachDict:set('lastUpdateTs', tostring(nowTs))
	
	--缓存生成成功，放回'getCacheKey'
	cachDict:set('getCacheKey', '0')
	--关闭redis链接
	conn.close(r)
	
	ngx.log(ngx.INFO, string.format("rebuildCacheDict rebuild cache success, globalStateKey %s", cachDict:get(config.globalStateKey)))
	return true
end


--崩溃异常，立即关闭反爬虫系统
function forceCloseSystem()
	local cachDict = ngx.shared.cachDict
	cachDict:set(config.globalStateKey, '0')
	ngx.log(ngx.ERR, string.format("rebuildCacheDict system got error, force close"))
end












