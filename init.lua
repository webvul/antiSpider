--ngx_lua启动执行这里，将一些常用的数据缓存在此，避免每次request都去请求数据库，减少i/o
	
require "cjson"	--cjson库
require "ngx" --ngx库


--aes 加密相关
cachDict = ngx.shared.cachDict
cachDict:set('aeskey', '', 1)
cachDict:set('aessecret', '',1)

--总开关
local suc
suc = cachDict:set('state', '1',1)

--如果出错则记录初始化失败
if not suc then
    ngx.log(ngx.ERR, 'lua init failed')
end