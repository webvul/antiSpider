require "ngx" --ngx库

local config = require "config"
local tools = require "tools"
local conn = require "redis_conn"
local http = require "resty.http"


KEY_URL = "/td/key?callback=callback"
CHECK_URL = '/proxy?_tdcheck=1'
CHECK_URL_NO_JSONP = '/proxy'

function trim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end


ngx.header["Content-Type"] = 'text/plain'


--测试redis连接函数包
do
	local r, err = conn.conn()	
	assert(not err)
	r:set('test', '1')
	local res, err = r:get('test')
	assert(not err)
	assert(res, '1')
	
	
	
	
	--清楚所有的key
	r:flushdb()

	
	r:set(config.globalStateKey, '1')
	r:set(config.globalAesKey, '302702db952acfa2beb0563ded2da35a')
	r:set(config.lastGlobalAesKey, '302702db952acfa2beb0563ded2da35a')
	
	conn.close(r)
	ngx.say('redis 连接测试 OK')
end


--测试tools函数包
do
	
	--测试getNowTs
	local nowTs = tools.getNowTs()
	assert(type(nowTs) == type(1))
	assert(nowTs >= (os.time()-1))
	
	--sha256测试
	local toSharStr = 'http://www.ly.com/'
	local shaStr = tools.sha256(toSharStr)
	assert('4b9cef18d078f3e81d45359efed6fa94a6a05067124843feeb75d49fbd813560' == shaStr)
	
	--aes加密解密
	local aesKey = '49a0a981c3b37aab2c480510653690a5'
	local aesStr = 'http://www.ly.com/'
	local encodeStr = tools.aes128Encrypt(aesStr, aesKey)
	local decodeStr = tools.aes128Decrypt(encodeStr, aesKey)
	assert(decodeStr, aesStr)
	
	--测试jsonp方法
	local jsonpStr = tools.jsonp('0','','callback')
	assert(jsonpStr,';callback(["0","",""]);')
	local jsonpStr = tools.jsonp('1','','callback')
	assert(jsonpStr,';callback(["1","",""]);')
	local jsonpStr = tools.jsonp('49a0a981c3b37aab2c480510653690a5','123','callback')
	assert(jsonpStr,';callback(["49a0a981c3b37aab2c480510653690a5","'..config.globalAesIv..'","123"]);')
	
	
	
	
	
	--测试重建缓存的功能
	local cachDict = ngx.shared.cachDict
	cachDict:set('lastUpdateTs', '0')
	local result = tools.rebuildCacheDict()
	assert(result)
	assert(cachDict:get(config.globalStateKey))
	assert(cachDict:get(config.globalAesKey))
	assert(cachDict:get(config.lastGlobalAesKey))
	assert(cachDict:get('lastUpdateTs'))
	
	--测试强制关闭系统
	cachDict:set(config.globalStateKey, '1')
	tools.forceCloseSystem()
	assert(cachDict:get(config.globalStateKey), '0')
	
	--恢复开关
	cachDict:set(config.globalStateKey, '1')
	
	ngx.say('tools 方法测试 OK')
end



local globalCookieVal
--测试生成key的方法和check方法
do
	local r, err = conn.conn()
	local cachDict = ngx.shared.cachDict
	
	--测试check
	ngx.log(ngx.ERR, string.format("###################### key no agent #########################"))
	ngx.req.set_header("User-Agent", "")
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	
	--测试java_agent
	ngx.log(ngx.ERR, string.format("###################### key java agent #########################"))
	ngx.req.set_header("User-Agent", "java")
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	
	--测试referrer 没有 referrer
	ngx.log(ngx.ERR, string.format("###################### no referrer #########################"))
	ngx.req.set_header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36")
	ngx.req.set_header("referrer", "")
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	--测试referrer 无效的 referrer
	ngx.log(ngx.ERR, string.format("###################### invalid referrer #########################"))
	ngx.req.set_header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36")
	ngx.req.set_header("referrer", "http://www.baidu.com/")
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	
	--测试开关
	ngx.log(ngx.ERR, string.format("###################### key state key #########################"))
	r:set(config.globalStateKey, '0')
	--设置之后重建缓存
	cachDict:set('lastUpdateTs', '0')
	local result = tools.rebuildCacheDict()
	
	ngx.req.set_header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36")
	ngx.req.set_header("referrer", "http://127.0.0.1/")
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	local data = trim(res.body)
	assert(code==200)
	assert('body', ';callback(["","",""]);')
	
	
	--测试正常获取key和iv和str
	ngx.log(ngx.ERR, string.format("###################### key pass #########################"))
	r:set(config.globalStateKey, '1')
	r:set(config.globalAesKey, '12345678901234567890123456789012')
	--设置之后重建缓存
	cachDict:set('lastUpdateTs', '0')
	local result = tools.rebuildCacheDict()
	
	local ipAndAgent = tools.sha256('127.0.0.1'..config.md5Gap..'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36')
	ngx.req.set_header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36")
	ngx.req.set_header("referer", "http://127.0.0.1/")
	local res = ngx.location.capture(KEY_URL,{method=ngx.HTTP_GET})
	local code = res.status
	local data = trim(res.body)
	assert(code==200)
	assert('body', ';callback(["12345678901234567890123456789012","'..config.globalAesIv..'","'..ipAndAgent..'"]);')
	local cookieVal = res.header['Set-Cookie']
	--下面测试用

	local p = string.find(cookieVal, config.sessionName)
	assert(p)
	local p = string.find(cookieVal, 'HttpOnly')
	assert(p)
	
	ngx.say('key 生成方法测试 OK')
	conn.close(r)
