-- suit up

local suit = require("suit")
require("utils")


editor = {}

local data =
{
    -- story nodes
    {
        story =     
        {
            -- alternate story text at each node
            {
                id = 100,
                text =      { {text={""}} }, 
                reqs =      { {text={""}} } 
            }
        },
        
        options = 
        {
            -- multiple options at each node
            {
                id = 101,
                text =      { {text={""}} },
                reqs =      { {text={""}} },
                results =   { {text={""}} }
            }
        }
    }
}



local scroll_offset = 0
local story_node = 1
local story_alt = 1
local id_register = 101


function editor:load()
    -- make love use font which support CJK text
    local font = love.graphics.newFont("Courier Prime.ttf", 16)
    love.graphics.setFont(font)
end

function editor:update()
    -- all the UI is defined in love.update or functions that are called from it
	
    local function new_id()
        id_register = id_register + 1
        return id_register
    end
    
    local story = data[story_node].story
    local options = data[story_node].options
    local lw = 80                   -- label width
    
    -- STORY
	-- the layout will grow down and to the right from this point
	suit.layout:reset(25,25,25)

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
                if tonumber(node)==story_node then 
                    story_node=k 
                    return 
                end
            end
        end
        
    end
    

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
    suit.layout:padding(25)
    
    suit.layout:up(0, 145)
    suit.layout:right(25, 0)        -- I don't understand why these values work but whatever
    
    suit.Input(story[story_alt].text, suit.layout:col(700,265))
    suit.layout:padding(0)
    suit.Label("reqs",suit.layout:row(lw,35))
    suit.Input(story[story_alt].reqs, suit.layout:col(700-lw,35))
    
    
    -- OPTIONS
	suit.layout:reset(25,350,25)
    
    local function new_node(k)
        table.insert(data,
            {
                story =     
                {
                    -- alternate story text at each node
                    {
                        id = new_id(),
                        text =      { {text={""}} }, 
                        reqs =      { {text={""}} } 
                    }
                },
                
                options = 
                {
                    -- multiple options at each node
                    {
                        id = new_id(),
                        text =      { {text={""}} },
                        reqs =      { {text={""}} },
                        results =   { {text={""}} }
                    }
                }
            })
        
        local results = options[k].results.text[1]
        options[k].results.text[1] = "node="..#data..";"..results
        story_node = #data
    end
    
    local function node(k)
        local results = options[k].results.text[1]
        local node = check_status(results, "node")
        if node == nil then
            new_node(k)
        else
            story_node = tonumber(node)
        end
    end
        
    local function delete(which)
        if #options > 1 then
            table.remove(options, which)
            
            -- fix scroll offset
            if scroll_offset > #options-5 then scroll_offset = #options-5 end
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
        scroll_offset = #options-5
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
            if scroll_offset < #options-5 then
                scroll_offset = scroll_offset + 1
            end
        end
    end
    
            
            
    
    local tw = 700-50-50-25-25-80   -- text width
    
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
        if suit.Button("Del", {id="B"..options[k].id}, suit.layout:col(50,52)).hit then delete(k) end
        suit.layout:padding(0)
        if suit.Button("Node", {id="N"..options[k].id}, suit.layout:row(50,53)).hit then node(k) end
        suit.layout:up(50,52)
        suit.layout:padding(25)
        if suit.Button("U", {id="U"..options[k].id}, suit.layout:col(50,52)).hit then up(k) end
        suit.layout:padding(0)
        if suit.Button("D", {id="D"..options[k].id}, suit.layout:row(50,53)).hit then down(k) end
    end

    -- this must be a while loop not a for loop, because the BIN button 
    -- can change the length of value of #options
    local k=1
    while k <= math.min(#options, 5) do -- we cannot calculate this prior to the loop!!
        suit.layout:reset(25,350+(130*(k-1)),25)
        if k == 1 then
            if suit.Button("New Option", suit.layout:row(150,70)).hit then new_option() end
        elseif k == 2 and #options > 5 then
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

end

function editor:draw()
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
