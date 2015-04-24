require "ngx" --ngx库

local config = require "config"
local tools = require "tools"
local conn = require "redis_conn"
local http = require "resty.http"
local cjson = require "cjson"

--测试deviceid是否有效的接口，内部使用
local args = ngx.req.get_uri_args()
local ip = args['ip'] or ''
ngx.log(ngx.INFO, string.format("TEST DID IP: %s", ip))
local agent = args['agent'] or ''
ngx.log(ngx.INFO, string.format("TEST DID AGENT: %s", agent))
local key = args['key'] or ''
ngx.log(ngx.INFO, string.format("TEST DID KEY: %s", key))
local iv = args['iv'] or ''
ngx.log(ngx.INFO, string.format("TEST DID IV: %s", iv))
local did = args['did'] or ''
ngx.log(ngx.INFO, string.format("TEST DID DID: %s", did))


--开始生成加密串did
local toEncryptStr = tools.sha256(ip..config.md5Gap..agent)
ngx.log(ngx.INFO, string.format("TEST DID toEncryptStr: %s", toEncryptStr))

--加密串
local aesStr = tools.aes128Encrypt(toEncryptStr, key)
ngx.log(ngx.INFO, string.format("TEST DID toEncryptStr: %s", toEncryptStr))

--解密串
local decodeDid
if did and did ~= '' then
	decodeDid = tools.aes128Decrypt(did, key)
	ngx.log(ngx.INFO, string.format("TEST DID decodeDid: %s", decodeDid))
else
	decodeDid = ''
end

local tmpTable = {
	ip=ip,
	agent=agent,
	key=key,
	iv=iv,
	nginx_toEncryptStr=toEncryptStr,
	nginx_aesStr=aesStr,
	client_decodeDid=decodeDid,
}

ngx.header["Content-Type"] = 'text/plain'
ngx.say(cjson.encode(tmpTable))
