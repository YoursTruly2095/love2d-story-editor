
-- allow access to third party code
--package.path = package.path .. ";../third-party/?/?.lua"


require("editor")

function love.load(arg)
    -- stuff for debugging in zerobrane
  
    local hasdebug,debug = pcall(require,"mobdebug")
    if hasdebug then
        debug.start()
    end
  
    io.stdout:setvbuf("no")
  
    love.window.setFullscreen(true)
    editor:load()
end

function love.update(dt)
    editor:update(dt)
end

function love.draw()
    editor:draw()
end 
