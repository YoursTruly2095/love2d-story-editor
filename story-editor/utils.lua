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
        if s[1] == status then return s[2] end
    end
    return nil
end
        
