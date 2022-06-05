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

local story_node = 1
local story_alt = 1
local id_register = 101

local mode = 'normal'
local normal_mode = 'edit'
local player_status = { text={""} }

local button_locations = {}
local map_button_height = 40

-- for the options / option delete screen
local scroll_offset = 0
local option_to_delete
local options_to_display=4

function editor:load()
    -- make love use font which support CJK text
    local font = love.graphics.newFont("Courier Prime.ttf", 16)
    love.graphics.setFont(font)
    love.keyboard.setKeyRepeat(true)
end
    
function editor:update()
    -- all the UI is defined in love.update or functions that are called from it
    local story = data[story_node].story
    local options = data[story_node].options
	
    local function new_id()
        id_register = id_register + 1
        return id_register
    end

    local function load_file()
        if filename == '...none...' then return end
        local load_string
        local length
        load_string, length = love.filesystem.read(filename)
        if load_string and length > 0 then
            local load_data = smallfolk.loads(load_string, 1000000)
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
            
            -- id duplicate check
            local used_ids = {}
            for s,story in pairs(node.story) do
                if used_ids[story.id] then
                    local id = new_id()
                    print("Story ID "..story.id.." is duplicated... changing to "..id)
                    story.id = id
                end
                used_ids[story.id] = true
            end
            
            for o,opt in pairs(node.options) do
                if used_ids[opt.id] then
                    local id = new_id()
                    print("Option ID "..opt.id.." is duplicated... changing to "..id)
                    opt.id = id
                end
                used_ids[opt.id] = true
            end

        end
    end
        
    local function save_file() 
        if filename == '...none...' then mode = 'saveas' return end
        local save_data = deep_copy(data)
        for n,node in ipairs(save_data) do
            for s,story_alt in ipairs(node.story) do
                dewrap(story_alt.text)
            end
        end
        save_data = deep_copy_with_ignore(save_data, {'line_wrap','cursor','cursorline','select','text_draw_offset'})
        local save_string = smallfolk.dumps(save_data)
        local new_save_data = smallfolk.loads(save_string, 1000000)
        
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
        suit.Input(editable_filename, {id="f"}, suit.layout:col(600,40))
        
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
        suit.Input(editable_filename, {id="f"}, suit.layout:col(600,40))
        
        
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
        
    local function delete_story_screen()
        
        local function actual_delete()
            if #story == 1 then
                -- there is only 1 alt, we are deleting the entire node, 
                -- but don't let the last node be deleted
                if #data > 1 then
                    table.remove(data, story_node)
                    
                    -- all the nodes above this one have just been renumbered
                    -- we need to fix all the links to those nodes
                    -- and remove links to the removed node
                    for n,node in pairs(data) do
                        for o,opt in pairs(node.options) do
                            local dest = check_status(opt.results.text[1], "node")
                            if dest and type(dest)=='number' then
                                if dest >= story_node then
                                    local req = opt.results.text[1]
                                    local s,e = req:find("node=%d+;") 
                                    if dest == story_node then
                                        -- we just deleted the destination of this option
                                        req = req:sub(1,s-1).."node=?;"..req:sub(e+1) 
                                    else
                                        -- we just moved the destination of this option up by 1
                                        local n = req:sub(s+5,e-1)
                                        n = tonumber(n) - 1
                                        req = req:sub(1,s-1).."node="..n..";"..req:sub(e+1) 
                                    end
                                    opt.results.text[1] = req
                                end
                            end
                        end
                    end
                    if story_node > #data then story_node = #data end
                end
            else
                table.remove(story, story_alt)
                if story_alt > #story then story_alt = #story end
            end
            mode='normal'
        end
    
        suit.layout:reset(25,25,25)
        if #story == 1 then
            suit.Label("Are you sure you want to delete this node?",suit.layout:col(900,40))
            suit.Label("All text and options will be irretrievably lost.",suit.layout:row(900,40))
        else
            suit.Label("Are you sure you want to delete this story alternative?",suit.layout:col(900,40))
            suit.Label("This text will be irretrievably lost.",suit.layout:row(900,40))
        end
        
        -- delete and cancel buttons
        suit.layout:reset(25,870,25)
        if suit.Button("Delete", suit.layout:row(150,70)).hit then actual_delete() end
        if suit.Button("Cancel", suit.layout:row(150,70)).hit then mode = 'normal' end
    end
    
    local function delete_option_screen()
        
        local function actual_delete(which)
            table.remove(options, which)
            
            -- fix scroll offset
            if scroll_offset > #options-options_to_display then scroll_offset = #options-options_to_display end
            if scroll_offset < 0 then scroll_offset = 0 end
            
            mode='normal'
        end
    
        suit.layout:reset(25,25,25)
        if #options > 1 then
            suit.Label("Are you sure you want to delete this option?",suit.layout:col(900,40))
            suit.Label("Option text, reqs and results will be irretrievably lost.",suit.layout:row(900,40))
        else
            suit.Label("You cannot delete the last option.",suit.layout:col(900,40))
        end
        
        -- delete and cancel buttons
        suit.layout:reset(25,870,25)
        if #options > 1 and option_to_delete then
            if suit.Button("Delete", suit.layout:row(150,70)).hit then actual_delete(option_to_delete) end
        end
        if suit.Button("Cancel", suit.layout:row(150,70)).hit then mode = 'normal' end
    end
    
    if mode == 'load' then load_screen() return end
    if mode == 'saveas' then save_screen() return end
    if mode == 'quit' then quit_screen() return end
    if mode == 'delete_story' then delete_story_screen() return end
    if mode == 'delete_option' then delete_option_screen() return end
    
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
        
    local lw = 80                   -- label width
    
    if normal_mode == 'play' then
        
        local function make_player_status_string(text_control)
            local status_string = ""
            for key,string in pairs(text_control.text) do
                status_string=status_string..string
                if status_string:sub(-1) ~= ';' then
                    status_string=status_string..';'
                end
            end
            return status_string
        end
        
        local function pick_alt()
            story_alt = 1           -- default
            
            -- the last alternative that satisfies requirements is picked
            if #story > 1 then
                for n=2,#story do
                    local reqs = convert_op_string(story[n].reqs.text[1], decode_req)
                    local lps = make_player_status_string(player_status)
                    local status = convert_op_string(lps, decode_status)
                    
                    if check_reqs(reqs,status)  then
                        story_alt = n
                    end
                end
            end
        end
        
        local function check_option(opt)
            local reqs = convert_op_string(opt.reqs.text[1], decode_req)
            local lps = make_player_status_string(player_status)
            local status = convert_op_string(lps, decode_status)
            return check_reqs(reqs,status) 
        end
        
        local function do_option(opt) 
            
            -- apply results
            local results = convert_op_string(opt.results.text[1], decode_results)
            local lps = make_player_status_string(player_status)
            local status = convert_op_string(lps, decode_status)
            
            -- switch to a new node if the option result specifies 
            -- one, and that node actually exists
            if results.node then
                if data[results.node.val] then 
                    story_node = results.node.val 
                else
                    local node = results.node.val or '?'
                    print("Tried to go to non-existent node "..node)
                end
                results.node = nil
            end
            
            status = apply_results(status, results)
            
            local status_string = ""
            for k,v in pairs(status) do
                status_string = status_string..k..v.op..v.val..";"
            end
            player_status.text[1] = status_string
        
        end
        
        -- play instead of editing
        -- edit mode button
        suit.layout:reset(640,1000,15)
        if suit.Button("Edit", suit.layout:row(150,60)).hit then normal_mode = 'edit' end
        suit.layout:reset(480,1000,15)
        if suit.Button("Reset", suit.layout:row(150,60)).hit then story_node = 1 end
        suit.layout:reset(320,1000,15)
        if suit.Button("Reset Player Status", suit.layout:row(150,60)).hit then player_status.text = {""} end
        
        -- the layout will grow down and to the right from this point
        suit.layout:reset(25,25,25)
        suit.Label("Player", suit.layout:row(150, 25))
        suit.layout:padding(0)
        suit.Label("Status", suit.layout:row(150, 25))
        suit.layout:up(0,25)
        suit.layout:right(175,0)    
        suit.Input(player_status, {id='ps', wrap=true, split_char=';'}, suit.layout:col(700,265))
        
        suit.layout:reset(25,320,25)
        suit.Label("Story", suit.layout:row(150, 25))
        suit.layout:padding(0)
        suit.Label("(node"..story_node..")(alt"..story_alt..")", suit.layout:row(150, 25))
        suit.layout:up(0,25)
        suit.layout:right(175,0)    
        -- pick the story alt depending on the player status
        pick_alt()
        suit.Input(story[story_alt].text, {id=story[story_alt].id, wrap=true}, suit.layout:col(700,265))

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
        
        -- the layout will grow down and to the right from this point
        suit.layout:reset(25,25,25)
        
        -- put an input widget at the layout origin, with a cell size of 200 by 30 pixels
        suit.Label("Story", suit.layout:row(150, 25))
        suit.layout:padding(0)
        suit.Label("(node"..story_node..")(alt"..story_alt..")", suit.layout:row(150, 25))
        suit.layout:padding(15)

        if suit.Button("New Alt", suit.layout:row(150,40)).hit then new_alt_story() end
        local button_text = "Delete Alt"
        if #story == 1 then button_text = "Delete Node" end
        if suit.Button(button_text, suit.layout:row(150,40)).hit then mode = 'delete_story' end
        
        if suit.Button("L", suit.layout:row(50,50)).hit then story_left() end
        suit.layout:padding(50)
        if suit.Button("R", suit.layout:col(50,50)).hit then story_right() end
        suit.layout:padding(15)
        
        suit.layout:left(100, 50)        -- I don't understand why these values work but whatever
        suit.Label("lvl",suit.layout:row(35,35))
        suit.layout:padding(0)
        suit.Input(data[story_node].display_level, {id=story[story_alt].id.."dl"}, suit.layout:col(35,35))
        suit.layout:padding(10)
        suit.Label("off",suit.layout:col(35,35))
        suit.layout:padding(0)
        suit.Input(data[story_node].display_offset, {id=story[story_alt].id.."do"}, suit.layout:col(50,35))
        
        suit.layout:up(0, 245)
        suit.layout:right(75, 0)        -- I don't understand why these values work but whatever
        
        suit.Input(story[story_alt].text, {id=story[story_alt].id, wrap=true, undo=true}, suit.layout:col(700,265))
        suit.Label("reqs",suit.layout:row(lw,35))
        suit.Input(story[story_alt].reqs, {id=story[story_alt].id.."reqs", undo=true}, suit.layout:col(700-lw,35))
        
        
        -- OPTIONS
        local function new_node(k)
            table.insert(data,
                {
                    display_level = {},
                    display_offset = {},
        
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
            if node == '?' then
                -- node we pointed to has been previously deleted or otherwise rendered '?'
                local s,e = results:find("node=%?;") 
                options[k].results.text[1] = results:sub(1,s-1)..results:sub(e+1)                 
                node = nil
            end
            if node == nil then
                new_node(k)
            else
                story_node = node
            end
            scroll_offset = 0
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
        
        local function delete_option(which)
            option_to_delete = which 
            mode = 'delete_option' 
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
            suit.Input(options[k].text, {id=options[k].id, undo=true}, suit.layout:col(tw,35))
            suit.layout:left(lw)
            suit.Label("reqs",suit.layout:row(lw,35))
            suit.Input(options[k].reqs, {id=options[k].id.."reqs", undo=true}, suit.layout:col(tw,35))
            suit.layout:left(lw)
            suit.Label("result",suit.layout:row(lw,35))
            suit.Input(options[k].results, {id=options[k].id.."results", undo=true}, suit.layout:col(tw,35))
            suit.layout:up(tw,70)
            suit.layout:padding(25)
            
            -- check out the horrible construct below
            -- we're using 'else' to make sure we don;t process the other buttons if one actually gets hit
            if suit.Button("Del", {id="B"..options[k].id}, suit.layout:col(50,52)).hit then delete_option(k) else
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
        scroll_offset = 0        
    end
        
        
    -- try looking at levels
    -- all nodes that are only sourced from level 1 are at level 2
    -- if there are no such nodes, but there are still unassigned nodes... oops!
    --   in this case, pick a node that is accessed from level 1 and call it level 2
    
    local node_levels = {}

    if #data > 1 then
        
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
    button_locations = {}
    map_button_height = 40
    
    local level_height = 100
    
    local deepest_level = 0
    for _,v in ipairs(node_levels) do
        if v>deepest_level then deepest_level = v end
    end

    if deepest_level > 10 then
        level_height = 1000 / deepest_level
    end

    if map_button_height > (level_height/2) then
        map_button_height = level_height/2
    end

    for level = 1, deepest_level do
    
        local buttons = {}
        
        for k,v in ipairs(node_levels) do
            if v == level then
                table.insert(buttons, k)
            end
        end
            
        local gap_width = (map_width - (button_width*#buttons)) / ((#buttons)+1)
        
        for k,v in ipairs(buttons) do
            
            local offset = map_offset + (gap_width*k) + (button_width*(k-1))
            
            local display_offset = 0
            
            if data[v].display_offset and data[v].display_offset.text then 
                display_offset = (tonumber(data[v].display_offset.text[1]) or 0) * 10 
            end
            
            -- reset to where we want to draw the button
            suit.layout:reset(offset+display_offset, 25 + (level-1)*level_height)
            
            -- record button location for the line drawing
            button_locations[v]={offset+(button_width/2)+display_offset, 25+(map_button_height/2)+((level-1)*level_height)}
            
            if suit.Button(v.." (1-"..#data[v].story..")", suit.layout:col(button_width,map_button_height)).hit then navigate(v) end
        end    
    end
    

end

function editor:draw()

    -- draw lines between buttons to be options
    if mode == 'normal' then
        for n, node in ipairs(data) do
            for o, option in ipairs(node.options) do
                local destination_node = check_status(option.results.text[1], 'node')
                if destination_node ~= nil and button_locations[n] and button_locations[destination_node] then
                    -- draw an arrow for node to destination_node
                    love.graphics.line(button_locations[n][1],button_locations[n][2]+(map_button_height/2),
                        button_locations[destination_node][1], button_locations[destination_node][2])
                end
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
