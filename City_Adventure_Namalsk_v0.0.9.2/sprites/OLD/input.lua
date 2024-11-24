-- Input.lua
local Defs = require("definitions")

local Input = {}
Input.__index = Input

function Input:new(camera, grid, buildingSystem)
    local input = {
        camera = camera,
        grid = grid,
        buildingSystem = buildingSystem,
        mouseX = 0,
        mouseY = 0,
        lastGridX = 0,
        lastGridY = 0,
        isDragging = false,
        dragStartX = 0,
        dragStartY = 0,
        currentTool = nil,
        keyStates = {},
        terrainTool = {
            active = false,
            type = nil,
            brushSize = 1
        }
    }
    setmetatable(input, self)
    return input
end

function Input:update(dt)
    -- Actualizar posición del mouse
    self.mouseX, self.mouseY = love.mouse.getPosition()
    
    -- Convertir coordenadas de pantalla a coordenadas de grid
    local worldX, worldY = self:screenToWorld(self.mouseX, self.mouseY)
    local gridX, gridY = self:worldToGrid(worldX, worldY)
    
    -- Actualizar posición en el grid si es válida
    if self.grid:isValidPosition(gridX, gridY) then
        self.lastGridX = gridX
        self.lastGridY = gridY
        self.grid.hover = {x = gridX, y = gridY}
    else
        self.grid.hover = nil
    end
    
    -- Mover cámara con teclas
    self:updateCameraMovement(dt)
end

function Input:screenToWorld(screenX, screenY)
    return (screenX - self.camera.x) / self.camera.zoom,
           (screenY - self.camera.y) / self.camera.zoom
end

function Input:worldToGrid(worldX, worldY)
    -- Convertir coordenadas de mundo a coordenadas isométricas
    local isoX = (worldX / Defs.SYSTEM.GRID.ISO_SCALE_X + worldY / Defs.SYSTEM.GRID.ISO_SCALE_Y) / 2
    local isoY = (worldY / Defs.SYSTEM.GRID.ISO_SCALE_Y - worldX / Defs.SYSTEM.GRID.ISO_SCALE_X) / 2
    return math.floor(isoX + 0.5), math.floor(isoY + 0.5)
end

function Input:updateCameraMovement(dt)
    local moveSpeed = Defs.SYSTEM.CAMERA.MOVE_SPEED * dt
    
    -- Movimiento con WASD o flechas
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        self.camera:move(0, -moveSpeed)
    end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        self.camera:move(0, moveSpeed)
    end
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        self.camera:move(-moveSpeed, 0)
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        self.camera:move(moveSpeed, 0)
    end
end

function Input:handleMousePressed(x, y, button)
    if button == 1 then  -- Click izquierdo
        if self.terrainTool.active then
            self:applyTerrainTool()
            return true
        elseif self.buildingSystem.buildMode then
            self.buildingSystem:tryPlaceBuilding(self.lastGridX, self.lastGridY)
            return true
        end
    elseif button == 2 then  -- Click derecho
        self.isDragging = true
        self.dragStartX = x
        self.dragStartY = y
        self.camera:startDrag(x, y)
        return true
    end
    return false
end

function Input:handleMouseReleased(x, y, button)
    if button == 2 then
        self.isDragging = false
        self.camera:endDrag()
    end
end

function Input:handleMouseMoved(x, y, dx, dy)
    if self.isDragging then
        self.camera:updateDrag(x, y)
    end
end

function Input:handleMouseWheel(x, y)
    if love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl') then
        -- Zoom
        local zoom = self.camera.zoom + y * Defs.SYSTEM.CAMERA.ZOOM_SPEED
        self.camera:setZoom(zoom)
    else
        -- Ajustar tamaño de brocha si estamos en modo terreno
        if self.terrainTool.active then
            self.terrainTool.brushSize = math.max(1, 
                math.min(3, self.terrainTool.brushSize + (y > 0 and 1 or -1)))
        end
    end
end

function Input:handleKeyPressed(key)
    self.keyStates[key] = true
    
    if key == 'escape' then
        self:cancelCurrentTool()
    elseif key == 'b' then
        self:toggleBuildMode()
    elseif key == 'pageup' then
        self:setTerrainTool('raise')
    elseif key == 'pagedown' then
        self:setTerrainTool('lower')
    elseif key == 'l' then
        self:setTerrainTool('level')
    elseif key >= '1' and key <= '3' then
        if self.terrainTool.active then
            self.terrainTool.brushSize = tonumber(key)
        end
    end
end

function Input:handleKeyReleased(key)
    self.keyStates[key] = false
end

function Input:setTerrainTool(toolType)
    self:cancelCurrentTool()
    self.terrainTool.active = true
    self.terrainTool.type = toolType
    self.currentTool = 'terrain'
end

function Input:toggleBuildMode()
    if self.buildingSystem then
        self.buildingSystem.buildMode = not self.buildingSystem.buildMode
        if self.buildingSystem.buildMode then
            self:cancelCurrentTool()
        end
    end
end

function Input:cancelCurrentTool()
    self.currentTool = nil
    self.terrainTool.active = false
    if self.buildingSystem then
        self.buildingSystem.buildMode = false
    end
end

function Input:applyTerrainTool()
    if not self.terrainTool.active or not self.grid.hover then return end
    
    local x, y = self.grid.hover.x, self.grid.hover.y
    
    -- Aplicar modificación según el tipo de herramienta
    for offsetY = -self.terrainTool.brushSize + 1, self.terrainTool.brushSize - 1 do
        for offsetX = -self.terrainTool.brushSize + 1, self.terrainTool.brushSize - 1 do
            local targetX = x + offsetX
            local targetY = y + offsetY
            
            if self.grid:isValidPosition(targetX, targetY) then
                if self.terrainTool.type == 'raise' then
                    self.grid:modifyHeight(targetX, targetY, 'topLeft', 1)
                    self.grid:modifyHeight(targetX, targetY, 'topRight', 1)
                    self.grid:modifyHeight(targetX, targetY, 'bottomLeft', 1)
                    self.grid:modifyHeight(targetX, targetY, 'bottomRight', 1)
                elseif self.terrainTool.type == 'lower' then
                    self.grid:modifyHeight(targetX, targetY, 'topLeft', -1)
                    self.grid:modifyHeight(targetX, targetY, 'topRight', -1)
                    self.grid:modifyHeight(targetX, targetY, 'bottomLeft', -1)
                    self.grid:modifyHeight(targetX, targetY, 'bottomRight', -1)
                elseif self.terrainTool.type == 'level' then
                    local baseHeight = self.grid:getCell(x, y).heights.topLeft
                    self.grid:levelTile(targetX, targetY, baseHeight)
                end
            end
        end
    end
end

return Input