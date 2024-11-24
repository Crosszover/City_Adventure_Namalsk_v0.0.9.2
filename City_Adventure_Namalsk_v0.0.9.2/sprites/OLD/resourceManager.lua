-- ResourceManager.lua
local Defs = require("definitions")

local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager:new()
    local manager = {
        resources = {
            money = Defs.GAME_RULES.STARTING_MONEY,
            population = 0,
            workers = 0,
            power = {supply = 0, demand = 0},
            water = {supply = 0, demand = 0}
        },
        buildings = {},
        lastUpdate = 0,
        updateInterval = 1  -- Actualizar cada segundo
    }
    setmetatable(manager, self)
    return manager
end

function ResourceManager:update(dt)
    self.lastUpdate = self.lastUpdate + dt
    if self.lastUpdate >= self.updateInterval then
        self:updateResources()
        self.lastUpdate = 0
    end
end

function ResourceManager:updateResources()
    -- Reiniciar contadores
    local newResources = {
        money = self.resources.money,
        population = 0,
        workers = 0,
        power = {supply = 0, demand = 0},
        water = {supply = 0, demand = 0}
    }
    
    -- Actualizar recursos por edificio
    for _, building in pairs(self.buildings) do
        local buildingDef = Defs.getBuildingById(building.type)
        if buildingDef then
            -- Costos de mantenimiento
            if buildingDef.maintenance then
                newResources.money = newResources.money - buildingDef.maintenance
            end
            
            -- Población y trabajadores
            if buildingDef.inhabitants then
                newResources.population = newResources.population + buildingDef.inhabitants
            end
            if buildingDef.jobs then
                newResources.workers = newResources.workers + buildingDef.jobs
            end
        end
    end
    
    self.resources = newResources
end

function ResourceManager:canAfford(action, params)
    if action == "build" then
        local buildingDef = Defs.getBuildingById(params.buildingType)
        if buildingDef then
            return self.resources.money >= buildingDef.cost
        end
    elseif action == "terrain" then
        local cost = Defs.GAME_RULES.TERRAIN_MODIFICATION_COST * (params.size or 1)
        return self.resources.money >= cost
    end
    return false
end

function ResourceManager:spend(action, params)
    if not self:canAfford(action, params) then
        return false
    end
    
    if action == "build" then
        local buildingDef = Defs.getBuildingById(params.buildingType)
        if buildingDef then
            self.resources.money = self.resources.money - buildingDef.cost
            -- Registrar nuevo edificio
            table.insert(self.buildings, {
                type = params.buildingType,
                x = params.x,
                y = params.y
            })
        end
    elseif action == "terrain" then
        local cost = Defs.GAME_RULES.TERRAIN_MODIFICATION_COST * (params.size or 1)
        self.resources.money = self.resources.money - cost
    end
    
    return true
end

function ResourceManager:addBuilding(buildingType, x, y)
    if self:spend("build", {buildingType = buildingType, x = x, y = y}) then
        return true
    end
    return false
end

function ResourceManager:removeBuilding(x, y)
    for i, building in ipairs(self.buildings) do
        if building.x == x and building.y == y then
            table.remove(self.buildings, i)
            -- Podríamos dar algún reembolso aquí
            return true
        end
    end
    return false
end

function ResourceManager:getResources()
    return self.resources
end

-- Debug info
function ResourceManager:getDebugInfo()
    return {
        money = self.resources.money,
        population = self.resources.population,
        buildings = #self.buildings,
        workers = self.resources.workers
    }
end

return ResourceManager