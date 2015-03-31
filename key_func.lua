require "ngx" --ngx库

local config = require "config"
local tools = require "tools"
local ck = require "resty.cookie"
local checkState = require "check"['checkState']

function jsonpSay(jsStr)
	ngx.header["Content-Type"] = 'application/x-javascript';
	ngx.header['Cache-Control'] = 'nocache';
	ngx.header['Pragma']= 'no-cache';
	ngx.header['Expires']= '-1';
	ngx.say(jsStr)
end


function doJsonp()
		--检查状态
		local gateStateVal, aesKey, aesSecret, remoteAgent, noAgent = checkState()

		--生成cookie
		local cookie, err = ck:new()

		--如果关闭开关或者出错了,或者未用agent请求
		if gateStateVal.eq('0') or not cookie or noAgent then
			local resStr = tools.jsonp('', '')
			jsonpSay(resStr)
			return
		end

		local enterTime = tools.getNowTs()
		local remoteIp = ngx.var.remote_addr
		local remoteAgent = remoteAgent

		--将ip,agent和时间戳加密成待加密字符串,用内部aes加密key来进行加密
		local toEncryptStr = tools.sha256(remoteIp..config.md5Gap..remoteAgent)
		local aesEncryptStr = tools.aes128Encrypt(config.aesPrivateKey, toEncryptStr)
		--生成加密session的字符串
		local sessionSha256 = tools.sha256(string.format('%s&%s', enterTime, config.sessionKey))
		--session cookie,base64编码
		local sessionVal = ngx.encode_base64(string.format('%s.%s', enterTime, sessionSha256))

		--设置加密cookie
		local ok, err = cookie:set({
			key = config.sessionName,
			value = sessionVal,
			path = "/",
			httponly = true,
			expires = config.sessionExpire,
			max_age = config.sessionMaxAge
		})

		--cookie设置出错记录错误日志
		if not ok then
			ngx.log(ngx.ERR, "cookie:set error :" ..err)
			local resStr = tools.jsonp('', '')
			jsonpSay(resStr)
			return
		end

		--将aes的加密key和已经aes加密串丢入jsonp返回给客户
		local resStr = tools.jsonp(aesKey, aesEncryptStr)
		jsonpSay(resStr)

		--如果超过1秒, 记录错误日志
		local dealTime = tools.getNowTs() - enterTime
		if dealTime > 1 then
			ngx.log(ngx.ERR, string.format("jsonp deal too long : %s", dealTime))
		end

end

doJsonp()
