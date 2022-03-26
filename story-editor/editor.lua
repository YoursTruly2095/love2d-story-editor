-- suit up

local suit = require("suit")


editor = {}

local data =
{
    -- story levels
    {
        story =     
        {
            -- alternate story text at each level
            {
                text =      { {text={""}} }, 
                reqs =      { {text={""}} } 
            }
        },
        
        options = 
        {
            -- multiple options at each level
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
local story_level = 1
local story_alt = 1
local id_register = 101


function editor:load()
    -- make love use font which support CJK text
    local font = love.graphics.newFont("Courier Prime.ttf", 20)
    love.graphics.setFont(font)
end

function editor:update()
    -- all the UI is defined in love.update or functions that are called from it
	
    local function new_id()
        id_register = id_register + 1
        return id_register
    end
    
    local story = data[story_level].story[story_alt]
    local options = data[story_level].options
    local lw = 80                   -- label width
    
    -- STORY
	-- the layout will grow down and to the right from this point
	suit.layout:reset(25,25,25)

    local function new_alt_story() 
            -- much like new() below for the options?
    end

	-- put an input widget at the layout origin, with a cell size of 200 by 30 pixels
	suit.Label("Story", suit.layout:row(150, 50))
    if suit.Button("New Alt", suit.layout:row(150,50)).hit then new_alt_story() end
    suit.layout:up(150, 50)
    suit.Input(story.text, suit.layout:col(700,265))
    suit.layout:padding(0)
    suit.Label("reqs",suit.layout:row(lw,35))
    suit.Input(story.reqs, suit.layout:col(700-lw,35))
    
    -- need some 'side to side' scroll button for selection alt story versions

    
    -- OPTIONS
	suit.layout:reset(25,350,25)
    
    --suit.layout:push(suit.layout:nextCol())
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
    
    local function new()
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
        if suit.Button("B", {id="B"..options[k].id}, suit.layout:col(50,105)).hit then delete(k) end
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
            if suit.Button("New Option", suit.layout:row(150,70)).hit then new() end
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
