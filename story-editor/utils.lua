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
        
function check_reqs(reqs_string, player_status_string)
    local meets_reqs = true
    local reqs = split(reqs_string,';')
    for k,v in ipairs(reqs) do
        local req = split(v,'=')
        req[2] = tonumber(req[2]) or req[2]
        if req[2]=='nil' then req[2]=nil end                        -- allow the string 'nil'
        local status = check_status(player_status_string, req[1])
        if status==nil then if req[2]==0 then req[2]=nil end end    -- allow 0 to match nil and visa versa
        if req[2] ~= status then
            meets_reqs = false
        end
    end
    return meets_reqs
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
