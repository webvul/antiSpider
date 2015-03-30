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

aesPrivateKey = 'F06DA4A3DF28030E80FAEA2E3A7726CC'
sessionKey = '7A6913620518EDFF3502427AF2CCF7ED17961AF2DD3ED280E909652F58B741E2'
sessionName = 'td_ssid'
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