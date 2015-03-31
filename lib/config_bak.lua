module("config", package.seeall)

connTable = {
	host='192.168.28.27',
	port=3306,
	database='try_game4',
	user='root',
	password='123456',
}

connRedis = {
	host='192.168.20.62',
	port=6379,
	pool=100,
	max_idle_timeout=1000*10,
}

aesPrivateKey = '123'
sessionKey = '123'
sessionName = '123'
sessionExpire = "Wed, 09 Jun 2099 10:18:14 GMT"
sessionMaxAge = 3600*24*365*10

deviceIdCookieName = 'td_did'

freqSec = 10
freqShard = 6
freqRule = [10,-1,15,-1,20]

didKey = 'did_%s'
dtsKey = 'dtx_%s'
dipKey = 'dip_%s'

globalStateKey = 'state'
globalAesKey = 'aeskey'
globalAesSecret = 'aesSecret'

md5Gap = '&@'



ipWhiteList = [
'127.0.0.1',
]