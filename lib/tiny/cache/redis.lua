local M = {}
M._VERSION = "1.0"
local mt = {__index=M }

function M.new(self,config)
    local ins = self or {} 
    setmetatable(ins,mt)
    return mt
end

function M:set(key,ob)

end


function M:get(key)


end


return M

