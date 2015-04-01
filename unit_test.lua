--测试用例
require "ngx" --ngx库

local config = require "config"
local tools = require "tools"
local conn = require "redis_conn"


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




--测试生成key的方法
do   

	
end




do   --发送不存在的sign请求

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body="aaa=111"})


local code = res.status
local data = trim(res.body)


--ngx.log(ngx.ERR, cjson.encode(res))


ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10003,"error":"sign not given"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送不存在的sign请求，测试完毕')


end




do   --发送不存在的client_id请求
ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")

local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body="sign=111"})


local code = res.status
local data = trim(res.body)

ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10005,"error":"client_id not given"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送不存在的client_id请求，测试完毕')

end





do   --发送无效的client_id请求

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")

local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body="sign=111&client_id=aaa"})

local code = res.status
local data = trim(res.body)


ngx.say("code == 401 : "..tostring(assert(code==401)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10006,"error":"client_id not Authorize"}'

ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送无效的client_id请求，测试完毕')


end



do   --使用GET方式发送


ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_GET})

local code = res.status
local data = trim(res.body)

ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10010,"error":"method not allowed"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('使用GET方式发送，测试完毕')



end



do   --发送错误的sign签名

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")

local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body="sign=111&client_id=test1"})

local code = res.status
local data = trim(res.body)


ngx.say("code == 401 : "..tostring(assert(code==401)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10004,"error":"invalid sign"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送错误的sign签名，测试完毕')


end


do   --转发ip地址
ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body=DEFAULT_FORM_STR})

local code = res.status
local data = trim(res.body)

ngx.say("code == 503 or 200 : "..tostring(assert(code==503 or code==200)))
ngx.say('转发ip地址，测试完毕')

end



do   --使用json发送数据
ngx.req.set_header("Content-Type", "application/json")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body=DEFAULT_JSON_STR})

local code = res.status
local data = trim(res.body)

--ngx.log(ngx.ERR, cjson.encode(res))

ngx.say("code == 503 or 200 : "..tostring(assert(code==503 or code==200)))
ngx.say('使用json发送数据，测试完毕')

end


do   --错误的json发送数据

ngx.req.set_header("Content-Type", "application/json")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body=DEFAULT_JSON_STR.."12312312"})

local code = res.status
local data = trim(res.body)

ngx.log(ngx.ERR, cjson.encode(res))


ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10013,"error":"param error"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('错误的json发送数据，测试完毕')

end



do   --错误的x-www-form发送数据

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body=DEFAULT_JSON_STR})

local code = res.status
local data = trim(res.body)

ngx.log(ngx.ERR, cjson.encode(res))


ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10003,"error":"sign not given"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('错误的x-www-form发送数据，测试完毕')

end


do   --重建缓存

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture("/rebuild",{method=ngx.HTTP_GET})

local code = res.status
local data = trim(res.body)


ngx.say("code == 200 : "..tostring(assert(code==200)))
local str = 'rebuild cache success'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('重建缓存，测试完毕')

end


do   --后端服务器

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture("/status",{method=ngx.HTTP_GET})

local code = res.status
local data = trim(res.body)


ngx.say("code == 200 : "..tostring(assert(code==200)))
assert(data ~= "")
ngx.say('后端服务器状态，测试完毕')

end

ngx.say('所有测试完毕')
ngx.exit(ngx.HTTP_OK)