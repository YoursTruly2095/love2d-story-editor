-- suit up

local suit = require("suit")


editor = {}
-- storage for text input
local story = {text = {""}}
local options = { {text={""}} }
local reqs = { {text={""}} }

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
    
    local function up(k)
        if k > 1  and #options > 1 then
            table.insert(options,k-1,options[k])
            table.remove(options, k+1)
            table.insert(reqs,k-1,reqs[k])
            table.remove(reqs, k+1)
        end
    end
    
    local function down(k)
        if k < #options and #options > 1 then
            table.insert(options,k+2,options[k])
            table.remove(options, k)
            table.insert(reqs,k+2,reqs[k])
            table.remove(reqs, k)
        end
    end
    
    local function bin(k)
        if #options > 1 then
            table.remove(options, k)
            table.remove(reqs, k)
        end
    end
    
    local function entry(k)
        suit.Label("text",suit.layout:col(60,35))
        suit.layout:padding(0)
        suit.Input(options[k], suit.layout:col(500,35))
        suit.layout:left(60)
        suit.Label("reqs",suit.layout:row(60,35))
        suit.Input(reqs[k], suit.layout:col(500,35))
        suit.layout:up(500,35)
        suit.layout:padding(25)
        if suit.Button("B"..k, suit.layout:col(50,70)).hit then bin(k) end
        if suit.Button("U"..k, suit.layout:col(50,35)).hit then up(k) end
        suit.layout:padding(0)
        if suit.Button("D"..k, suit.layout:row(50,35)).hit then down(k) end
    end

    -- this must be a while loop not a for loop, because the BIN button 
    -- can change the length of value of #options
    local k=1
    while k <= #options do
        suit.layout:reset(25,350+(95*(k-1)),25)
        if k == 1 then
            if suit.Button("New Option", suit.layout:row(150, 70)).hit then
                if #options < 7 then
                    table.insert(options, {text={""}})
                    table.insert(reqs, {text={""}})
                end
            end
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
