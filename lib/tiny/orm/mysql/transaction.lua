local mysql_cfg = require 'tiny.util.cfg'
local mysql_con = require 'tiny.orm.mysql.connector'
local log = require 'tiny.log.helper'
local M = {}
M._VERSION = "1.0"
local mt = { __index = M }
-- 执行 mysql
local function exec(con,sql)
	local res, err,errcode,state
    res, err,errcode,state = con:query(sql)
	while err == 'again' do
		res,err,errcode,state = con:read_result()
	end
    if (err) then
		log.info({msg='sql exeute err',err=err,sql=sql,errorcde = errcode,state = state})
	end
	if res then
		return res
	else
		return 'error'
	end
end
-- 初始化
function M.new()
    if ngx.ctx.ff_trans_ins == nil then
	    local ins = { _cons = {},trans = false }
	    setmetatable(ins,mt)
	    ngx.ctx.ff_trans_ins = ins
    end
    return ngx.ctx.ff_trans_ins
end
-- 开始
function M:start()
    self.trans = true
    for _,v in pairs(self._cons) do
        log.info('start. trans')
        exec(v,'start transaction')
    end
end
-- 提交
function M:commit()
    for _,v in pairs(self._cons) do
        exec(v,'commit')
    end
    self.trans = false
end
-- 判断是否在一个事务内
function M:is_in_trans()
    return self.trans
end
-- 回滚
function M:rollback()
    for _,v in pairs(self._cons) do
        exec(v,'rollback')
    end
   self.trans = false
end
-- 得到连接 内部使用
function M:get_con(cfg)
    if self._cons[cfg] == nil then
        local db =  mysql_con:new(mysql_cfg:get_mysql_cfg(cfg))
        self._cons[cfg] = db :connectByMaster()
        exec(self._cons[cfg] ,'start transaction')
    end
    return self._cons[cfg]
end
return M
