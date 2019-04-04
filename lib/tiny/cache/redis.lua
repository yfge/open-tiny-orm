local cjson = require('cjson')
local cfg = require('tiny.util.cfg')
local connect = require('tiny.redis.connector')


local M = {}
M._VERSION = "1.0"
local mt = {__index=M }


function M.new(self,config)
    local ins = self or {} 
    ins.redis = connect:new(cfg:get_redis_cfg(config.redis))
    ins.key_pre = config.key_pre or ""
    ins.expired = config.expired or 0 
    setmetatable(ins,mt)
    return ins 
end

function M:set(key,ob)
    local set_key = self.key_pre .. tostring(key) 
    local rd = self.redis:connect_by_key(set_key) 
    
    local suc,msg 
    if not rd then 
        return false 
    end
    local str = cjson .encode(ob)
    suc,msg = rd:set(set_key,str)
    if self.expired > 0 then
        suc ,msg = rd:expire(set_key,self.expired) 
    end
end


function M:get(key)
    local set_key = self.key_pre .. tostring(key)
    local rd = self.redis:connect_by_key(set_key)
    if rd then 
        local str = rd:get(set_key)
        self.redis:keep_alive(rd)
        if str then 
            return cjson.decode(str) or str
        else 
            return nil
        end
    end
    return nil
end

function M:del(key)
    local set_key = self.key_pre .. tostring(key) 
    local rd = self.redis:connect_by_key(set_key)
    if rd then 
        local res = rd:del(set_key)
        self.redis:keep_alive(rd)
        return res
    end
    return false 
end



return M

