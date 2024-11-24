-- Grid.lua
local Defs = require("definitions")

local Grid = {}
Grid.__index = Grid

function Grid:new(width, height)
    local grid = {
        width = width or Defs.SYSTEM.GRID.SIZE,
        height = height or Defs.SYSTEM.GRID.SIZE,
        cells = {},
        hover = nil,
        selected = nil,
        lastModified = {}
    }
    setmetatable(grid, self)
    grid:initialize()
    return grid
end

function Grid:initialize()
    for y = 1, self.height do
        self.cells[y] = {}
        for x = 1, self.width do
            self.cells[y][x] = self:createCell(x, y)
        end
    end
end
-- Añadir estos métodos a la clase Grid

function Grid:drawDecoration(cell, isoPos)
    -- Si no hay decoración, no hacer nada
    if not cell.decoration then return end
    
    -- Calcular posición base considerando altura del terreno
    local avgHeight = (cell.heights.topLeft + cell.heights.topRight + 
                      cell.heights.bottomRight + cell.heights.bottomLeft) / 4
    
    local x = isoPos.x - Defs.SYSTEM.GRID.ISO_SCALE_X
    local y = isoPos.y - avgHeight * Defs.TERRAIN_SYSTEM.HEIGHT_STEP
    
    -- Dibujar sprite de decoración
    if sprites["bosque"] then  -- Por ahora solo usamos el sprite de bosque
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            sprites["bosque"],
            x,
            y - sprites["bosque"]:getHeight() + Defs.SYSTEM.GRID.TILE_HEIGHT
        )
    end
end

-- También deberíamos modificar el método drawCell para manejar casos donde no hay decoración
function Grid:drawCell(x, y)
    local cell = self:getCell(x, y)
    if not cell then return end
    
    local isoPos = self:gridToIso(x, y)
    
    -- Dibujar terreno base
    self:drawTerrain(cell, isoPos)
    
    -- Dibujar agua si existe
    if cell.waterLevel >= 0 then
        self:drawWater(cell, isoPos)
    end
    
    -- Dibujar decoraciones solo si existen
    if cell.decoration then
        self:drawDecoration(cell, isoPos)
    end
end

function Grid:addDecoration(x, y, decorationType)
    local cell = self:getCell(x, y)
    if not cell then return false end
    
    -- Solo permitir decoraciones en celdas vacías
    if cell.building or cell.road then return false end
    
    -- Por ahora solo manejamos árboles
    if decorationType == "tree" then
        cell.decoration = "tree"
        return true
    end
    
    return false
end

function Grid:removeDecoration(x, y)
    local cell = self:getCell(x, y)
    if not cell then return false end
    
    if cell.decoration then
        cell.decoration = nil
        return true
    end
    
    return false
end

function Grid:canAddDecoration(x, y)
    local cell = self:getCell(x, y)
    if not cell then return false end
    
    -- No permitir decoraciones en:
    -- - Celdas con edificios
    -- - Celdas con carreteras
    -- - Celdas con agua
    return not (cell.building or cell.road or cell.waterLevel >= 0)
end

function Grid:createCell(x, y)
    return {
        x = x,
        y = y,
        terrain = "grass",
        heights = {
            topLeft = 1,
            topRight = 1,
            bottomRight = 1,
            bottomLeft = 1
        },
        waterLevel = 0,
        building = nil,
        buildingRef = nil,  -- Para edificios multi-tile
        isSecondaryTile = false,
        road = nil,
        rotation = 0,
        decoration = nil,
        modified = false
    }
end

-- Conversiones de coordenadas
function Grid:gridToIso(x, y)
    return {
        x = (x - y) * Defs.SYSTEM.GRID.ISO_SCALE_X,
        y = (x + y) * Defs.SYSTEM.GRID.ISO_SCALE_Y
    }
end

function Grid:isoToGrid(isoX, isoY)
    local x = (isoX / Defs.SYSTEM.GRID.ISO_SCALE_X + isoY / Defs.SYSTEM.GRID.ISO_SCALE_Y) / 2
    local y = (isoY / Defs.SYSTEM.GRID.ISO_SCALE_Y - isoX / Defs.SYSTEM.GRID.ISO_SCALE_X) / 2
    return math.floor(x + 0.5), math.floor(y + 0.5)
end

