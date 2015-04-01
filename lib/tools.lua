module("tools", package.seeall)

require "ngx" --ngx库

local ck = require "resty.cookie"
local resty_sha256 = require "resty.sha256"
local resty_md5 = require "resty.md5"
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
	
	local aes_iv = aes:new(aes_iv_key, nil, aes.cipher(128,"cbc"), {iv=aes_iv_val})
	local decryptStr = aes_iv:decrypt(ngx.decode_base64(encryptedStrParm)) or ''
	
	return decryptStr

end

--jsonp方法返回
function jsonp(aesKey, encryptStr)
	local globalAesIv = config.globalAesIv
	--如果aeskey是空，则都返回空或者'0'
	if aesKey == '' or aesKey == '0' or aesKey == '1' then
		globalAesIv = ''
		encryptStr = ''
	end
	local args = ngx.req.get_uri_args()
	local callbackName = args['callback'] or 'callback'
	return string.format(';%s(["%s","%s","%s"]);', callbackName, aesKey, globalAesIv, encryptStr)
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
		ngx.log(ngx.ERR, string.format("verifySessionCookie get cookie err: %s", err))
		return false, nil
	end
	if sessionVal == ngx.null or  not sessionVal or sessionVal == '' then
		ngx.log(ngx.ERR, string.format("verifySessionCookie not have sessionVal"))
		return false, nil
	end

	--检查sessionCookie是否合法
	--base64解码
	sessionVal = ngx.decode_base64(sessionVal)
	local sessionTimestamp = string.sub(sessionVal,1,10)
	local sessionSign = string.sub(sessionVal,12, -1)
	local trueSign = sha256(sessionTimestamp..config.md5Gap..config.sessionKey)
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
	deviceId = ngx.unescape_uri(deviceId)
	if not deviceId or deviceId == '' then
		return false, nil
	else
		
		return deviceId or ''
	end
end


function jsonpSay(jsStr)
	ngx.header["Content-Type"] = 'application/x-javascript';
	ngx.header['Cache-Control'] = 'nocache';
	ngx.header['Pragma']= 'no-cache';
	ngx.header['Expires']= '-1';
	ngx.say(jsStr)
end


