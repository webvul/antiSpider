module("config", package.seeall)

--redis地址ip配置
connRedis = {
	host={'127.0.0.1'},
	port=6379,
	pool=100,
	max_idle_timeout=1000*10,
}

--session加密的秘钥
sessionKey = ''
--session的cookie名称
sessionName = 'td_sid'
--加密session的过期时间
sessionMaxAge = 3600*25
--deviceid的cookie名称
deviceIdCookieName = ''

--访问频率限制配置
--访问每片10秒钟
freqSec = 10
--一共分6片
freqShard = 6
--频率限制数组，长度需和 freqShard 相同
freqRule = {10,-1,15,-1,-1,20}

--redis的device的key
didKey = 'did_%s'
--redis的device上次请求时间的key
dtsKey = 'dtx_%s'
--redis的ip的key
dipKey = 'dip_%s'

--全局状态开关的redis的key（注意保持48小时内不能修改超过1次，否则会造成用户无法访问的情况）
globalStateKey = 'state'
--全局aes公钥的redis的key
globalAesKey = 'aeskey'
--全局公钥项量值（上线后勿修改）
globalAesIv = ''
--上一次aes公钥的redis的key
lastGlobalAesKey = 'aeskey_last'

md5Gap = ''

referrerList = {
	'127.0.0.1',
}

--agent中的黑名单
blackAgent = {
	'jakarta',
	'java',
	'python',
	'HttpClient',
	'WinHttp',
}


ipWhiteList = {
	'127.0.0.1',
}

internalList = {
	'127.0.0.1',
}





