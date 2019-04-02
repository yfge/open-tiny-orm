-- mysql 的配置读取工具
-- 支持从配置读取或是串读取

local cfg = {}
function cfg:get_mysql_cfg(config)
    if type(config) == 'string' then
        return require('config.mysql')[config]
    else
        return config 
    end
end

function cfg:get_redis_cfg(config)
    if type(config) == "string" then
        return require('config.redis')[config]
    else
        return config
    end
end

return cfg 