end




--测试代理功能是否可用
do
	local r, err = conn.conn()
	local cachDict = ngx.shared.cachDict
	local blackDict = ngx.shared.blackDict
	blackDict:flush_all() --清楚所有dict里的黑名单
	
	--无agent
	ngx.log(ngx.ERR, string.format("**************************proxy no agent ***********************"))
	ngx.req.set_header("User-Agent", "")
	ngx.req.set_header("referrer", "http://127.0.0.1/")
	local res = ngx.location.capture(CHECK_URL_NO_JSONP,{method=ngx.HTTP_GET})
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	--无cookie
	ngx.log(ngx.ERR, string.format("**************************proxy no cookie ***********************"))
	ngx.req.set_header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36")
	ngx.req.set_header("referrer", "http://127.0.0.1/")
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })
	
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	
	
	
	--有td_sid，但不合法
	ngx.log(ngx.ERR, string.format("**************************proxy have td_sid not valid ***********************"))	
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = string.format("%s=%s; path=/",config.sessionName, '123213213232121'),
		  ["referrer"] = 'http://127.0.0.1/',
		}
    })
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	
	--有td_sid，合法，但是超时了
	ngx.log(ngx.ERR, string.format("**************************proxy have td_sid but expire ***********************"))
	local nowTs = tostring(tools.getNowTs() - 3600*24*3)
	local trueSign = tools.sha256(nowTs..config.md5Gap..config.sessionKey)
	local cookieSidVal = ngx.encode_base64(nowTs..'.'..trueSign)	
	
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = string.format("%s=%s; path=/",config.sessionName, cookieSidVal),
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })
	
	
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	
	ngx.sleep(1)
	
	--有td_sid，无td_did
	local nowTs = tostring(tools.getNowTs())
	local trueSign = tools.sha256(nowTs..config.md5Gap..config.sessionKey)
	local cookieSidVal = ngx.encode_base64(nowTs..'.'..trueSign)
	
	globalCookieVal = string.format('%s=%s;',config.sessionName, cookieSidVal)
	
	ngx.log(ngx.ERR, string.format("**************************proxy have td_sid no td_did ***********************"))
	--ngx.log(ngx.ERR, string.format("#########__%s",globalCookieVal))
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format(globalCookieVal)},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })
	

	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
		
	
	--有td_sid，有td_did 不合法,解密出错
	ngx.log(ngx.ERR, string.format("**************************proxy td_did decrypt error ***********************"))
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format('%s=%s', config.deviceIdCookieName, '123213232132131'), globalCookieVal},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })

	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
		
	--有td_sid，有td_did，不合法，ip和agent不匹配
	ngx.log(ngx.ERR, string.format("**************************proxy td_did ip agent not valid ***********************"))
	local globalAesKey = '302702db952acfa2beb0563ded2da35a'
	r:set(config.globalAesKey, globalAesKey)
	--设置之后重建缓存
	cachDict:set('lastUpdateTs', '0')
	local result = tools.rebuildCacheDict()
	
	local remoteIp = '127.0.0.1'
	local remoteAgent = 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0; QQBrowser/8.0.3345.400)'
	local toEncryptStr = tools.sha256(remoteIp..config.md5Gap..remoteAgent)
	local aesKey = globalAesKey
	local aesStr = toEncryptStr
	local didCookie = ngx.escape_uri(tools.aes128Encrypt(aesStr, aesKey))
		
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format('%s=%s',config.deviceIdCookieName, didCookie), globalCookieVal},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })

	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	ngx.sleep(1)
	
	--有td_sid，有td_did，不合法，ip和agent匹配，但是在黑名单中
	ngx.log(ngx.ERR, string.format("**************************proxy in blak list ***********************"))
	--ngx.log(ngx.ERR, string.format("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"))

	local remoteIp = '127.0.0.1'
	local remoteAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36"
	local toEncryptStr = tools.sha256(remoteIp..config.md5Gap..remoteAgent)
	local aesKey = globalAesKey
	local aesStr = toEncryptStr
	local didCookie = tools.aes128Encrypt(aesStr, aesKey)
	local didCookie2 = didCookie
	r:set(string.format('black_%s',didCookie), '1')
	didCookie = ngx.escape_uri(didCookie)
	
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format('%s=%s',config.deviceIdCookieName, didCookie), globalCookieVal},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })
	--ngx.log(ngx.ERR, string.format("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$__%s", res.status))
	local code = res.status
	assert(code==ngx.HTTP_BAD_REQUEST)
	r:del(string.format('black_%s',didCookie2))
	
	
	ngx.sleep(1)
	
	
	--有td_sid，有td_did，合法，ip和agent匹配，通过
	ngx.log(ngx.ERR, string.format("**************************proxy pass ***********************"))
	
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format('%s=%s',config.deviceIdCookieName, didCookie), globalCookieVal},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })

	local code = res.status
	local data = trim(res.body)
	assert(code==ngx.HTTP_OK)
	
	--ngx.log(ngx.ERR, string.format("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$__%s",data))
	
	assert(data==';callback(["1","",""]);')
	local count = r:lindex(string.format(config.didKey,didCookie2), 0)
	assert(tonumber(count)==1)
	local lastTs = r:get(string.format(config.dtsKey,didCookie2))
	assert(tonumber(lastTs))
	
	
	ngx.sleep(1)
	
	
	--有td_sid，有td_did，合法，ip和agent匹配，通过,计数器+1
	ngx.log(ngx.ERR, string.format("**************************proxy pass 2 ***********************"))

	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format('%s=%s',config.deviceIdCookieName, didCookie), globalCookieVal},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })

	local code = res.status
	local data = trim(res.body)
	assert(code==ngx.HTTP_OK)
	assert(data==';callback(["1","",""]);')
	local count = r:lindex(string.format(config.didKey,didCookie2), 0)
	assert(tonumber(count)==2)
	local lastTs = r:get(string.format(config.dtsKey,didCookie2))
	assert(tonumber(lastTs))
	
	ngx.sleep(1)
	
	
	--有td_sid，有td_did，合法，使用的是老的key通过，ip和agent匹配，通过,计数器+1
	ngx.log(ngx.ERR, string.format("**************************proxy pass use last key ***********************"))
	
	local globalAesKeyOld = '302702db952acfa2beb0563ded2da35a'
	local globalAesKeyNew = 'eeae72cc9b4574153aae686df5b4afa9'
	
	r:set(config.globalAesKey, globalAesKeyNew)
	r:set(config.lastGlobalAesKey, globalAesKeyOld)
	--设置之后重建缓存
	cachDict:set('lastUpdateTs', '0')
	local result = tools.rebuildCacheDict()
		
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format('%s=%s',config.deviceIdCookieName, didCookie), globalCookieVal},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })

	local code = res.status
	local data = trim(res.body)
	assert(code==ngx.HTTP_OK)
	assert(data==';callback(["1","",""]);')
	local count = r:lindex(string.format(config.didKey,didCookie2), 0)
	assert(tonumber(count)==3)
	local lastTs = r:get(string.format(config.dtsKey,didCookie2))
	assert(tonumber(lastTs))
	
	
	
	ngx.sleep(1)
	
	
	--有td_sid，有td_did，不合法，ip和agent匹配，通过,计数器+1，但是由于频率过高，被挡了400
	ngx.log(ngx.ERR, string.format("**************************proxy count too max ***********************"))
	
	r:lset(string.format(config.didKey,didCookie2), 0, 9999)
	
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format('%s=%s',config.deviceIdCookieName, didCookie), globalCookieVal},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })
	
	
	local code = res.status
	local data = trim(res.body)
	
	
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	local count = r:lindex(string.format(config.didKey,didCookie2), 0)
	
	assert(tonumber(count)==10000)
	local lastTs = r:get(string.format(config.dtsKey,didCookie2))
	assert(tonumber(lastTs))
	local countSets = r:scard(string.format(config.dipKey,'127.0.0.1'))
	assert(tonumber(countSets)==1)
	
	
	ngx.sleep(1)
	



	--有td_sid，有td_did，不合法，ip和agent匹配，通过,计数器+1，但是由于频率过高，被挡了400，使用本地的blackDict
	ngx.log(ngx.ERR, string.format("**************************proxy count too max ***********************"))
		
	local httpc = http.new()
	local res, err = httpc:request_uri(string.format("http://127.0.0.1%s", CHECK_URL_NO_JSONP), {
        method = "GET",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
		  ["Cookie"] = {string.format('%s=%s',config.deviceIdCookieName, didCookie), globalCookieVal},
		  ["referrer"] = 'http://127.0.0.1/',
        }
    })
	
	local code = res.status
	local data = trim(res.body)
	
	assert(code==ngx.HTTP_BAD_REQUEST)
	
	local countSets = r:scard(string.format(config.dipKey,'127.0.0.1'))
	assert(tonumber(countSets)==1)
	
	--ngx.log(ngx.ERR, string.format("@@@@@@@@@@@@@@@@@@@@@@@: %s", didCookie2))
	assert(blackDict:get(didCookie2)=='1')
	
	
	ngx.sleep(62)
	assert(not blackDict:get(didCookie2))
	
	
	ngx.say('proxy 方法测试 OK')
	
	
	
	--扫尾
	conn.close(r)
end



ngx.say('所有测试完毕')
ngx.exit(ngx.HTTP_OK)