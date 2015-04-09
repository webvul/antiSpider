module("redis_conn", package.seeall)

local redis = require "resty.redis"
local RedisConn = require "config"["connRedis"]


function conn()
		
	--直接连接
	local r = redis:new()
	r:set_timeout(2000) -- 2 second
	local ok, err = r:connect(RedisConn.host, RedisConn.port)
	
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

 