function Grid:screenToGrid(screenX, screenY, camera)
    local worldX = (screenX - camera.x) / camera.zoom
    local worldY = (screenY - camera.y) / camera.zoom
    return self:isoToGrid(worldX, worldY)
end

-- Gestión de celdas
function Grid:getCell(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return nil
    end
    return self.cells[y][x]
end

function Grid:isValidPosition(x, y)
    return x >= 1 and x <= self.width and y >= 1 and y <= self.height
end

-- Sistema de terreno
function Grid:modifyHeight(x, y, corner, delta)
    local cell = self:getCell(x, y)
    if not cell or cell.building or cell.road then return false end
    
    -- Verificar límites de altura
    local newHeight = cell.heights[corner] + delta
    if newHeight < Defs.TERRAIN_SYSTEM.MIN_HEIGHT or 
       newHeight > Defs.TERRAIN_SYSTEM.MAX_HEIGHT then
        return false
    end
    
    cell.heights[corner] = newHeight
    cell.modified = true
    table.insert(self.lastModified, {x = x, y = y})
    
    -- Auto-nivelar terreno adyacente
    self:smoothTerrain(x, y)
    self:updateWaterLevel(x, y)
    
    return true
end

function Grid:smoothTerrain(x, y)
    local directions = {
        {x = -1, y = 0, corners = {"topRight", "bottomRight", "topLeft", "bottomLeft"}},
        {x = 1, y = 0, corners = {"topLeft", "bottomLeft", "topRight", "bottomRight"}},
        {x = 0, y = -1, corners = {"bottomLeft", "bottomRight", "topLeft", "topRight"}},
        {x = 0, y = 1, corners = {"topLeft", "topRight", "bottomLeft", "bottomRight"}}
    }
    
    for _, dir in ipairs(directions) do
        local adjX, adjY = x + dir.x, y + dir.y
        local adjCell = self:getCell(adjX, adjY)
        if adjCell and not (adjCell.building or adjCell.road) then
            for i = 1, 2 do
                local sourceCorner = dir.corners[i]
                local targetCorner = dir.corners[i + 2]
                local heightDiff = math.abs(self:getCell(x, y).heights[sourceCorner] - 
                                          adjCell.heights[targetCorner])
                
                if heightDiff > Defs.GAME_RULES.MAX_SLOPE then
                    local avgHeight = (self:getCell(x, y).heights[sourceCorner] + 
                                     adjCell.heights[targetCorner]) / 2
                    adjCell.heights[targetCorner] = avgHeight
                    adjCell.modified = true
                    table.insert(self.lastModified, {x = adjX, y = adjY})
                end
            end
        end
    end
end

function Grid:updateWaterLevel(x, y)
    local cell = self:getCell(x, y)
    if not cell then return end
    
    -- El agua se acumula en los puntos más bajos
    local minHeight = math.min(
        cell.heights.topLeft,
        cell.heights.topRight,
        cell.heights.bottomRight,
        cell.heights.bottomLeft
    )
    
    if minHeight <= Defs.TERRAIN_SYSTEM.MIN_HEIGHT then
        cell.waterLevel = Defs.TERRAIN_SYSTEM.MIN_HEIGHT
    else
        cell.waterLevel = -1
    end
end

-- Construcción
function Grid:canBuildAt(x, y, buildingType)
    local building = Defs.getBuildingById(buildingType)
    if not building then return false end
    
    -- Verificar área completa
    for offsetY = 0, building.size.height - 1 do
        for offsetX = 0, building.size.width - 1 do
            local cell = self:getCell(x + offsetX, y + offsetY)
            if not cell then return false end
            
            -- Verificar terreno nivelado
            if not self:isCellLevel(cell) then return false end
            
            -- Verificar agua y construcciones existentes
            if cell.waterLevel >= 0 or cell.building or cell.road then
                return false
            end
        end
    end
    
    return true
end

function Grid:isCellLevel(cell)
    local h = cell.heights.topLeft
    return h == cell.heights.topRight and
           h == cell.heights.bottomRight and
           h == cell.heights.bottomLeft
end

-- Renderizado
function Grid:draw(camera)
    love.graphics.push()
    self:drawTerrainLayer(camera)
    self:drawBuildingsLayer(camera)
    self:drawHover(camera)
    love.graphics.pop()
end

function Grid:drawTerrainLayer(camera)
    -- Dibujar de atrás hacia adelante para correcto orden de renderizado
    for sum = 2, self.width + self.height do
        for x = math.max(1, sum - self.height), math.min(sum - 1, self.width) do
            local y = sum - x
            if y >= 1 and y <= self.height then
                self:drawCell(x, y)
            end
        end
    end
end

function Grid:drawCell(x, y)
    local cell = self:getCell(x, y)
    if not cell then return end
    
    local isoPos = self:gridToIso(x, y)
    
    -- Dibujar terreno base
    self:drawTerrain(cell, isoPos)
    
    -- Dibujar agua si existe
    if cell.waterLevel >= 0 then
        self:drawWater(cell, isoPos)
    end
    
    -- Dibujar decoraciones
    if cell.decoration then
        self:drawDecoration(cell, isoPos)
    end
end

function Grid:drawTerrain(cell, isoPos)
    -- Calcular puntos considerando altura
    local points = self:calculateTerrainPoints(cell, isoPos)
    
    -- Color base del terreno
    local color = self:getTerrainColor(cell)
    love.graphics.setColor(color)
    love.graphics.polygon('fill', points)
    
    -- Borde del terreno
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.polygon('line', points)
end

function Grid:calculateTerrainPoints(cell, isoPos)
    return {
        -- Top left
        isoPos.x - Defs.SYSTEM.GRID.ISO_SCALE_X,
        isoPos.y - cell.heights.topLeft * Defs.TERRAIN_SYSTEM.HEIGHT_STEP,
        -- Top
        isoPos.x,
        isoPos.y - cell.heights.topRight * Defs.TERRAIN_SYSTEM.HEIGHT_STEP - 
                   Defs.SYSTEM.GRID.ISO_SCALE_Y,
        -- Top right
        isoPos.x + Defs.SYSTEM.GRID.ISO_SCALE_X,
        isoPos.y - cell.heights.bottomRight * Defs.TERRAIN_SYSTEM.HEIGHT_STEP,
        -- Bottom
        isoPos.x,
        isoPos.y - cell.heights.bottomLeft * Defs.TERRAIN_SYSTEM.HEIGHT_STEP + 
                   Defs.SYSTEM.GRID.ISO_SCALE_Y
    }
end

function Grid:getTerrainColor(cell)
    -- Color base según tipo de terreno
    local baseColor = Defs.TERRAIN_SYSTEM.COLORS[cell.terrain] or 
                     Defs.TERRAIN_SYSTEM.COLORS.grass
    
    -- Modificar color según pendiente
    if self:isCellLevel(cell) then
        return Defs.TERRAIN_SYSTEM.COLORS.slope.flat
    else
        -- Calcular inclinación predominante
        local avgLeft = (cell.heights.topLeft + cell.heights.bottomLeft) / 2
        local avgRight = (cell.heights.topRight + cell.heights.bottomRight) / 2
        if avgLeft > avgRight then
            return Defs.TERRAIN_SYSTEM.COLORS.slope.left
        else
            return Defs.TERRAIN_SYSTEM.COLORS.slope.right
        end
    end
end

function Grid:drawWater(cell, isoPos)
    love.graphics.setColor(Defs.TERRAIN_SYSTEM.COLORS.water)
    local points = {
        isoPos.x - Defs.SYSTEM.GRID.ISO_SCALE_X,
        isoPos.y - cell.waterLevel * Defs.TERRAIN_SYSTEM.HEIGHT_STEP,
        isoPos.x,
        isoPos.y - cell.waterLevel * Defs.TERRAIN_SYSTEM.HEIGHT_STEP - 
                   Defs.SYSTEM.GRID.ISO_SCALE_Y,
        isoPos.x + Defs.SYSTEM.GRID.ISO_SCALE_X,
        isoPos.y - cell.waterLevel * Defs.TERRAIN_SYSTEM.HEIGHT_STEP,
        isoPos.x,
        isoPos.y - cell.waterLevel * Defs.TERRAIN_SYSTEM.HEIGHT_STEP + 
                   Defs.SYSTEM.GRID.ISO_SCALE_Y
    }
    love.graphics.polygon('fill', points)
end

function Grid:drawHover(camera)
    if self.hover then
        local cell = self:getCell(self.hover.x, self.hover.y)
        if cell then
            local isoPos = self:gridToIso(self.hover.x, self.hover.y)
            love.graphics.setColor(1, 1, 1, 0.3)
            local points = self:calculateTerrainPoints(cell, isoPos)
            love.graphics.polygon('fill', points)
        end
    end
end

return Grid