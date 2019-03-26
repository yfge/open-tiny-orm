local _M = {}
_M.VERSION = "1.0"
local mt = { __index = _M }
function _M.new(_,table_name,cols,source,id_col)
	local _ins = { table_name = table_name , _cols=cols,_source = source  }
	if id_col == nil then
		_ins._id_col = 'id'
	else
		_ins._id_col = id_col
	end
	setmetatable(_ins, mt)
	return _ins
end
return _M
