-- mysql 连接管理
-- 管理当前上下文的连接
-- 用来控制trans
-- @author 拐 <geyunfei@gmail.com>
-- @version 1.0
-- @Date Nov 19th,2018
local cfg_fac = require 'tiny.util.cfg'
local mysql_con = require 'tiny.orm.mysql.connector'
local transaction = require 'tiny.orm.mysql.transaction'
local cjson = require "cjson.safe"
local fac = {}
-- 得到查询连接
function fac.get_query_con(_,cfg)
    local trans = transaction:new()
    if trans:is_in_trans() == false then
        local db = mysql_con:new(cfg_fac:get_mysql_cfg(cfg))
        local con = db:connect_by_slave()
        return con
    else
        return trans:get_con(cfg)
    end
end
-- 得到操作连接
function fac.get_op_con(_,cfg)
    local trans = transaction:new()
    if trans:is_in_trans() == false then
        local db = mysql_con:new(cfg_fac:get_mysql_cfg(cfg))
        local con = db:connect_by_master()
        return con
    else
        return trans:get_con(cfg)
    end
end


function fac.keep_alive_con(_,db,cfg)
    local trans = transaction:new()
    if trans:is_in_trans() == false then
        local ok, err = db:set_keepalive(cfg.pool.maxIdleTime, cfg.pool.size)
        if not ok then
            db:close()
        end
    end  

end
return fac
