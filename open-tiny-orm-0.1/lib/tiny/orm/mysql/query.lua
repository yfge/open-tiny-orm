-- mysql query的生成器
-- @author 拐 <geyf@knowbox.cn>
-- @version 1.0
-- @date Sep 27th,2018
-- 借签链式表达式的思路
---- 但是有一个问题，就是不能实现复杂的结构
local cfg_fac = require 'tiny.orm.mysql.cfg'
local mysql_con = require 'tiny.orm.mysql.connector'
local fac = require 'tiny.orm.mysql.factory'
local log = require 'tiny.log.helper'
local cjson = require 'cjson'
local _M = {}
_M.VERSION = "1.0"
local mt = { __index = _M }
-- 执行mysql
local function exec(con,sql)
	local res, err,errcode,state = con:query(sql)
	while err == 'again' do
		res,err,errcode,state = con:read_result()
	end
 	if (err) then
		log.info({msg='sql exeute err',err=err,sql=sql})
	end	
	if res then
		return res
	else 
		return 'error'
	end
end
function _M.create_select(model,filter,page,page_size)
    local set = ""
    local select = "select "
    local where = " from `" .. model.table_name.."`"
    for i,v in pairs(model._cols) do
        select = select .. " `" .. v .. "` ,"
    end
    select = string.sub(select , 1 ,string.len(select) - 1 )
    if nil ~= filter then 
	where = where .. ' where 1 = 1 and '
	for k,v in pairs(filter) do
		where = where .."`".. k .. '` = \'' .. v .. '\''
        end
    end  
    select = select .. where
    return select
