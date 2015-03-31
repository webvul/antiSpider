require "ngx" --ngx库


local config = require "config"
local tools = require "tools"
local ck = require "resty.cookie"
local conn = require "redis_conn"
local checkState = require "check"['checkState']


function dealProxyPass()
	local args = ngx.req.get_uri_args()
	local tdcheck = args['_tdcheck']
	--如果开启了check
	if tdcheck == '1' then
		jsonpStr = tools.jsonp('1','1')
		ngx.say(jsonpStr)
		return ngx.exit(ngx.HTTP_OK)
	end

end

function erroResponse()
	local args = ngx.req.get_uri_args()
	local tdcheck = args['_tdcheck']
	--如果开启了check
	if tdcheck == '1' then
		jsonpStr = tools.jsonp('0','')
		ngx.say(jsonpStr)
		return ngx.exit(ngx.HTTP_OK)
	end
	ngx.exit(400)
end


--代理函数
function doProxy()

	--检查状态
	local gateStateVal, aesKey, aesSecret, remoteAgent, noAgent = checkState()
	--如果没有Agent，报错
	if noAgent then
		return erroResponse()
	end
	--如果 gateStateVal 为0，表示关闭验证，直接pass
	if gateStateVal == '0' then
		return dealProxyPass()
	end

	--定义变量
	local enterTime = tools.getNowTs()
	local remoteIp = ngx.var.remote_addr
	local remoteAgent = remoteAgent

	--判断sessioncookie是否有效
	local isValidCookie, err = tools.verifySessionCookie()
	--出错直接放过
	if err then
		return dealProxyPass()
	end
	if not isValidCookie then
		return erroResponse()
	end

	--判断deviceId是否有效
	local deviceId, err = tools.simpleVerifyDeviceId()
	if err then
		return dealProxyPass()
	end
	
	ngx.log(ngx.ERR, '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'..deviceId)
	
	if not deviceId or  deviceId == '' then
		ngx.log(ngx.ERR, string.format("verifyDeviceId not have deviceId"))
		return erroResponse()
	end
	
	ngx.log(ngx.ERR, '*************************************'..deviceId)
	--检查deviceId的值是否被篡改
	local trueDeviceContent = tools.aes128Decrypt(deviceId, aesKey)
	ngx.log(ngx.ERR, '*************************************'..trueDeviceContent)
	
	local didIpAgent = trueDeviceContent
	--检查ip地址是否合法
	if didIpAgent ~= tools.sha256(remoteIp..config.md5Gap..remoteAgent) then
		ngx.log(ngx.ERR, string.format("verifyDeviceId IP and agent not valid"))
		return erroResponse()
	end

	--下面进行redis连接后的检查
	local r, err = conn.conn()
	if err then
		--如果连接reids出错
		return dealProxyPass()
	end

	--检查此deviceid是否在黑名单中
	local blackKey = string.format('black_%s', deviceId)
	local isBlack = r:get(blackKey)
	--如果在黑名单中
	if isBlack then
		ngx.log(ngx.ERR, string.format("request in blackList, deviceId %s", deviceId))
		return erroResponse()
	end

	--检查此deviceid是否访问频率过快
	local didKey = string.format(config.didKey, deviceId)
	local dtsKey = string.format(config.dtsKey, deviceId)
	local dipKey = string.format(config.dipKey, remoteIp)

	--获取上一次请求时间
	local didTs = r:get(dtsKey)
	--如果没有找到这个deviceid上次请求的时间,则全部新建
	if not didTs then
		r:set(dtsKey, enterTime)
		r:ltrim(didKey,0,-1)
		r:lpush(didKey,1)
	else
		--如果存在上次请求
		r:set(dtsKey, enterTime)
		--如果上一次请求在10秒钟之内，最新片+1
		if enterTime - tonumber(didTs) <= config.freqSec then
			local count = tonumber(r:lindex(didKey)) + 1
			r:lset(didKey, 0, count)
		else
			--如果上一次请求在10秒钟之外,新建一个片
			r:lpush(didKey,1)
			r:ltrim(didKey, config.freqShard, -1)
		end
	end

	--进行访问频率判断
	--获得最新的6片数据
	didCountList = r:lrange(didKey, 0, config.freqShard)
	tempSum = 0
	for i = 1, config.freqShard, 1 do
		--记录每个分片的求和
		tempSum = tempSum + tonumber(didCountList[i])
		--当满足规则时，表示请求过于频繁
		if config.freqRule[i] ~= -1 and  tempSum >= config.freqRule[i] then
			ngx.log(ngx.ERR, string.format("request too freqency, deviceId %s", deviceId))
			return erroResponse()
		end
	end

	--将此deviceid存入ipkey中
	r:lpush(dipKey, deviceId)

	--更新redis的key的expire过期时间
	r:expire(dtsKey, 600)
	r:expire(didKey, 600)
	r:expire(dipKey, 3600)

	--记录时间，进行转发
	--如果超过1秒, 记录错误日志
	local dealTime = tools.getNowTs() - enterTime
	if dealTime > 1 then
		ngx.log(ngx.ERR, string.format("proxy deal too long : %s", dealTime))
	end

end

doProxy()
