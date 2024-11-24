-- Camera.lua
local Defs = require("definitions")  -- Añadido require al inicio

local Camera = {}
Camera.__index = Camera

function Camera:new()
    local camera = {
        x = 0,
        y = 0,
        targetX = 0,
        targetY = 0,
        zoom = Defs.SYSTEM.CAMERA.DEFAULT_ZOOM,
        targetZoom = Defs.SYSTEM.CAMERA.DEFAULT_ZOOM,
        isDragging = false,
        dragStartX = 0,
        dragStartY = 0,
        lastX = 0,
        lastY = 0,
        velocity = {x = 0, y = 0},
        bounds = {
            minX = -1000,
            maxX = 1000,
            minY = -1000,
            maxY = 1000
        }
    }
    setmetatable(camera, self)
    return camera
end

function Camera:update(dt)
    -- Suavizado de movimiento
    local smoothness = 0.15
    self.x = self.x + (self.targetX - self.x) * smoothness
    self.y = self.y + (self.targetY - self.y) * smoothness
    self.zoom = self.zoom + (self.targetZoom - self.zoom) * smoothness
    
    -- Aplicar inercia al movimiento
    if not self.isDragging then
        self.velocity.x = self.velocity.x * 0.95
        self.velocity.y = self.velocity.y * 0.95
        self:move(self.velocity.x * dt, self.velocity.y * dt)
    end
    
    -- Mantener la cámara dentro de los límites
    self:clampToBounds()
end

function Camera:move(dx, dy)
    self.targetX = self.targetX + dx * Defs.SYSTEM.CAMERA.MOVE_SPEED
    self.targetY = self.targetY + dy * Defs.SYSTEM.CAMERA.MOVE_SPEED
end

function Camera:setZoom(zoom)
    self.targetZoom = math.max(Defs.SYSTEM.CAMERA.MIN_ZOOM,
                     math.min(Defs.SYSTEM.CAMERA.MAX_ZOOM, zoom))
end

function Camera:startDrag(x, y)
    self.isDragging = true
    self.dragStartX = x
    self.dragStartY = y
    self.lastX = x
    self.lastY = y
    self.velocity = {x = 0, y = 0}
end

function Camera:updateDrag(x, y)
    if self.isDragging then
        local dx = x - self.lastX
        local dy = y - self.lastY
        
        self.velocity.x = dx / self.zoom
        self.velocity.y = dy / self.zoom
        
        self:move(dx / self.zoom, dy / self.zoom)
        
        self.lastX = x
        self.lastY = y
    end
end

function Camera:endDrag()
    self.isDragging = false
end

function Camera:screenToWorld(screenX, screenY)
    local worldX = (screenX - self.x) / self.zoom
    local worldY = (screenY - self.y) / self.zoom
    return worldX, worldY
end

function Camera:worldToScreen(worldX, worldY)
    local screenX = worldX * self.zoom + self.x
    local screenY = worldY * self.zoom + self.y
    return screenX, screenY
end

function Camera:clampToBounds()
    self.targetX = math.max(self.bounds.minX, math.min(self.bounds.maxX, self.targetX))
    self.targetY = math.max(self.bounds.minY, math.min(self.bounds.maxY, self.targetY))
end

function Camera:setBounds(minX, maxX, minY, maxY)
    self.bounds = {
        minX = minX,
        maxX = maxX,
        minY = minY,
        maxY = maxY
    }
end

function Camera:getTransform()
    return love.math.newTransform()
        :translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
        :scale(self.zoom)
        :translate(-love.graphics.getWidth()/2, -love.graphics.getHeight()/2)
        :translate(self.x, self.y)
end

return Camera