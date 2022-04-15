-- suit up

local suit = require("suit")
require("utils")
--local json = require("json")
--local bitser = require("bitser")
local smallfolk = require 'smallfolk'

editor = {}

local data =
{
    -- story nodes
    {
--        display_level = { {text={""}} },
        display_level = {},
        display_offset = {},
        
        story =     
        {
            -- alternate story text at each node
            {
                id = 100,
                text =      { text={""} }, 
                reqs =      { text={""} } 
            }
        },
        
        options = 
        {
            -- multiple options at each node
            {
                id = 101,
                text =      { text={""} },
                reqs =      { text={""} },
                results =   { text={""} }
            }
        }
    }
}

local filename = "...none..."
local editable_filename = { text={""} }

local scroll_offset = 0
local story_node = 1
local story_alt = 1
local id_register = 101

local mode = 'normal'
local normal_mode = 'edit'
local player_status = { text={""} }

local button_locations = {}

function editor:load()
    -- make love use font which support CJK text
    local font = love.graphics.newFont("Courier Prime.ttf", 16)
    love.graphics.setFont(font)
    love.keyboard.setKeyRepeat(true)
end

function editor:update()
    -- all the UI is defined in love.update or functions that are called from it
	
    local function load_file()
        if filename == '...none...' then return end
        local load_string
        local length
        load_string, length = love.filesystem.read(filename)
        if length > 0 then
            local load_data = smallfolk.loads(load_string)
            -- validate??
            data = deep_copy(load_data)
            story_node = 1
            story_alt = 1
            -- need to update the id register too
            mode = 'normal'
        end
        
        for n,node in pairs(data) do
            -- file conversion
            if not node.display_level then node.display_level = {} end
            if not node.display_offset then node.display_offset = {} end
            
            -- id_register update
            for s,story in pairs(node.story) do
                if story.id >= id_register then id_register = story.id + 1 end
            end
            
            for o,opt in pairs(node.options) do
                if opt.id >= id_register then id_register = opt.id + 1 end
            end
            
        end
    end
        
    local function save_file() 
        if filename == '...none...' then mode = 'saveas' return end
        local save_data = deep_copy_with_ignore(data, {'cursor','cursorline','select','text_draw_offset'})
--        local save_string = json.encode(save_data)
--        local new_save_data = json.decode(save_string)
        local save_string = smallfolk.dumps(save_data)
        local new_save_data = smallfolk.loads(save_string)
        
        local success
        local message
        success, message = love.filesystem.write(filename, save_string)
        if not success then 
            print("Save failed: "..message) 
        else
            print("Saved")
        end
        mode = 'normal'
    end

    local function load_screen()
        -- display a list of files that could be loaded
        -- allow a file to be selected
        -- have a cancel button also
        
        local function lload()
            -- validate the filename
            -- copy it to 'filename' variable
            filename = editable_filename.text[1]
            load_file()
        end
        
        -- or for now...
        suit.layout:reset(25,25,25)
        suit.Label("filename",suit.layout:col(100,40))
        suit.Input(editable_filename, suit.layout:col(600,40))
        
        -- load and cancel buttons
        suit.layout:reset(25,870,25)
        if suit.Button("Load", suit.layout:row(150,70)).hit then lload() end
        if suit.Button("Cancel", suit.layout:row(150,70)).hit then mode = 'normal' end
        
    end
    
    local function save_screen()
        -- display a list of filenames that could be used (?)
        -- allow typing of a new filename
        
        local function save()
            -- validate the filename
            -- copy it to 'filename' variable
            filename = editable_filename.text[1]
            save_file()
        end
        
        
        suit.layout:reset(25,25,25)
        suit.Label("filename",suit.layout:col(100,40))
        suit.Input(editable_filename, suit.layout:col(600,40))
        
        
        -- save and cancel buttons
        suit.layout:reset(25,870,25)
        if suit.Button("Save", suit.layout:row(150,70)).hit then save() end
        if suit.Button("Cancel", suit.layout:row(150,70)).hit then mode = 'normal' end
    end
    
    local function quit_screen()
        
        local function quit()
            love.event.quit()
        end
        
        suit.layout:reset(25,25,25)
        suit.Label("All unsaved data will be lost upon quit!",suit.layout:col(900,40))
        
        -- save and cancel buttons
        suit.layout:reset(25,870,25)
        if suit.Button("Quit", suit.layout:row(150,70)).hit then quit() end
        if suit.Button("Cancel", suit.layout:row(150,70)).hit then mode = 'normal' end
    end
        
    
    if mode == 'load' then load_screen() return end
    if mode == 'saveas' then save_screen() return end
    if mode == 'quit' then quit_screen() return end
    
    -- NORMAL MODE
    -- load and save buttons
    suit.layout:reset(25,900,15)
    if suit.Button("Load", suit.layout:row(150,40)).hit then mode = 'load' end
    if suit.Button("Save", suit.layout:row(150,40)).hit then save_file() end
    if suit.Button("Save As", suit.layout:row(150,40)).hit then mode = 'saveas' end
    suit.layout:padding(0)
    suit.layout:up(0, 55)
    suit.layout:right(180, 0)        -- I don't understand why these values work but whatever
    suit.Label("filename",suit.layout:col(100,40))
    suit.Label(filename, {align='left'}, suit.layout:col(600,40))
    suit.layout:padding(25)
    
    -- quit button
    suit.layout:reset(800,1000,15)
    if suit.Button("Quit", suit.layout:row(150,40)).hit then mode = 'quit' end
        
    local story = data[story_node].story
    local options = data[story_node].options
    local lw = 80                   -- label width
    
    if normal_mode == 'play' then
        
        local function pick_alt()
            story_alt = 1           -- default
            
            -- the last alternative that satisfies requirements is picked
            if #story > 1 then
                for n=2,#story do
                    local reqs = convert_op_string(story[n].reqs.text[1], decode_req)
                    local status = convert_op_string(player_status.text[1], decode_status)
                    
                    if check_reqs(reqs,status)  then
                        story_alt = n
                    end
                end
            end
        end
        
        local function check_option(opt)
            local reqs = convert_op_string(opt.reqs.text[1], decode_req)
            local status = convert_op_string(player_status.text[1], decode_status)
            return check_reqs(reqs,status) 
        end
        
        local function do_option(opt) 
            
            -- apply results