end
-- 创建新建 
function _M:create_insert(item)
    local sql = 'INSERT ' ..self. model.table_name .. '('
    local params = ''
    local values = ""
    local pname = ""
    for i,v in pairs(self.model._cols) do
        if item[v] and v ~=  self.model._id_col  then
            sql = sql .. "`"..v .."`,"
            pname = "@"..v
            if item[v] == ngx.null or item[v]==nil then
            params = params .. "SET " .. pname .. " = null ; "
            else
            params = params .. "SET ".. pname .. " = ".. ngx.quote_sql_str(item[v])..";"
            end
            values = values .. pname ..","
        end
    end
    sql =string.sub(sql,1,#sql-1)
    sql = sql .. ") values (" .. string.sub(values,1,#values-1) .. ");"
    sql = params .. sql --.."select LAST_INSERT_ID();"
   	if self.model._source then 
        local con = fac:get_op_con(self.model._source)
        local res =  exec(con,sql)
        if res ~= nil then 
            local id = res.insert_id
            item[self.model._id_col] = id
            return true
        else 
            log.err('insert failed')
            return false
        end
    else 
		return sql
	end
end

function _M:create_update(item)
    local sql = 'update  ' ..self. model.table_name .. ' set '
    local params = ''
    local values = ""
    local pname = ""
    local filter = ""
    if item[self.model._id_col] == nil then
        return false
    else 
        filter = " where `"..self.model._id_col .."`=@"..self.model._id_col
        params = params .. "SET @".. self.model._id_col .. " = ".. ngx.quote_sql_str(item[self.model._id_col])..";"
    end
    for i,v in pairs(self.model._cols) do
        if item[v] and v ~=  self.model._id_col  then
            pname = "@"..v
            sql = sql .. "`"..v .."` = "..pname..","
            if item[v] ~= ngx.null and item[v] ~= nil then
                params = params .. "SET ".. pname .. " = ".. ngx.quote_sql_str(item[v])..";"
            else
                params = params .. "SET ".. pname .. " = null;"
            end
        end
    end
    sql =string.sub(sql,1,#sql-1)
    sql = sql .. filter .. ";"
    sql = params .. sql --.."select LAST_INSERT_ID();"
   	if self.model._source then
        local con = fac:get_op_con(self.model._source)
        local res =  exec(con,sql)
        if res ~= nil then
            return true
        else
            return false
        end
    else 
		return sql
	end
end
function _M:create_delete(item)
    local sql = 'delete from  ' ..self. model.table_name .. '  '
    local params = ''
    local values = ""
    local pname = ""
    local filter = ""
    if item[self.model._id_col] == nil then
        return false
    else 
        filter = " where `"..self.model._id_col .."`=@"..self.model._id_col
        params = params .. "SET @".. self.model._id_col .. " = ".. ngx.quote_sql_str(item[self.model._id_col])..";"
    end
    sql = sql .. filter .. ";"
    sql = params .. sql --.."select LAST_INSERT_ID();"
   	if self.model._source then
        local con = fac:get_op_con(self.model._source)
        local res =  exec(con,sql)
        if res ~= nil then
            return true
        else 
            return false
        end
    else 
		return sql
	end
end
-- 构造函数
function _M:new (model)
    local _ins = { model = model }
    setmetatable(_ins,mt)
    self = _ins
    return _ins
end
-- 增加where条件
function _M:where(...)
    local args = table.pack(...)
     local col , op ,value
     if args.n == 3 then
	    col ,op,value = ...
     end
     if args.n == 2 then
	    col ,value = ...
        op = '='
     end
     if nil ==  self.filter then
	    self.filter = {}
     end
        self.filter[#(self.filter)+1]={link = " and ",col=col,op=op,value=value}
     return self
end 
function _M:where_between(col,start_value,end_value)
	if nil == self.filter then
		self.filter = {}
	end
	self.filter [#self.filter + 1] = {link = ' and ' ,col = col ,op = '>=',value = start_value }
	self.filter [#self.filter + 1] = {link = ' and ' ,col = col ,op = '<' ,value = end_value }
	return self
end
-- 增加whereIn条件
function _M:where_in(col, array)
     if self.filter == nil then
	self.filter = {}
     end
     if #array > 0 then 
     	self.filter[#(self.filter)+1]={link = " and ", col=col,op='in',value =array}
     end
     return self
end
-- 得到选择列
function _M:select(cols)
	self.cols = cols
	return self
end
-- 增加order by
function _M:order_by(...)
	local args = table.pack(...)
	local col,by
	if args.n == 2 then
		col , by = ...
	elseif args.n == 1 then
		col = ...
		by  = 'asc'
	end	
	if self.orders == nil then
		self._order = {}
	end
	self._order[#self._order+1]={col = col , by = by }
	return self
end

local function create(m)
	local sql = "select "
	local cols = m.model._cols
	local params = ""
	if nil ~= m.cols then
		cols = m.cols
	end 
	for i, v in pairs(cols) do
		sql = sql .. " `"..v .. "`,"
	end 
	sql = string.sub(sql, 1 ,string.len(sql) -1 )
 	sql = sql .. " from `" .. m.model.table_name.."`"
	if nil ~= m.filter then
		sql = sql .. ' where 1 = 1 '
		for i , v in ipairs(m.filter) do
			if(v.op == 'in') then
				local a_values = ""
				for a_i,a_v in ipairs(v.value) do
					local sub_param = "@p"..i.."_"..a_i
					params = params .."set "..sub_param .." = "..ngx.quote_sql_str(a_v)..";"
					a_values = a_values .. sub_param..","
				end	
				sql = sql .. v.link .."`".. v.col .."` in  ("..string.sub(a_values,1,#a_values- 1)..")"
			else
				if v.value == nil or v.value == ngx.null then 
                    params =params.. "set @p"..i.." = null;"
                else
                    params =params.. "set @p"..i.." = "..ngx.quote_sql_str(v.value)..";"
				end
                sql = sql .. v.link .."`".. v.col .."`".. v.op .. '@p'..i
			end
		end
	end
	if  m._order then
		for _,v in pairs(m._order) do
			sql = sql .. ' order by '..v.col .. ' '..v.by .. ','
		end
		sql = string.sub(sql,1,#sql -1 )
	end
	if  m._size then
		sql = sql .. ' limit '.. m._size
		if m._offset then
			sql = sql .. ' offset ' .. m._offset
		end 
	end 
	sql = params .. sql
	if m.model._trace == true then
		log.trace(sql)
	end
	if m.model._source then
        local db = mysql_con:new(cfg_fac:get(m.model._source))
	    local con = db:connectBySlave()
        return exec(con,sql)
    else 
		return sql
	end
end
function _M:get()
	return create(self)
end
function _M:take(count)
	self._size = count
	return self
end
function _M:skip(count)
	self._offset = count
	return self
end
-- 得到符合条件的第一个数据
function _M:first()
	local items =create(self)
	if #items >=1 then
		return items[1]
	else
		return nil
	end
end
-- 得到分页结果
function _M:get_with_paging(page_index, page_size)
end
-- 得到查询的数量
function _M:get_count()
end
return _M
