module("tools", package.seeall)
require "ngx" --ngx库

local ck = require "resty.cookie"
local resty_sha256 = require "resty.sha256"
local aes = require "resty.aes"
local str = require "resty.string"
local config = require "config"


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
	local aes_128_cbc_md5 = aes:new(frontAesKey)
	local encrypted = aes_128_cbc_md5:encrypt(strParm)
	return str.to_hex(encrypted)
end

--aes128解密算法
function aes128Decrypt(encryptedStrParm, frontAesKey)
	local aes_128_cbc_md5 = aes:new(frontAesKey)
	return aes_128_cbc_md5:decrypt(encryptedStrParm)
end

--jsonp方法返回
function jsonp(aesKey, encryptStr)
	local args = ngx.req.get_uri_args()
	local callbackName = args['callback']
	return string.format(';%s("%s","%s");', callbackName, encryptStr)
end

--验证加密cookie是否合法
function verifySessionCookie()
	local cookie, err = ck:new()
	--出错了
	if not cookie then
		return nil, err
	end
	local sessionVal, err = cookie:get(config.sessionName)
	--出错了
	if err then
		return nil, err
	end
	if not sessionVal or sessionVal.eq('') then
		ngx.log(ngx.ERR, string.format("verifySessionCookie not have sessionVal"))
		return false, nil
	end

	--检查sessionCookie是否合法
	--base64解码
	sessionVal = ngx.decode_base64(sessionVal)
	local sessionTimestamp = string.sub(sessionVal,0,13)
	local sessionSign = string.sub(sessionVal,14, -1)
	local trueSign = sha256(string.format('%s&%s', sessionTimestamp, config.sessionKey))

	if trueSign ~= sessionSign then
		ngx.log(ngx.ERR, string.format("verifySessionCookie sign not valid, sessionval : %s", sessionVal))
		return false, nil
	elseif getNowTs() - tonumber(sessionTimestamp) > 3600*48 then
		ngx.log(ngx.ERR, string.format("verifySessionCookie timestamp expire sessionval : %s", sessionVal))
		return false, nil
	else
		return true, nil
	end
end

--验证deviceid是否合法
function simpleVerifyDeviceId()
	local cookie, err = ck:new()
	if not cookie then
		return nil, err
	end
	local deviceId, err = cookie:get(config.deviceIdCookieName)
	if not deviceId or deviceId.eq('') then
		return false, nil
	else
		return deviceId
	end
end




