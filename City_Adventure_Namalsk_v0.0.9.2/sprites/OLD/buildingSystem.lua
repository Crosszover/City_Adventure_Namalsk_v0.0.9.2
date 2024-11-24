-- buildingSystem.lua
local Defs = require("definitions")

local BuildingSystem = {}
BuildingSystem.__index = BuildingSystem

function BuildingSystem:new(grid, resourceManager)
    local system = {
        grid = grid,
        resourceManager = resourceManager,
        buildMode = false,
        selectedBuilding = nil,
        buildPreview = {
            x = 0,
            y = 0,
            valid = false,
            rotation = 0
        },
        lastBuilt = nil
    }
    setmetatable(system, self)
    return system
end

function BuildingSystem:update(dt)
    if self.buildMode and self.grid.hover then
        self.buildPreview.x = self.grid.hover.x
        self.buildPreview.y = self.grid.hover.y
        self.buildPreview.valid = self:canBuildAt(
            self.grid.hover.x, 
            self.grid.hover.y, 
            self.selectedBuilding
        )
    end
end

function BuildingSystem:draw(camera)
    if self.buildMode and self.selectedBuilding then
        self:drawBuildPreview()
    end
end

function BuildingSystem:drawBuildPreview()
    if not self.grid.hover then return end
    
    local buildingDef = Defs.getBuildingById(self.selectedBuilding)
    if not buildingDef then return end
    
    local x, y = self.buildPreview.x, self.buildPreview.y
    local isValid = self:canBuildAt(x, y, self.selectedBuilding)
    
    -- Color según validez
    love.graphics.setColor(
        isValid and Defs.UI.COLORS.PREVIEW_VALID or Defs.UI.COLORS.PREVIEW_INVALID
    )
    
    -- Dibujar área de construcción
    for offsetY = 0, buildingDef.size.height - 1 do
        for offsetX = 0, buildingDef.size.width - 1 do
            local cell = self.grid:getCell(x + offsetX, y + offsetY)
            if cell then
                local isoPos = self.grid:gridToIso(x + offsetX, y + offsetY)
                local points = self.grid:calculateTerrainPoints(cell, isoPos)
                love.graphics.polygon('fill', points)
            end
        end
    end
    
    -- Dibujar sprite del edificio si existe
    if sprites[buildingDef.sprite] and isValid then
        love.graphics.setColor(1, 1, 1, 0.5)
        local isoPos = self.grid:gridToIso(x, y)
        love.graphics.draw(
            sprites[buildingDef.sprite],
            isoPos.x - Defs.SYSTEM.GRID.ISO_SCALE_X,
            isoPos.y - buildingDef.size.height * Defs.TERRAIN_SYSTEM.HEIGHT_STEP,
            self.buildPreview.rotation,
            1, 1,
            sprites[buildingDef.sprite]:getWidth()/2,
            sprites[buildingDef.sprite]:getHeight()
        )
    end
end

function BuildingSystem:selectBuilding(buildingType)
    self.buildMode = true
    self.selectedBuilding = buildingType
    self.buildPreview.rotation = 0
end

function BuildingSystem:canBuildAt(x, y, buildingType)
    if not buildingType then return false end
    
    local buildingDef = Defs.getBuildingById(buildingType)
    if not buildingDef then return false end
    
    -- Verificar que hay suficiente dinero
    if not self.resourceManager:canAfford("build", {buildingType = buildingType}) then
        return false
    end
    
    -- Verificar área completa
    for offsetY = 0, buildingDef.size.height - 1 do
        for offsetX = 0, buildingDef.size.width - 1 do
            local cell = self.grid:getCell(x + offsetX, y + offsetY)
            if not cell then return false end
            
            -- Verificar terreno nivelado
            if not self.grid:isCellLevel(cell) then return false end
            
            -- Verificar que no hay agua
            if cell.waterLevel >= 0 then return false end
            
            -- Verificar que no hay otras construcciones
            if cell.building or cell.road then return false end
        end
    end
    
    return true
end

function BuildingSystem:tryPlaceBuilding(x, y)
    if not self.buildMode or not self.selectedBuilding then return false end
    
    if self:canBuildAt(x, y, self.selectedBuilding) then
        return self:placeBuilding(x, y, self.selectedBuilding)
    end
    
    return false
end

function BuildingSystem:placeBuilding(x, y, buildingType)
    local buildingDef = Defs.getBuildingById(buildingType)
    if not buildingDef then return false end
    
    -- Intentar gastar recursos
    if not self.resourceManager:spend("build", {buildingType = buildingType}) then
        return false
    end
    
    -- Colocar edificio principal
    local mainCell = self.grid:getCell(x, y)
    mainCell.building = {
        type = buildingType,
        rotation = self.buildPreview.rotation,
        health = 100,
        mainTile = true
    }
    
    -- Colocar tiles secundarios para edificios grandes
    for offsetY = 0, buildingDef.size.height - 1 do
        for offsetX = 0, buildingDef.size.width - 1 do
            if offsetX > 0 or offsetY > 0 then
                local cell = self.grid:getCell(x + offsetX, y + offsetY)
                cell.building = {
                    type = buildingType,
                    mainTile = false,
                    mainX = x,
                    mainY = y
                }
            end
        end
    end
    
    self.lastBuilt = {
        x = x,
        y = y,
        type = buildingType
    }
    
    return true
end

function BuildingSystem:rotate()
    if self.buildMode and self.selectedBuilding then
        self.buildPreview.rotation = self.buildPreview.rotation + math.pi/2
        if self.buildPreview.rotation >= math.pi * 2 then
            self.buildPreview.rotation = 0
        end
    end
end

function BuildingSystem:cancelBuildMode()
    self.buildMode = false
    self.selectedBuilding = nil
    self.buildPreview.rotation = 0
end

return BuildingSystem