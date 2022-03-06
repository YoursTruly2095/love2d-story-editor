
require("viewer")

function love.load(arg)
  viewer:load()
end

function love.update(dt)
  viewer:update(dt)
end

function love.draw()
  viewer:draw()
end 
