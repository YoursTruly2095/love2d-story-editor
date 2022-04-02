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
