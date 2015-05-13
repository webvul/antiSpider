--ngx_lua启动执行这里，将一些常用的数据缓存在此，避免每次request都去请求数据库，减少i/o
	
require "cjson"	--cjson库
require "ngx" --ngx库



--初始化重建所有缓存
--local initResult = tools.rebuildCacheDict()
--if not initResult then
--	ngx.log(ngx.ERR, string.format("initLua rebuildCacheDict error"))
--end


