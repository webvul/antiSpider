--测试用例
require "ngx" --ngx库

local config = require "config"
local tools = require "tools"
local conn = require "redis_conn"


KEY_URL = "/td/key?callback=callback"
CHECK_URL = '/?_tdcheck=1'

function trim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end


--测试redis连接函数包
do
	local r, err = conn.conn()
	assert(not err)
	r:set('test', '1')
	local res, err = r:get('test')
	assert(not err)
	assert(res, '1')
	conn.close(r)
	ngx.say('redis 连接测试 OK')
end


--测试tools函数包
do
	local nowTs = tools.getNowTs()
	assert(type(nowTs) == type(1))
	assert(nowTs >= (os.time()-1))
	
	local toSharStr = 'http://www.ly.com/'
	local shaStr = tools.sha256(toSharStr)
	assert('4b9cef18d078f3e81d45359efed6fa94a6a05067124843feeb75d49fbd813560' == shaStr)
	
	local aesKey = '49a0a981c3b37aab2c480510653690a5'
	local aesStr = 'http://www.ly.com/'
	local encodeStr = tools.aes128Encrypt(aesStr, aesKey)
	local decodeStr = tools.aes128Decrypt(aesStr, aesKey)
	assert(decodeStr, aesStr)
	
	local jsonpStr = tools.jsonp('0','','callback')
	assert(jsonpStr,';callback(["0","",""]);')
	local jsonpStr = tools.jsonp('1','','callback')
	assert(jsonpStr,';callback(["1","",""]);')
	local jsonpStr = tools.jsonp('49a0a981c3b37aab2c480510653690a5','123','callback')
	assert(jsonpStr,';callback(["49a0a981c3b37aab2c480510653690a5","'..config.globalAesIv..'","123"]);')
		
	ngx.say('tools 方法测试 OK')
end




--测试生成key的方法和check方法
do
	local r, err = conn.conn()
	
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	assert(code==400)
	

	r:set(config.globalStateKey, '0')
	ngx.req.set_header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36")
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	local data = trim(res.body)
	assert(code==200)
	assert('body', ';callback(["","",""]);')
	
	
	
	r:set(config.globalStateKey, '1')
	r:set(config.globalAesKey, '12345678901234567890123456789012')
	local ipAndAgent = tools.sha256('127.0.0.1'..config.md5Gap..'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36')
	ngx.req.set_header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36")
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	local data = trim(res.body)
	assert(code==200)
	assert('body', ';callback(["12345678901234567890123456789012","'..config.globalAesIv..'","'..ipAndAgent..'"]);')
	local cookieVal = res.header['Set-Cookie']
	local p = string.find(cookieVal, 'td_ssid=')
	assert(p)
	local p = string.find(cookieVal, 'ax-Age=86400; Path=/; HttpOnly')
	assert(p)
	
	ngx.say('key 生成方法测试 OK')
	conn.close(r)
end


--测试代理功能是否可用
do
	local r, err = conn.conn()
	
	
	
	ngx.say('proxy 方法测试 OK')
	conn.close(r)
end




ngx.say('所有测试完毕')
ngx.exit(ngx.HTTP_OK)