--[[
            local _results = split(opt.results.text[1], ';')
            local _status = split(player_status.text[1], ';')
            local results = {}
            local status = {}
            
            for _,_v in ipairs(_results) do
                local t = split(_v,'=')
                if t[1] ~= 'node' then results[t[1] ]=t[2] end
            end
            
            for _,_v in ipairs(_status) do
                local t = split(_v,'=')
                status[t[1] ]=t[2]
            end
--]]            
            local results = convert_op_string(opt.results.text[1], decode_results)
            local status = convert_op_string(player_status.text[1], decode_status)
            
            if results.node then 
                story_node = results.node.val
                results.node = nil
            end
            
            
            status = apply_results(status, results)
            
--[[    
           
            for k,result in pairs(results) do
                if status[k] == nil then 
                    status[k] = result 
                else
                    status[k] = tostring(status[k]+result)
                end
            end
--]]
            local status_string = ""
            for k,v in pairs(status) do
                status_string = status_string..k..v.op..v.val..";"
            end
            player_status.text[1] = status_string
--[[            
            local new_node = check_status(opt.results.text[1], 'node')
            if new_node then story_node = new_node end
--]]            
        end
        
        -- play instead of editing
        -- edit mode button
        suit.layout:reset(600,1000,15)
        if suit.Button("Edit", suit.layout:row(150,40)).hit then normal_mode = 'edit' end
        suit.layout:reset(400,1000,15)
        if suit.Button("Reset", suit.layout:row(150,40)).hit then story_node = 1 end
        
        -- the layout will grow down and to the right from this point
        suit.layout:reset(25,25,25)
        suit.Label("Player", suit.layout:row(150, 25))
        suit.layout:padding(0)
        suit.Label("Status", suit.layout:row(150, 25))
        suit.layout:up(0,25)
        suit.layout:right(175,0)    
        suit.Input(player_status, suit.layout:col(700,265))
        
        suit.layout:reset(25,320,25)
        suit.Label("Story", suit.layout:row(150, 25))
        suit.layout:padding(0)
        suit.Label("(node"..story_node..")(alt"..story_alt..")", suit.layout:row(150, 25))
        suit.layout:up(0,25)
        suit.layout:right(175,0)    
        -- pick the story alt depending on the player status
        pick_alt()
        suit.Input(story[story_alt].text, suit.layout:col(700,265))

        suit.layout:reset(25,615,25)
        suit.Label("Options", suit.layout:row(150, 25))
        suit.layout:reset(200,615,0)
        for k,v in ipairs(options) do
            -- only add options if the player status is appropriate
            if check_option(v) then
                if suit.Button(v.text.text[1], suit.layout:row(700,35)).hit then do_option(v) end
            end
        end

    else
        -- play mode button
        suit.layout:reset(600,1000,15)
        if suit.Button("Play", suit.layout:row(150,40)).hit then normal_mode = 'play' end
        
        local function new_id()
            id_register = id_register + 1
            return id_register
        end
        
        
        -- STORY
        local function new_alt_story() 
            table.insert(story, 
                {
                    id =        new_id(),
                    text =      { {text={""}} },
                    reqs =      { {text={""}} },
                })
            story_alt = #story
        end

        local function story_left() 
            if story_alt > 1 then story_alt = story_alt - 1 end
        end
        local function story_right() 
            if story_alt < #story then story_alt = story_alt + 1 end
        end
        local function story_up() 
            -- move up a node
            -- need to look up which is the node above
            -- there may be multiple options...?
            -- maybe this button makes no sense?
            -- maybe node navigation should be via the node map only?
            -- perhaps I should add something in here temporarily
            -- or maybe we should go up to the first available
            -- or maintain a stack and go up to the one we came from
            
            -- simple version
            -- search for any node with any option that leads to the current node
            for k,v in ipairs(data) do
                for k2,v2 in ipairs(v.options) do
                    local node = check_status(v2.results.text[1], 'node')
                    if node==story_node then 
                        story_node=k 
                        story_alt=1
                        return 
                    end
                end
            end
       
        end
        
        -- the layout will grow down and to the right from this point
        suit.layout:reset(25,25,25)
        
        -- put an input widget at the layout origin, with a cell size of 200 by 30 pixels
        suit.Label("Story", suit.layout:row(150, 25))
        suit.layout:padding(0)
        suit.Label("(node"..story_node..")(alt"..story_alt..")", suit.layout:row(150, 25))
        suit.layout:padding(15)

        if suit.Button("New Alt", suit.layout:row(150,40)).hit then new_alt_story() end
        
        suit.Label("", suit.layout:row(50, 50))     -- invisible label as spacer
        suit.layout:padding(0)
        if suit.Button("U", suit.layout:col(50,50)).hit then story_up() end
        suit.layout:left(50, 50)
        if suit.Button("L", suit.layout:row(50,50)).hit then story_left() end
        suit.layout:padding(50)
        if suit.Button("R", suit.layout:col(50,50)).hit then story_right() end
        --suit.layout:padding(0)
        --suit.layout:left(50, 50)
        --if suit.Button("D", suit.layout:row(50,50)).hit then story_down() end
        suit.layout:padding(15)
        
        suit.layout:left(100, 50)        -- I don't understand why these values work but whatever
        suit.Label("lvl",suit.layout:row(35,35))
        suit.layout:padding(0)
        suit.Input(data[story_node].display_level, suit.layout:col(35,35))
        suit.layout:padding(10)
        suit.Label("off",suit.layout:col(35,35))
        suit.layout:padding(0)
        suit.Input(data[story_node].display_offset, suit.layout:col(50,35))
        
        suit.layout:up(0, 245)
        suit.layout:right(75, 0)        -- I don't understand why these values work but whatever
        
        suit.Input(story[story_alt].text, suit.layout:col(700,265))
        suit.Label("reqs",suit.layout:row(lw,35))
        suit.Input(story[story_alt].reqs, suit.layout:col(700-lw,35))
        
        
        -- OPTIONS
        local options_to_display=4
        
        local function new_node(k)
            table.insert(data,
                {
                    story =     
                    {
                        -- alternate story text at each node
                        {
                            id = new_id(),
                            text =      { text={""} }, 
                            reqs =      { text={""} } 
                        }
                    },
                    
                    options = 
                    {
                        -- multiple options at each node
                        {
                            id = new_id(),
                            text =      { text={""} },
                            reqs =      { text={""} },
                            results =   { text={""} }
                        }
                    }
                })
            
            local results = options[k].results.text[1]
            options[k].results.text[1] = "node="..#data..";"..results
            story_node = #data
            story_alt = 1
        end
        
        local function node(k)
            local results = options[k].results.text[1]
            local node = check_status(results, "node")
            if node == nil then
                new_node(k)
            else
                story_node = node
            end
        end
            
        local function delete(which)
            if #options > 1 then
                table.remove(options, which)
                
                -- fix scroll offset
                if scroll_offset > #options-options_to_display then scroll_offset = #options-options_to_display end
                if scroll_offset < 0 then scroll_offset = 0 end
            end
        end
        
        local function insert(where,which)
            table.insert(options,where,options[which])
        end
        
        local function new_option()
            table.insert(options, 
                {
                    id =        new_id(),
                    text =      { {text={""}} },
                    reqs =      { {text={""}} },
                    results =   { {text={""}} }
                })
                
            -- set the scroll offset so the new option is visible
            scroll_offset = #options-options_to_display
            if scroll_offset < 0 then scroll_offset = 0 end
        end
        
        local function up(k)
            if k > 1  and #options > 1 then
                insert(k-1, k)
                delete(k+1)
            end
        end
        
        local function down(k)
            if k < #options and #options > 1 then
                insert(k+2, k)
                delete(k)
            end
        end
        
        local function scroll(dir)
            if dir == 'up' then
                if scroll_offset > 0 then
                    scroll_offset = scroll_offset - 1
                end
            else
                if scroll_offset < #options-options_to_display then
                    scroll_offset = scroll_offset + 1
                end
            end
        end
        
                
                
        
        local tw = 700-50-50-25-25-80   -- text width
        
        suit.layout:reset(25,350,25)
        
        local function entry(k)
            suit.Label("opt"..k,suit.layout:col(lw,35))
            suit.layout:padding(0)
            suit.Input(options[k].text, suit.layout:col(tw,35))
            suit.layout:left(lw)
            suit.Label("reqs",suit.layout:row(lw,35))
            suit.Input(options[k].reqs, suit.layout:col(tw,35))
            suit.layout:left(lw)
            suit.Label("result",suit.layout:row(lw,35))
            suit.Input(options[k].results, suit.layout:col(tw,35))
            suit.layout:up(tw,70)
            suit.layout:padding(25)
            
            -- check out the horrible construct below
            -- we're using 'else' to make sure we don;t process the other buttons if one actually gets hit
            if suit.Button("Del", {id="B"..options[k].id}, suit.layout:col(50,52)).hit then delete(k) else
            suit.layout:padding(0)
            if suit.Button("Node", {id="N"..options[k].id}, suit.layout:row(50,53)).hit then node(k) else
            suit.layout:up(50,52)
            suit.layout:padding(25)
            if suit.Button("U", {id="U"..options[k].id}, suit.layout:col(50,52)).hit then up(k) else
            suit.layout:padding(0)
            if suit.Button("D", {id="D"..options[k].id}, suit.layout:row(50,53)).hit then down(k) end end end end
        end

        -- this must be a while loop not a for loop, because the BIN button 
        -- can change the length of value of #options
        local k=1
        while k <= math.min(#options, options_to_display) do -- we cannot calculate this prior to the loop!!
            suit.layout:reset(25,350+(130*(k-1)),25)
            if k == 1 then
                if suit.Button("New Option", suit.layout:row(150,70)).hit then new_option() end
            elseif k == 2 and #options > options_to_display then
                suit.layout:col(50,70)
                suit.layout:padding(0)
                if suit.Button("SU", suit.layout:col(50,52)).hit then scroll('up') end
                if suit.Button("SD", suit.layout:row(50,53)).hit then scroll('down') end
                suit.layout:up(50,53)
                suit.layout:col(50,70)
                suit.layout:padding(25)
            else
                suit.layout:row(150,70)
            end
            entry(k+scroll_offset)
            k = k + 1
        end
    end -- edit mode

    -- STORY MAP
    local map_offset = 920
    local map_width = 1000
    local button_width = 100
    
    local function navigate(node)
        story_node = node
        story_alt = 1
    end
        
	
    
--[[        
    if #data > 1 then
        -- for all other nodes, need to work out what the deepest level is
        -- this is really problematic because of potential looping
        local level = {1}
        for node = 2, #data do
            -- check which nodes lead to this node
            for psn in 1, #data do  -- potential source node
                if psn ~= node then
                    for k, v in ipairs(data[psn].options) do
                        local results = v.results.text[1]
                        local dn = check_status(results, "node")    -- destination node
                        if dn == node then
                            -- this potential source node actually is a real source node!
                            if level[psn] and level[node] == nil or level[node] <= level[psn] then
                                level[node] = level[psn]+1
                            end
                        end
                    end
                end
            end
        end
--]]
        
        -- try looking at levels instead??
        -- all nodes that are only sourced from level 1 are at level 2
        -- if there are no such nodes, but there are still unassigned nodes... oops!
            -- in this case, pick a node that is accessed from level 1 and call it level 2
    
    local node_levels = {}

    if #data > 1 then
--[[        
        local unassigned_nodes = {} --#data-1
        unassigned_nodes[1] = false
        for n=2,#data do
            unassigned_nodes[n] = true
        end
        
        local function any_node_unassigned()
            for _,v in ipairs(unassigned_nodes) do
                if v == false then return true end
            end
            return false
        end
--]]        
        node_levels[1] = 1
        for n=2,#data do
            local level = nil
            if data[n].display_level and data[n].display_level.text then level = tonumber(data[n].display_level.text[1]) end
            node_levels[n] = level or '?'
        end
        
        local function any_node_unassigned()
            for _,v in ipairs(node_levels) do
                if v == '?' then return true end
            end
            return false
        end
        
        local level = 2
        while any_node_unassigned() do
            -- search for nodes at the current level
            -- nodes at the current level are those which only have links from levels above
            local found_node = false
            
            for cn,current_node in ipairs(data) do
                if node_levels[cn] == '?' then
                    local potential_level = nil
                    for psn,potential_source_node in ipairs(data) do
                        if psn ~= cn then
                            for o,option in ipairs(potential_source_node.options) do
                                if potential_level ~= '?' then
                                    local destination_node = check_status(option.results.text[1], 'node')
                                    if destination_node == cn then
                                        -- the potential_source_node is an actual source node!
                                        -- if the level of the source node is unknown, then our level is unknown
                                        if node_levels[psn] == '?' then
                                            potential_level = '?'
                                            found_node = false
                                        elseif potential_level == nil or (potential_level < (node_levels[psn]+1)) then
                                            potential_level = node_levels[psn]+1
                                            found_node = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if potential_level == nil then 
                        --print ("ERROR") 
                        -- disconnected node, put at the top 
                        potential_level = 1
                    end
                    
                    node_levels[cn] = potential_level
                end
            end
            
            if not found_node then
                -- assign the first unassigned node to the first unused level and carry on
                local deepest_level = 0
                for _,v in ipairs(node_levels) do
                    if v ~= '?' and v>deepest_level then 
                        deepest_level = v
                    end
                end
                
                for k,v in ipairs(node_levels) do
                    if v == '?' then 
                        node_levels[k]=deepest_level + 1
                        break
                    end
                end
                
            end
            
                        
        end
        

    end
     
    -- actually draw the map
    for level = 1, 10 do
    
        local buttons = {}
           
        for k,v in ipairs(node_levels) do
            if v == level then
                table.insert(buttons, k)
            end
        end
            
        local gap_width = (map_width - (button_width*#buttons)) / ((#buttons)+1)
        
        for k,v in ipairs(buttons) do
            
            local offset = map_offset + (gap_width*k) + (button_width*(k-1))
            
            local display_offset
            if data[v].display_offset and data[v].display_offset.text then display_offset = tonumber(data[v].display_offset.text[1]) end
            display_offset = (display_offset or 0) * 10
            
            suit.layout:reset(offset+display_offset, 25 + (level-1)*100)
            button_locations[v]={offset+(button_width*0.5)+display_offset, 45+(level-1)*100}
            if suit.Button(v.." (1-"..#data[v].story..")", suit.layout:col(button_width,40)).hit then navigate(v) end
        end    
    end
    

end

function editor:draw()

    -- draw lines between buttons to be options
    for n, node in ipairs(data) do
        for o, option in ipairs(node.options) do
            local destination_node = check_status(option.results.text[1], 'node')
            if destination_node ~= nil and button_locations[n] and button_locations[destination_node] then
                -- draw an arrow for node to destination_node
                love.graphics.line(button_locations[n][1],button_locations[n][2]+20,
                    button_locations[destination_node][1], button_locations[destination_node][2])
            end
        end
    end
    
    suit.draw()

end


-- redirect some love UI functions

function love.textedited(text, start, length)
    -- for IME input
    --suit.textedited(text, start, length)
    if length > 0 then
        print("IME " .. text .. " " .. start .. " " .. length)
    end
end

function love.textinput(t)
	-- forward text input to SUIT
	suit.textinput(t)
end

function love.keypressed(key)
	-- forward keypresses to SUIT
	suit.keypressed(key)
end

function love.keyreleased(key)
	-- forward keypresses to SUIT
	suit.keyreleased(key)
end
