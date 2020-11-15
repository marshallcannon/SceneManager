-- Input defined further down file
local Input = {}

local SceneManager = {
  -- All scenes in draw order
  sceneObjects = {},
  -- The current transition
  transition = nil,
  -- Scenes to remove at the end of the update loop
  removalQueue = {},
  -- Container for all input related functions
  input = Input
}

function SceneManager:add(newScene, index)

  local sceneObject = {
    scene = newScene,
    status = 'active'
  }
  index = index or #self.sceneObjects + 1
  table.insert(self.sceneObjects, index, sceneObject)

  return sceneObject, index

end

function SceneManager:remove(scene)

  local sceneObject = self:getSceneObject(scene)
  table.insert(self.removalQueue, sceneObject)

end

function SceneManager:realRemove(sceneObject)

  for i = 1, #self.sceneObjects do
    if self.sceneObjects[i] == sceneObject then
      table.remove(self.sceneObjects, i)
      return sceneObject
    end
  end

  error('Could not find provided scene to remove')

end

function SceneManager:clear()

  for i = 1, #self.sceneObjects do
    table.insert(self.removalQueue, self.sceneObjects[i])
  end

end

-- Resumes updating, input, and rendering
function SceneManager:play(scene)

  local sceneObject = self:getSceneObject(scene)
  assert(sceneObject, 'Could not find scene to play')

  sceneObject.status = 'active'
  if sceneObject.scene.resume then
    sceneObject.scene:resume()
  end

end

-- Stops updating and input, but keeps rendering
function SceneManager:pause(scene)

  local sceneObject = self:getSceneObject(scene)
  assert(sceneObject, 'Could not find scene to pause')

  sceneObject.status = 'paused'
  if sceneObject.scene.pause then
    sceneObject.scene:pause()
  end

end

-- Stops updating, input, and rendering
function SceneManager:stop(scene)

  local sceneObject = self:getSceneObject(scene)
  assert(sceneObject, 'Could not find scene to stop')

  sceneObject.status = 'stopped'
  if sceneObject.scene.stop then
    sceneObject.scene:stop()
  end

end

function SceneManager:sendToBack(key)

end

function SceneManager:bringToFront(key)

end

function SceneManager:getSceneObject(scene)

  for i = 1, #self.sceneObjects do
    if self.sceneObjects[i].scene == scene then
      return self.sceneObjects[i], i
    end
  end

end

function SceneManager:getSceneIndex(scene)

  local _, index = self:getSceneObject(scene)
  return index

end

-- Replaces scene1 with scene2 in the scene order
function SceneManager:replaceScene(scene1, scene2)

  -- Get scene index
  local index = self:getSceneIndex(scene1)
  self:remove(scene1)
  self:add(scene2, index)

end

function SceneManager:transitionReplace(scene1, scene2, transition)

  self.transition = transition
  self.transition:start(function ()
    self:replaceScene(scene1, scene2)
  end, function ()
    self.transition = nil
  end)

end

function SceneManager:getSceneObjects()

  return self.sceneObjects

end

function SceneManager:printScenes()

  print('Scene order:')
  for i = 1, #self.sceneObjects do
    local name = self.sceneObjects[i].scene.sceneName or 'No Name'
    local status = self.sceneObjects[i].status
    print(string.format('  %s - %s', name, status))
  end

end

--[[-----------------
Love callback hookups
--]]-----------------
function SceneManager:update(dt)

  self.input:update(dt)

  for i = 1, #self.sceneObjects do

    if self.sceneObjects[i].status == 'active' then
      self.sceneObjects[i].scene:update(dt)
    end

  end

  -- Remove scenes
  if #self.removalQueue > 0 then
    for i = 1, #self.removalQueue do
      self:realRemove(self.removalQueue[i])
    end
    self.removalQueue = {}
  end

end

function SceneManager:draw()

  for i = 1, #self.sceneObjects do

    if self.sceneObjects[i].status ~= 'stopped' then
      self.sceneObjects[i].scene:draw()
    end

  end

  -- Dragged object
  if self.input.draggedObject then
    self.input.draggedObject:draw()
  end

  -- Transition
  if self.transition then
    self.transition:draw()
  end

end

function SceneManager:keypressed(key)

  for i = #self.sceneObjects, 1, -1 do

    if (self.sceneObjects[i].status == 'active' and self.sceneObjects[i].scene.keypressed) then
      self.sceneObjects[i].scene:keypressed(key)
      return
    end

  end

end

function SceneManager:keyreleased(key)

  for i = #self.sceneObjects, 1, -1 do

    if (self.sceneObjects[i].status == 'active' and self.sceneObjects[i].scene.keyreleased) then
      self.sceneObjects[i].scene:keyreleased(key)
      return
    end

  end

end

function SceneManager:mousepressed(x, y, button)

  for i = #self.sceneObjects, 1, -1 do

    if (self.sceneObjects[i].status == 'active' and self.sceneObjects[i].scene.mousepressed) then
      local clickedObject = self.sceneObjects[i].scene:mousepressed(x, y, button)
      if clickedObject then
        return
      end
    end

  end

end

function SceneManager:mousereleased(x, y, button)

  -- Drop dragged object
  if self.input.draggedObject then
    self.input:dropDraggedObject()
  end

  for i = #self.sceneObjects, 1, -1 do

    if (self.sceneObjects[i].status == 'active' and self.sceneObjects[i].scene.mousereleased) then
      self.sceneObjects[i].scene:mousereleased(x, y, button)
      return
    end

  end

end

function SceneManager:mousemoved(x, y, dx, dy)

  for i = #self.sceneObjects, 1, -1 do

    if (self.sceneObjects[i].status == 'active' and self.sceneObjects[i].scene.mousemoved) then
      self.sceneObjects[i].scene:mousemoved(x, y, dx, dy)
      return
    end

  end

end

function SceneManager:wheelmoved(x, y)

  for i = #self.sceneObjects, 1, -1 do

    if (self.sceneObjects[i].status == 'active' and self.sceneObjects[i].scene.wheelmoved) then
      self.sceneObjects[i].scene:wheelmoved(x, y)
      return
    end

  end

end

-- Scene Manager Input
function Input:update(dt)

  if self.draggedObject then
    if self.draggedObject.update then
      self.draggedObject:update(dt)
    end
    local dragX, dragY = love.mouse.getX(), love.mouse.getY()
    if self.draggedObject.drag then
      self.draggedObject:drag(dragX, dragY)
    else
      self.draggedObject:setPosition(dragX, dragY)
    end
  end

end

function Input:setDraggedObject(object)

  self.draggedObject = object

end

function Input:dropDraggedObject()

  local sceneObjects = SceneManager:getSceneObjects()
  for i = #sceneObjects, 1, -1 do
    local scene = sceneObjects[i].scene
    if scene.grabObject and scene:grabObject(self.draggedObject) then
      if self.draggedObject.drop then
        self.draggedObject:drop()
      end
      self.draggedObject = nil
      return scene
    end
  end

  self.draggedObject = nil

end

return SceneManager