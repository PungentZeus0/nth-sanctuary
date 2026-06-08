---@class AK3D.Stage3D: Object
---@overload fun(): AK3D.Stage3D
local Stage3D, super = Class(Object, "Stage3D")

function Stage3D:init()
    super.init(self)
    ---@type AK3D.Model[]
    self.objects = {}
end

function Stage3D:add(object)
    table.insert(self.objects, object)
end

function Stage3D:updateChildren()
    super.updateChildren(self)
    for i,v in ipairs(self.objects) do
        v:update()
    end
end

function Stage3D:drawChildren()
    super.drawChildren(self)
    for i,v in ipairs(self.objects) do
        -- love.graphics.setDepthMode("lequal", true)
        love.graphics.setWireframe(DEBUG_RENDER)
        v:draw()
        love.graphics.setWireframe(false)
        -- love.graphics.setDepthMode("always", true)
    end
end

return Stage3D
