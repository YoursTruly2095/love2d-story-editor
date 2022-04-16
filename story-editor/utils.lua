function split(str, sep)
    local t={}
    for s in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(t, s)
    end
    return t
end


function check_status(status_string, status)
    local statuses = split(status_string, ';')
    for _,v in ipairs(statuses) do
        local s = split(v,'=')
        if s[1] == status then 
            return tonumber(s[2]) or s[2] 
        end
    end
    return nil
end
   
   

local function split_op(req_table, req, op)
    local s,e = req:find(op,1,true)             -- plain string match
    if s then
        local key = req:sub(1,s-1)
        local val = req:sub(e+1)
        val = tonumber(val) or nil
        req_table[key] = {}
        req_table[key].val = val
        req_table[key].op = op
        return true
    end
    return false
end

function decode_req(req_table, req)
    if not ( 
        split_op(req_table, req, '=') or
        split_op(req_table, req, '==') or
        split_op(req_table, req, '>') or
        split_op(req_table, req, '<') ) then
        print("Error could not decode requirement "..req)
    end
end

function decode_results(req_table, req)
    if not (
        split_op(req_table, req, '+=') or
        split_op(req_table, req, '-=') or
        split_op(req_table, req, '=') or        -- must go after += and -= to avoid paring issues
        split_op(req_table, req, '++') or
        split_op(req_table, req, '--') ) then
        print("Error could not decode result "..req)
    end
end

function decode_status(req_table, req)
    if not ( 
        split_op(req_table, req, '=') ) then
        print("Error could not decode status "..req)
    end
end

function convert_op_string(reqs_string, decode_fn)
    local reqs = split(reqs_string,';')
    local req_table = {}
    for _,v in ipairs(reqs) do
        decode_fn(req_table, v)
    end
    return req_table
end

function check_reqs(reqs, player_status)
    local meets_reqs = true
    for k,req in pairs(reqs) do
        local status = nil
        if player_status[k] then status = player_status[k].val end
        if status==nil then status=0 end     -- allow 0 to match nil and visa versa
        
        if req.op == '=' or req.op == '==' and req.val ~= status then meets_reqs = false end
        if req.op == '>' and status <= req.val then meets_reqs = false end
        if req.op == '<' and status >= req.val then meets_reqs = false end
    
    end
    return meets_reqs
end

        
function apply_results(status, results)
    
    for k,result in pairs(results) do
        if status[k] == nil then 
            status[k] = {}
            status[k].val = 0
            status[k].op = '='
        end
        if result.op == '=' then
            status[k].val = result.val
        elseif result.op == '+=' then
            status[k].val = status[k].val + result.val
        elseif result.op == '-=' then
            status[k].val = status[k].val - result.val
        elseif result.op == '++' then
            status[k].val = status[k].val + 1
        elseif result.op == '--' then
            status[k].val = status[k].val - 1
        end
    end
    
    return status

end

        
-- basic deep copy
-- does not handle metatables 
-- does not handle recursive tables - class tables are recursive
function deep_copy(item)
    if type(item) ~= 'table' then 
        return item 
    end
    
    local copy = {}
    for k,v in pairs(item) do
        copy[k] = deep_copy(v)
    end
    
    return copy
end

function deep_copy_with_ignore(item, ignore)
    if type(item) ~= 'table' then 
        return item 
    end
    
    local copy = {}
    for k,v in pairs(item) do
        local do_copy = true
        for _,i in ipairs(ignore) do
            if k == i then
                do_copy = false
            end
        end
        if do_copy then copy[k] = deep_copy_with_ignore(v, ignore) end
    end
    
    return copy
end
