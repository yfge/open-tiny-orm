local M = {}
M._VERSION = "1.0"
local cjson = require('cjson')
function M.new(self,config)
    local ins = self or {}
    local catlog = config.catlog
    if catlog ~= nil then 
        local shared = ngx.shared[catlog]
        ins.shared = shared 
        ins.expired = config.expired or 0 
        ins.key_pre = config.key_pre or ""
        setmetatable(ins,M)
        return ins
    else 
        return nil
    end
end

function M:set(key,ob)
    local set_key = self.key_pre .. tostring(key)
    local success,err,forcible =  self.shared:set(key,cjson.encode(ob),self.expired)
    return success 
end


function M:get(key)
    local set_key = self.key_pre .. tostring(key)
    local str = self.shared:get(set_key)
    if str then
        return cjson.decode(str) or str
    else
        return nil
    end
end



return M

