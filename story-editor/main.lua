
-- allow access to third party code
package.path = package.path .. ";../third-party/?/?.lua"


require("editor")

function love.load(arg)
  editor:load()
end

function love.update(dt)
  editor:update(dt)
end

function love.draw()
  editor:draw()
end 
