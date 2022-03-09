viewer = {}

function viewer:load()
    viewer.graphic = love.graphics.newImage("graphics/main-view.png")
end

function viewer:update(dt)
  
end

function viewer:draw()
   love.graphics.draw(viewer.graphic, 0, 0, 0, 2, 2) 
end