-- suit up

local suit = require("suit")


editor = {}
-- storage for text input
local story = {text = {""}}

local options = { {text={""}} }
local reqs =    { {text={""}} }
local results = { {text={""}} }


function editor:load()
    -- make love use font which support CJK text
    local font = love.graphics.newFont("Courier Prime.ttf", 20)
    love.graphics.setFont(font)
end

function editor:update()
    -- all the UI is defined in love.update or functions that are called from it
	
    -- put the layout origin at position (100,100)
	-- the layout will grow down and to the right from this point
	suit.layout:reset(25,25,25)

	-- put an input widget at the layout origin, with a cell size of 200 by 30 pixels
	suit.Label("Story", suit.layout:row(150, 50))
    --suit.layout:col(25,300)
    suit.Input(story, suit.layout:col(700,300))

	-- put a label that displays the text below the first cell
	-- the cell size is the same as the last one (200x30 px)
	-- the label text will be aligned to the left
	--suit.Label("Hello, "..input.text, {align = "left"}, suit.layout:row())

	-- put an empty cell that has the same size as the last cell (200x30 px)
	suit.layout:reset(25,350,25)

	-- put a button of size 200x30 px in the cell below
	-- if the button is pressed, quit the game
    
    --suit.layout:push(suit.layout:nextCol())
    local function delete(which)
        if #options > 1 then
            table.remove(options, which)
            table.remove(reqs, which)
            table.remove(results, which)
        end
    end
    
    local function insert(where,which)
        table.insert(options,where,options[which])
        table.insert(reqs,where,reqs[which])
        table.insert(results,where,results[which])
    end
    
    local function new()
        if #options < 5 then
            table.insert(options, {text={""}})
            table.insert(reqs, {text={""}})
            table.insert(results, {text={""}})
        end
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
    
    local lw = 80                   -- label width
    local tw = 700-50-50-25-25-80   -- text width
    
    local function entry(k)
        suit.Label("text",suit.layout:col(lw,35))
        suit.layout:padding(0)
        suit.Input(options[k], suit.layout:col(tw,35))
        suit.layout:left(lw)
        suit.Label("reqs",suit.layout:row(lw,35))
        suit.Input(reqs[k], suit.layout:col(tw,35))
        suit.layout:left(lw)
        suit.Label("result",suit.layout:row(lw,35))
        suit.Input(results[k], suit.layout:col(tw,35))
        suit.layout:up(tw,70)
        suit.layout:padding(25)
        if suit.Button("B"..k, suit.layout:col(50,105)).hit then delete(k) end
        if suit.Button("U"..k, suit.layout:col(50,52)).hit then up(k) end
        suit.layout:padding(0)
        if suit.Button("D"..k, suit.layout:row(50,53)).hit then down(k) end
    end

    -- this must be a while loop not a for loop, because the BIN button 
    -- can change the length of value of #options
    local k=1
    while k <= #options do
        suit.layout:reset(25,350+(130*(k-1)),25)
        if k == 1 then
            if suit.Button("New Option", suit.layout:row(150,70)).hit then new() end
        elseif k == 2 then
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
        entry(k)
        k = k + 1
    end
--[[        
    for k=2, #options do
        suit.layout:reset(25,350+(95*(k-1)),25)
        suit.layout:col(150,50)
        entry(k)
    end
--]]        
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
