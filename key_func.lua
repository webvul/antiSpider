require "ngx" --ngx库

local config = require "config"
local tools = require "tools"
local ck = require "resty.cookie"
local checkState = require "check"['checkState']


ngx.header["P3P"] = 'CP="CURa ADMa DEVa PSAo PSDo OUR BUS UNI PUR INT DEM STA PRE COM NAV OTC NOI DSP COR"'

function doJsonp()
		--检查状态
		local gateStateVal, aesKey, aesSecret, remoteAgent, noAgent = checkState(true)
		
		
		
		if noAgent then
			ngx.exit(400)
			return
		end

		--生成cookie
		local cookie, err = ck:new()

		--如果关闭开关或者出错了,或者未用agent请求
		--if gateStateVal == '0' or not cookie then
		--	local resStr = tools.jsonp('', '')
		--	tools.jsonpSay(resStr)
		--	return
		--end

		local enterTime = tools.getNowTs()
		local remoteIp = tools.getRealIp()
		local remoteAgent = remoteAgent

		--将ip,agent和时间戳加密成待加密字符串,用内部aes加密key来进行加密
		local toEncryptStr = tools.sha256(remoteIp..config.md5Gap..remoteAgent)
		local aesIpStr = tools.aes128Encrypt(remoteIp, config.globalIpAesKey)
		--生成 xxxxx.yyyy 这种形式的did,前面是ip和agent的sha1，后面是ip的加密串
		toEncryptStr = toEncryptStr .. ',' .. aesIpStr
		
		--生成加密session的字符串
		local sessionSha256 = tools.sha256(enterTime..config.md5Gap..config.sessionKey)
		--session cookie,base64编码
		local sessionVal = ngx.encode_base64(string.format('%s.%s', enterTime, sessionSha256))

		--设置加密cookie
		local ok, err = cookie:set({
			key = config.sessionName,
			value = sessionVal,
			path = "/",
			httponly = true
		})
		
		--测试用,放入用户上一次调用key方法的ip和时间戳
		local ok2, err = cookie:set({
			key = 'k_st',
			value = remoteIp..'|'..enterTime,
			path = "/",
			httponly = true
		})
		

		--cookie设置出错记录错误日志
		if not ok then
			ngx.log(ngx.ERR, "cookie:set error :" ..err)
			--出错强制关闭系统
			tools.forceCloseSystem()
			local resStr = tools.jsonp('', '')
			tools.jsonpSay(resStr)
			return
		end
		
		
		--将aes的加密key和已经aes加密串丢入jsonp返回给客户
		local resStr = tools.jsonp(aesKey, toEncryptStr)
		tools.jsonpSay(resStr)
		
		--如果超过1秒, 记录错误日志
		local dealTime = tools.getNowTs() - enterTime
		if dealTime > 1 then
			ngx.log(ngx.ERR, string.format("jsonp deal too long : %s", dealTime))
		end

end

doJsonp()
