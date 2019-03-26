-- 日志处理类
-- @author 拐 <geyunfei@gmail.com>
-- -- @date Sep 19th,2018
-- -- @version 0.1
local debug = require('debug')
local json = require('cjson')
local _M = {}
local mt = { __index = _M }
local levels = { 'trace','debug','info','warn','err','fatal'}
local cjson = require "cjson.safe"
-- 初始化表
local function init_log(level)
	if not ngx.ctx.log_table then
		ngx.ctx.log_table = {}
    	end
	if not ngx.ctx.log_table [level] then
		ngx.ctx.log_table[level] = {}
	end
	return ngx.ctx.log_table[level]
end

-- 写入相应级别的日志
local function write_log(level,msg,i)
	local log = init_log(level)
	local info = debug.getinfo(3,'Sl')
	if msg == nil and i<=3 then
		return
	end
	local new_log
	if i>3 then
		new_log ={ msg = msg ,  module = info.short_src..' line '..info.currentline }
	else
		new_log =msg
       	end
	table.insert(log,new_log)
end
                                                                                                 -- 得到所有日志,并清空表
function _M.get_log()
	local logs = ngx.ctx.log_table
	ngx.ctx.log_table = nil
	return logs
end

for i = 1 , #levels do
	local cmd = levels [i]
	_M[cmd] = function (msg)
		write_log(cmd, msg,i)
	end
end

return _M
                                                                                                                                          
