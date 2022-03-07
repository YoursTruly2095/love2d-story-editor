viewer = {mode = "system"}

function viewer:load()
    viewer.graphic = love.graphics.newImage("main-view.png")
end

function viewer:update(dt)
  
end

function viewer:draw()
   love.graphics.draw(viewer.graphic, 0, 0, 0, 2, 2)
   love.graphics.print(viewer.mode, 100, 100)
end

function viewer:setMode(mode)
  viewer.mode = mode
end