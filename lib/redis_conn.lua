module("redis_conn", package.seeall)

local redis = require "resty.redis"
local RedisConn = require "config"["connRedis"]
local chash = require "chash" 
local cjson = require "cjson" 

--初始化函数
local useUpstream = false
function dealRedisServer()

	if type(RedisConn.host) == 'string' then
		ngx.log(ngx.INFO, "redis host single " .. RedisConn.host)
		useUpstream = false
	elseif type(RedisConn.host) == 'table' then --如果配置文件是一个table
		ngx.log(ngx.INFO, "redis host upstream " .. cjson.encode(RedisConn.host))
		--如果连接host是table，则循环加入一致性哈希集群
		useUpstream = true
		for i,v in ipairs(RedisConn.host) do
			chash.add_upstream(v)
		end
	end
end



--redis连接抽象层
function conn(deviceId)
	local deviceId = deviceId or false
	
	--如果是单机器连接
	if not useUpstream then
		return _conn(RedisConn.host)
	else
		--如果是多机器集群
		local upstreamHost
		
		if not deviceId then --如果不带deviceid的连接，则全部保存在host[1]上
			upstreamHost = RedisConn.host[1]
		else
			upstreamHost = chash.get_upstream(deviceId)
		end
		
		ngx.log(ngx.INFO, string.format('redis host upstream deviceId %s, host %s', deviceId, upstreamHost))
		return _conn(upstreamHost)
	end
	


end

--真正连接的函数
function _conn(host)

	--直接连接
	local r = redis:new()
	r:set_timeout(1000) -- 2 second
	local ok, err = r:connect(host, RedisConn.port)
	
	if not ok then
		ngx.log(ngx.ERR, "redis library error " .. err) --出错记录错误日志，无法连接redis
		return nil, err
	end
	
	return r, nil

end



function close(r) --关闭redis连接封装
	 local ok, err = r:set_keepalive(RedisConn.max_idle_timeout, RedisConn.pool) --将本链接放入连接池
	 if not ok then  --如果设置连接池出错
		ngx.log(ngx.ERR, "redis failed to back connect pool: " .. err) 
	 end
end


dealRedisServer()
 