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
    local redis_config = nil 
    if type(config) == "string" then
        redis_config = require('config.redis')[config]
    else
        redis_config = config
    end
    local instance = {
        timeout = redis_config.timeout or 1000,
        pool = redis_config.pool or {maxIdleTime = 120000, size = 200},
        clusters = redis_config.clusters or {},
        database = redis_config.database or 0,
        password = redis_config.password or "",
    }
    return instance
end

return cfg 
