-- 1. Constantes Globales
WINDOW = {
    width = 1024,
    height = 768,
    title = "City_Adventure_Namalsk_v0.0.9.1"
}

TILE = {
    width = 64,    -- Ancho de tile base
    height = 32,   -- Alto de tile base (mitad del ancho para isométrico)
}

MAP = {
    width = 150,    -- Ancho del mapa en tiles
    height = 150,   -- Alto del mapa en tiles
}

-- Sistema de Naturaleza
NATURE = {
    TYPES = {
        forest = {
            name = "Bosque",
            cost = 50,
            min_height = 1,
            max_height = 3,
            sprite = "sprites/bosque.png"
        }
    }
}

-- Función para inicializar el sistema de naturaleza (después de f036_initObjectives)
-- Función para inicializar el sistema de naturaleza (reemplaza la f044_initNatureSystem anterior)
function f044_initNatureSystem()
    -- Asegurar que existe el almacén de elementos naturales
    GameState.nature = {}
    
    -- Añadir botón de bosque con requisitos de altura corregidos
    table.insert(UI.buttons, {
        id = "place_forest",
        sprite_id = "place_forest",
        x = 250,
        y = (UI.toolbar_height - UI.button_size) / 2,
        width = UI.button_size,
        height = UI.button_size,
        tooltip = "Plantar Bosque (50$)",
        color = {0.3, 0.8, 0.3},
        nature_type = "forest"
    })
    
    -- Cargar sprite del botón
    pcall(function()
        UI.images.buttons["place_forest"] = love.graphics.newImage("assets/ui/btn_forest.png")
    end)
    
    -- Definir tipos de naturaleza con requisitos corregidos
    NATURE.TYPES = {
        forest = {
            name = "Bosque",
            cost = 50,
            min_height = 0,  -- Cambiado para permitir en todos los niveles excepto agua
            max_height = 3,
            sprite = "sprites/bosque.png"
        }
    }
    
    return true
end

-- Función para dibujar elementos naturales (reemplaza la f045_drawNature anterior)
function f045_drawNature()
    if not GameState.nature then return end
    
    love.graphics.push()
    love.graphics.translate(WINDOW.width/2 + Camera.x, WINDOW.height/4 + Camera.y)
    love.graphics.scale(Camera.zoom)
    
    local forestSprite = love.graphics.newImage(NATURE.TYPES.forest.sprite)
    
    for y, row in pairs(GameState.nature) do
        for x, element in pairs(row) do
            if element.type == "forest" then
                local height = GameState.heightmap[y][x]
                local screenX, screenY = f006_isoToScreen(x-1, y-1, height)
                
                -- Calcular sombreado
                local shadingFactor = 1.0
                if height > 0 then  -- Solo aplicar sombreado si no es agua
                    if x > 1 and y > 1 then  -- Evitar errores en bordes
                        local northHeight = GameState.heightmap[y-1][x] or height
                        local westHeight = GameState.heightmap[y][x-1] or height
                        
                        if northHeight > height then
                            shadingFactor = TERRAIN.SHADING.SOUTHEAST
                        elseif westHeight > height then
                            shadingFactor = TERRAIN.SHADING.NORTHEAST
                        else
                            shadingFactor = TERRAIN.SHADING.NORTHWEST
                        end
                    end
                end
                
                love.graphics.setColor(shadingFactor, shadingFactor, shadingFactor, 1)
                love.graphics.draw(forestSprite, screenX, screenY - forestSprite:getHeight())
            end
        end
    end
    
    love.graphics.pop()
end

function f046_handleNatureInput(x, y, button)
    if not GameState.currentTile or GameState.activeTool ~= "place_forest" then 
        return false 
    end
    
    local tileX, tileY = GameState.currentTile.x, GameState.currentTile.y
    
    -- Verificar si es agua
    if GameState.heightmap[tileY][tileX] == 0 then
        return false
    end
    
    -- Verificar dinero
    if GameState.resources.money < NATURE.TYPES.forest.cost then
        return false
    end
    
    -- Verificar ocupación
    if (GameState.nature[tileY] and GameState.nature[tileY][tileX]) or
       (GameState.buildings[tileY] and GameState.buildings[tileY][tileX]) then
        return false
    end
    
    -- Colocar bosque
    if not GameState.nature[tileY] then
        GameState.nature[tileY] = {}
    end
    
    GameState.nature[tileY][tileX] = {
        type = "forest",
        planted_at = love.timer.getTime()
    }
    
    GameState.resources.money = GameState.resources.money - NATURE.TYPES.forest.cost
    
    return true
end

function f047_drawNaturePreview()
    if not GameState.currentTile or GameState.activeTool ~= "place_forest" then
        return
    end

    local x, y = GameState.currentTile.x, GameState.currentTile.y
    local height = GameState.heightmap[y][x]
    local canPlace = true
    local reason = ""
    
    -- Verificaciones simples
    if height == 0 then
        canPlace = false
        reason = "No se puede plantar en agua"
    elseif GameState.resources.money < NATURE.TYPES.forest.cost then
        canPlace = false
        reason = "Fondos insuficientes"
    elseif (GameState.nature[y] and GameState.nature[y][x]) or
           (GameState.buildings[y] and GameState.buildings[y][x]) then
        canPlace = false
        reason = "Espacio ocupado"
    end
    
    love.graphics.push()
    love.graphics.translate(WINDOW.width/2 + Camera.x, WINDOW.height/4 + Camera.y)
    love.graphics.scale(Camera.zoom)
    
    -- Dibujar tile de previsualización
    local x1, y1 = f006_isoToScreen(x-1, y-1, height)
    local x2, y2 = f006_isoToScreen(x, y-1, height)
    local x3, y3 = f006_isoToScreen(x, y, height)
    local x4, y4 = f006_isoToScreen(x-1, y, height)
    
    -- Color de previsualización
    if canPlace then
        love.graphics.setColor(0, 1, 0, 0.3)
    else
        love.graphics.setColor(1, 0, 0, 0.3)
    end
    
    love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3, x4, y4)
    
    -- Previsualización del árbol
    if canPlace then
        local screenX, screenY = f006_isoToScreen(x-1, y-1, height)
        local forestSprite = love.graphics.newImage(NATURE.TYPES.forest.sprite)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(forestSprite, screenX, screenY - forestSprite:getHeight())
    end
    
    -- Mensaje de error
    if not canPlace then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(reason, x1, y1 - 20)
    end
    
    love.graphics.pop()
end

-- 2. Sistema de Terreno
TERRAIN = {
    MIN_HEIGHT = 0,    -- Nivel de agua
    MAX_HEIGHT = 3,    -- Máxima elevación
    STEP_SIZE = 1,     -- Incremento por click
    HEIGHT_FACTOR = 16, -- Factor visual de altura
    
    -- Sistema de colores base
    COLORS = {
        water = {0.2, 0.5, 0.8, 1.0},
        levels = {
            {0.45, 0.75, 0.45, 1.0}, -- Nivel 1 (índice 1)
            {0.50, 0.80, 0.50, 1.0}, -- Nivel 2 (índice 2)
            {0.55, 0.85, 0.55, 1.0}  -- Nivel 3 (índice 3)
        },
        outline = {0.2, 0.2, 0.2, 0.5},
        default = {0.5, 0.5, 0.5, 1.0}
    },

    -- Factores de sombreado según orientación
    SHADING = {
        NORTHWEST = 1.0,    -- Cara noroeste (la más brillante)
        NORTHEAST = 0.85,   -- Cara noreste
        SOUTHWEST = 0.70,   -- Cara suroeste
        SOUTHEAST = 0.55    -- Cara sureste (la más oscura)
    }
}

-- 3. Estado Global del Juego
GameState = {
    grid = {},         -- Información de tiles
    heightmap = {},    -- Alturas del terreno
    buildings = {},    -- Edificios colocados
    resources = {
        money = 1000,
        population = 0,
        happiness = 100
    },
    activeTool = nil,  -- Herramienta seleccionada
    currentTile = nil, -- Tile bajo el cursor
    lastTerrainUpdate = nil -- Control de actualización del terreno
}

-- 4. Cámara
Camera = {
    x = 0,
    y = 0,
    zoom = 1,
    speed = 500,
    drag = false,
    drag_start = nil
}



-- 1. Función Principal de Inicialización
function f001_initGame()
    f002_initWindow()    -- Inicializar ventana
    f003_initCamera()    -- Inicializar cámara
    f004_initGrid()      -- Inicializar grid
    f005_initHeightmap() -- Inicializar heightmap
    f016_initUI()        -- Inicializar UI
    f020_initBuildingSystem() -- Inicializar sistema de edificios
    f030_initEconomy()   -- Inicializar economía
    f033_initSaveSystem() -- Inicializar sistema de guardado
    f036_initObjectives() -- Inicializar sistema de objetivos
    f044_initNatureSystem()    -- Inicializar sistema de naturaleza
    return true
end

-- 2. Inicialización de Ventana
function f002_initWindow()
    love.window.setMode(WINDOW.width, WINDOW.height, {
        resizable = false,
        vsync = true,
        minwidth = 800,
        minheight = 600
    })
    love.window.setTitle(WINDOW.title)
    
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(0.2, 0.3, 0.4)
end

-- 3. Inicialización de Cámara
function f003_initCamera()
    Camera.x = 0
    Camera.y = 0
    Camera.zoom = 1
    Camera.drag = false
    Camera.drag_start = nil
end

-- 4. Inicialización de Grid
function f004_initGrid()
    for y = 1, MAP.height do
        GameState.grid[y] = {}
        for x = 1, MAP.width do
            GameState.grid[y][x] = {
                type = "empty",
                building = nil,
                height = 0
            }
        end
    end
end

-- 5. Inicialización de Heightmap
function f005_initHeightmap()
    for y = 1, MAP.height + 1 do
        GameState.heightmap[y] = {}
        for x = 1, MAP.width + 1 do
            GameState.heightmap[y][x] = 0  -- Todo comienza al nivel del agua
        end
    end
end

-- 6. Funciones de Sombreado
-- Función auxiliar para aplicar sombreado
function f042_applyShading(color, shadingFactor)
    return {
        color[1] * shadingFactor,
        color[2] * shadingFactor,
        color[3] * shadingFactor,
        color[4] or 1.0
    }
end

-- Función para obtener factor de sombreado según la orientación
function f043_getTileShadingFactor(face)
    return TERRAIN.SHADING[face] or 1.0
end

-- 7. Conversión de Coordenadas
function f006_isoToScreen(x, y, z)
    if not x or not y then return 0, 0 end
    z = z or 0
    
    local screenX = (x - y) * (TILE.width / 2)
    local screenY = (x + y) * (TILE.height / 2) - (z * TERRAIN.HEIGHT_FACTOR)
    
    return screenX, screenY
end

-- Conversión de Coordenadas de Pantalla a Isométricas
-- Conversión de Coordenadas de Pantalla a Isométricas
function f007_screenToIso(screenX, screenY)
    -- Ajustar por cámara y zoom
    local worldX = (screenX - WINDOW.width/2 - Camera.x) / Camera.zoom
    local worldY = (screenY - WINDOW.height/4 - Camera.y) / Camera.zoom
    
    -- Convertir a isométrico
    local isoX = (worldX / (TILE.width/2) + worldY / (TILE.height/2)) / 2
    local isoY = (worldY / (TILE.height/2) - worldX / (TILE.width/2)) / 2
    
    -- Devolver coordenadas redondeadas al tile más cercano
    return math.floor(isoX + 0.5), math.floor(isoY + 0.5)
end

-- 8. Callbacks principales de LÖVE
function love.load()
    if f001_initGame() then
        print("Game initialized successfully")
    else
        print("Error initializing game")
    end
end

function love.update(dt)
    -- Control básico de cámara
    if love.keyboard.isDown('w') then
        Camera.y = Camera.y + Camera.speed * dt
    end
    if love.keyboard.isDown('s') then
        Camera.y = Camera.y - Camera.speed * dt
    end
    if love.keyboard.isDown('a') then
        Camera.x = Camera.x + Camera.speed * dt
    end
    if love.keyboard.isDown('d') then
        Camera.x = Camera.x - Camera.speed * dt
    end
end

function love.draw()
    love.graphics.clear(0.2, 0.3, 0.4)
    f013_drawTerrain()
end


-- 1. Función principal para obtener color del tile
function f011_getTileColor(h1, h2, h3, h4)
    -- Validar alturas
    h1 = math.max(TERRAIN.MIN_HEIGHT, math.min(h1 or 0, TERRAIN.MAX_HEIGHT))
    h2 = math.max(TERRAIN.MIN_HEIGHT, math.min(h2 or 0, TERRAIN.MAX_HEIGHT))
    h3 = math.max(TERRAIN.MIN_HEIGHT, math.min(h3 or 0, TERRAIN.MAX_HEIGHT))
    h4 = math.max(TERRAIN.MIN_HEIGHT, math.min(h4 or 0, TERRAIN.MAX_HEIGHT))
    
    -- Determinar si es agua
    local waterCount = 0
    if h1 == 0 then waterCount = waterCount + 1 end
    if h2 == 0 then waterCount = waterCount + 1 end
    if h3 == 0 then waterCount = waterCount + 1 end
    if h4 == 0 then waterCount = waterCount + 1 end
    
    -- Si es mayormente agua, devolver color de agua
    if waterCount > 2 then
        return TERRAIN.COLORS.water
    end
    
    -- Para terreno, usar el nivel más alto para determinar el color
    local maxHeight = math.max(h1, h2, h3, h4)
    return TERRAIN.COLORS.levels[maxHeight] or TERRAIN.COLORS.default
end

-- 2. Función principal de renderizado de tile
function f012_drawTile(x, y)
    -- Obtener alturas de las esquinas
    local h1 = GameState.heightmap[y][x] or 0      -- Superior izquierda
    local h2 = GameState.heightmap[y][x+1] or 0    -- Superior derecha
    local h3 = GameState.heightmap[y+1][x+1] or 0  -- Inferior derecha
    local h4 = GameState.heightmap[y+1][x] or 0    -- Inferior izquierda
    
    -- Calcular posiciones en pantalla
    local x1, y1 = f006_isoToScreen(x-1, y-1, h1)
    local x2, y2 = f006_isoToScreen(x, y-1, h2)
    local x3, y3 = f006_isoToScreen(x, y, h3)
    local x4, y4 = f006_isoToScreen(x-1, y, h4)
    
    -- Contar vértices en agua
    local waterCount = 0
    if h1 == 0 then waterCount = waterCount + 1 end
    if h2 == 0 then waterCount = waterCount + 1 end
    if h3 == 0 then waterCount = waterCount + 1 end
    if h4 == 0 then waterCount = waterCount + 1 end
    
    if waterCount == 3 then
        -- Dibujar primero el tile terrestre con sombreado
        local maxHeight = math.max(h1, h2, h3, h4)
        local baseColor = TERRAIN.COLORS.levels[maxHeight]
        
        -- Determinar la orientación del tile basado en el vértice elevado
        local shadingFactor
        if h1 > 0 then      -- Vértice noroeste elevado
            shadingFactor = TERRAIN.SHADING.NORTHWEST
        elseif h2 > 0 then  -- Vértice noreste elevado
            shadingFactor = TERRAIN.SHADING.NORTHEAST
        elseif h3 > 0 then  -- Vértice sureste elevado
            shadingFactor = TERRAIN.SHADING.SOUTHEAST
        elseif h4 > 0 then  -- Vértice suroeste elevado
            shadingFactor = TERRAIN.SHADING.SOUTHWEST
        end
        
        -- Dibujar tile terrestre completo con sombreado
        love.graphics.setColor(
            baseColor[1] * shadingFactor,
            baseColor[2] * shadingFactor,
            baseColor[3] * shadingFactor,
            baseColor[4]
        )
        love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3, x4, y4)
        
        -- Luego dibujar el triángulo de agua
        love.graphics.setColor(TERRAIN.COLORS.water)
        if h1 > 0 then      -- Superior izquierdo elevado
            love.graphics.polygon('fill', x2, y2, x3, y3, x4, y4)
        elseif h2 > 0 then  -- Superior derecho elevado
            love.graphics.polygon('fill', x1, y1, x3, y3, x4, y4)
        elseif h3 > 0 then  -- Inferior derecho elevado
            love.graphics.polygon('fill', x1, y1, x2, y2, x4, y4)
        elseif h4 > 0 then  -- Inferior izquierdo elevado
            love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3)
        end
    else
        -- Para tiles normales (no 3 vértices de agua)
        if waterCount >= 3 then
            -- Si tiene más de 3 vértices de agua, es un tile de agua
            love.graphics.setColor(TERRAIN.COLORS.water)
        else
            -- Para terreno normal, aplicar sombreado según orientación
            local maxHeight = math.max(h1, h2, h3, h4)
            local baseColor = TERRAIN.COLORS.levels[maxHeight] or TERRAIN.COLORS.default
            
            -- Determinar la orientación del tile basado en las alturas de sus esquinas
            local shadingFactor = 1.0
            if h1 > h3 then  -- Mira hacia noroeste
                shadingFactor = TERRAIN.SHADING.NORTHWEST
            elseif h3 > h1 then  -- Mira hacia sureste
                shadingFactor = TERRAIN.SHADING.SOUTHEAST
            elseif h2 > h4 then  -- Mira hacia noreste
                shadingFactor = TERRAIN.SHADING.NORTHEAST
            elseif h4 > h2 then  -- Mira hacia suroeste
                shadingFactor = TERRAIN.SHADING.SOUTHWEST
            end
            
            -- Aplicar sombreado
            love.graphics.setColor(
                baseColor[1] * shadingFactor,
                baseColor[2] * shadingFactor,
                baseColor[3] * shadingFactor,
                baseColor[4]
            )
        end
        
        -- Dibujar tile completo
        love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3, x4, y4)
    end
    
    -- Dibujar contorno
    love.graphics.setColor(TERRAIN.COLORS.outline)
    love.graphics.setLineWidth(1)
    love.graphics.line(x1, y1, x2, y2, x3, y3, x4, y4, x1, y1)
end

-- 3. Función de renderizado del terreno completo
function f013_drawTerrain()
    love.graphics.push()
    
    -- Aplicar transformación de cámara
    love.graphics.translate(
        WINDOW.width/2 + Camera.x,
        WINDOW.height/4 + Camera.y
    )
    love.graphics.scale(Camera.zoom)
    
    -- Dibujar cada tile
    for y = 1, MAP.height do
        for x = 1, MAP.width do
            f012_drawTile(x, y)
        end
    end
    
    -- Dibujar indicador de terreno
    f014_drawTerrainIndicator()
    
    love.graphics.pop()
end

-- 1. Obtener Vértice Más Cercano
function f010_getNearestVertex(screenX, screenY)
    local worldX = (screenX - WINDOW.width/2 - Camera.x) / Camera.zoom
    local worldY = (screenY - WINDOW.height/4 - Camera.y) / Camera.zoom
    
    local isoX = (worldX / (TILE.width/2) + worldY / (TILE.height/2)) / 2
    local isoY = (worldY / (TILE.height/2) - worldX / (TILE.width/2)) / 2
    
    local vertexX = math.floor(isoX + 0.5)
    local vertexY = math.floor(isoY + 0.5)
    
    -- Validar límites
    if vertexX >= 1 and vertexX <= MAP.width + 1 and
       vertexY >= 1 and vertexY <= MAP.height + 1 then
        return vertexX, vertexY
    end
    
    return nil, nil
end

-- 2. Dibujar Indicador de Vértice
function f014_drawTerrainIndicator()
    if not GameState.activeTool or
       (GameState.activeTool ~= "terrain_up" and 
        GameState.activeTool ~= "terrain_down") then
        return
    end
    
    local mx, my = love.mouse.getPosition()
    local vertexX, vertexY = f010_getNearestVertex(mx, my)
    
    if vertexX and vertexY then
        local height = GameState.heightmap[vertexY][vertexX]
        local screenX, screenY = f006_isoToScreen(vertexX-1, vertexY-1, height)
        
        -- Color según altura
        if height == 0 then
            love.graphics.setColor(TERRAIN.COLORS.water)
        elseif height == TERRAIN.MAX_HEIGHT then
            love.graphics.setColor(0.7, 0.9, 0.7, 1.0)
        else
            love.graphics.setColor(0.6, 0.8, 0.6, 1.0)
        end
        
        -- Dibujar círculo indicador
        love.graphics.circle('fill', screenX, screenY, 4 * Camera.zoom)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle('line', screenX, screenY, 4 * Camera.zoom)
        
        -- Mostrar nivel actual
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(
            tostring(height),
            screenX + 6 * Camera.zoom,
            screenY - 8 * Camera.zoom
        )
    end
end

-- 3. Manejo de Input de Terreno
function f015_handleTerrainInput(x, y, button)
    if not GameState.activeTool then return false end
    
    local vertexX, vertexY = f010_getNearestVertex(x, y)
    if not vertexX or not vertexY then return false end
    
    -- Obtener altura actual
    local currentHeight = GameState.heightmap[vertexY][vertexX]
    
    -- Solo permitir un cambio si ha pasado suficiente tiempo
    if GameState.lastTerrainUpdate and 
       love.timer.getTime() - GameState.lastTerrainUpdate < 0.2 then
        return false
    end
    
    -- Modificar altura según la herramienta
    local changed = false
    local newHeight = currentHeight
    
    if GameState.activeTool == "terrain_up" and currentHeight < TERRAIN.MAX_HEIGHT then
        newHeight = currentHeight + 1
        changed = true
    elseif GameState.activeTool == "terrain_down" and currentHeight > TERRAIN.MIN_HEIGHT then
        newHeight = currentHeight - 1
        changed = true
    end
    
    -- Si hubo cambio, aplicar el cambio y nivelar
    if changed then
        GameState.lastTerrainUpdate = love.timer.getTime()
        GameState.heightmap[vertexY][vertexX] = newHeight
        -- Aplicar auto-nivelado después del cambio
        f041_autoLevel(vertexX, vertexY)
    end
    
    return changed
end

-- 4. Auto-nivelado de Terreno
function f041_autoLevel(x, y)
    -- Obtener altura del vértice actual
    local currentHeight = GameState.heightmap[y][x]
    
    -- Definir vértices adyacentes
    local adjacentVertices = {
        {x = x, y = y-1},    -- Arriba
        {x = x+1, y = y},    -- Derecha
        {x = x, y = y+1},    -- Abajo
        {x = x-1, y = y}     -- Izquierda
    }
    
    -- Verificar cada vértice adyacente
    for _, vertex in ipairs(adjacentVertices) do
        if vertex.x >= 1 and vertex.x <= MAP.width + 1 and
           vertex.y >= 1 and vertex.y <= MAP.height + 1 then
            
            local adjacentHeight = GameState.heightmap[vertex.y][vertex.x]
            local heightDiff = math.abs(currentHeight - adjacentHeight)
            
            -- Si la diferencia es mayor a 1 nivel
            if heightDiff > 1 then
                if currentHeight < adjacentHeight then
                    -- Bajar el adyacente
                    local newHeight = currentHeight + 1
                    if newHeight >= TERRAIN.MIN_HEIGHT then
                        GameState.heightmap[vertex.y][vertex.x] = newHeight
                        f041_autoLevel(vertex.x, vertex.y)
                    end
                else
                    -- Subir el adyacente
                    local newHeight = currentHeight - 1
                    if newHeight <= TERRAIN.MAX_HEIGHT then
                        GameState.heightmap[vertex.y][vertex.x] = newHeight
                        f041_autoLevel(vertex.x, vertex.y)
                    end
                end
            end
        end
    end
end

-- 5. Detección de Punto en Tile
function f008_isPointInTile(tileX, tileY, screenX, screenY)
    if not (tileX and tileY and 
           GameState.heightmap[tileY] and 
           GameState.heightmap[tileY][tileX]) then
        return false
    end
    
    -- Obtener altura y esquinas del tile
    local height = GameState.heightmap[tileY][tileX]
    local x1, y1 = f006_isoToScreen(tileX-1, tileY-1, height)
    local x2, y2 = f006_isoToScreen(tileX, tileY-1, height)
    local x3, y3 = f006_isoToScreen(tileX, tileY, height)
    local x4, y4 = f006_isoToScreen(tileX-1, tileY, height)
    
    -- Ajustar coordenadas del mouse
    screenX = (screenX - WINDOW.width/2 - Camera.x) / Camera.zoom
    screenY = (screenY - WINDOW.height/4 - Camera.y) / Camera.zoom
    
    -- Funciones auxiliares para detección de punto
    local function cross(x1, y1, x2, y2)
        return x1 * y2 - y1 * x2
    end
    
    local function sameSide(px, py, ax, ay, bx, by, cx, cy)
        local b1 = cross(bx - ax, by - ay, px - ax, py - ay)
        local b2 = cross(bx - ax, by - ay, cx - ax, cy - ay)
        return (b1 < 0) == (b2 < 0)
    end
    
    -- Verificar si el punto está dentro del tile
    return sameSide(screenX, screenY, x1, y1, x2, y2, x3, y3) and
           sameSide(screenX, screenY, x2, y2, x3, y3, x4, y4) and
           sameSide(screenX, screenY, x3, y3, x4, y4, x1, y1) and
           sameSide(screenX, screenY, x4, y4, x1, y1, x2, y2)
end

-- 1. Definición del Sistema UI
UI = {
    toolbar_height = 64,
    button_size = 32,
    buttons = {},
    active_button = nil,
    hover_button = nil,
    images = {
        buttons = {},
        toolbar = nil
    }
}

-- 2. Inicialización de UI
function f016_initUI()
    -- Intentar cargar toolbar
    pcall(function()
        UI.images.toolbar = love.graphics.newImage("assets/ui/toolbar.png")
    end)
    
    -- Definición de botones
    local buttonDefs = {
        {
            id = "terrain_up",
            file = "btn_terrain_up.png",
            tooltip = "Subir Terreno (0-3)",
            x = 10,
            color = {0.7, 0.9, 0.7}
        },
        {
            id = "terrain_down",
            file = "btn_terrain_down.png",
            tooltip = "Bajar Terreno",
            x = 50,
            color = {0.9, 0.7, 0.7}
        }
    }
    
    -- Crear botones
    UI.buttons = {}
    for _, def in ipairs(buttonDefs) do
        -- Intentar cargar sprite del botón
        pcall(function()
            UI.images.buttons[def.id] = love.graphics.newImage("assets/ui/" .. def.file)
        end)
        
        -- Añadir botón
        table.insert(UI.buttons, {
            id = def.id,
            sprite_id = def.id,
            x = def.x,
            y = (UI.toolbar_height - UI.button_size) / 2,
            width = UI.button_size,
            height = UI.button_size,
            tooltip = def.tooltip,
            color = def.color
        })
    end
end

-- 3. Actualización de UI
function f017_updateUI()
    local mx, my = love.mouse.getPosition()
    UI.hover_button = nil
    
    -- Verificar hover en botones
    for _, button in ipairs(UI.buttons) do
        if mx >= button.x and mx <= button.x + button.width and
           my >= button.y and my <= button.y + button.height then
            UI.hover_button = button
            
            -- Actualizar tooltip de altura si es herramienta de terreno
            if button.id == "terrain_up" then
                local vertexX, vertexY = f010_getNearestVertex(mx, my)
                if vertexX and vertexY then
                    local height = GameState.heightmap[vertexY][vertexX]
                    button.tooltip = string.format("Subir Terreno (Nivel: %d/%d)", 
                                                 height, TERRAIN.MAX_HEIGHT)
                end
            end
            break
        end
    end
end

-- 4. Dibujo de UI
function f018_drawUI()
    -- Dibujar toolbar
    love.graphics.setColor(1, 1, 1, 1)
    if UI.images.toolbar then
        love.graphics.draw(UI.images.toolbar, 0, 0)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle('fill', 0, 0, WINDOW.width, UI.toolbar_height)
    end
    
    -- Dibujar botones
    for _, button in ipairs(UI.buttons) do
        -- Determinar color del botón
        local color = button.color or {0.6, 0.6, 0.6, 1}
        if button == UI.active_button then
            love.graphics.setColor(color[1] * 1.2, color[2] * 1.2, color[3] * 1.2, 1)
        elseif button == UI.hover_button then
            love.graphics.setColor(color[1] * 1.1, color[2] * 1.1, color[3] * 1.1, 1)
        else
            love.graphics.setColor(color)
        end
        
        -- Dibujar botón
        if UI.images.buttons[button.sprite_id] then
            love.graphics.draw(UI.images.buttons[button.sprite_id], button.x, button.y)
        else
            love.graphics.rectangle('fill', button.x, button.y, button.width, button.height)
        end
        
        -- Dibujar borde si está activo
        if button == UI.active_button then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle('line', button.x, button.y, button.width, button.height)
        end
        
        -- Dibujar tooltip
        if button == UI.hover_button then
            love.graphics.setColor(0, 0, 0, 0.8)
            local tooltipWidth = love.graphics.getFont():getWidth(button.tooltip) + 10
            love.graphics.rectangle('fill', 
                                  button.x, 
                                  button.y + button.height + 5, 
                                  tooltipWidth, 
                                  20)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(button.tooltip, 
                              button.x + 5, 
                              button.y + button.height + 5)
        end
    end
end

-- 5. Manejo de Input de UI
function f019_handleUIClick(x, y, button)
    if button ~= 1 then return false end
    
    for _, btn in ipairs(UI.buttons) do
        if x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height then
            -- Toggle del botón
            if UI.active_button == btn then
                UI.active_button = nil
                GameState.activeTool = nil
            else
                UI.active_button = btn
                GameState.activeTool = btn.id
            end
            return true
        end
    end
    
    return false
end

-- 6. Actualización de Coordenadas del Cursor
function f009_updateCoordinates()
    local mouseX, mouseY = love.mouse.getPosition()
    local isoX, isoY = f007_screenToIso(mouseX, mouseY)
    
    -- Actualizar tile actual bajo el cursor
    if isoX >= 1 and isoX <= MAP.width and 
       isoY >= 1 and isoY <= MAP.height and
       f008_isPointInTile(isoX, isoY, mouseX, mouseY) then
        GameState.currentTile = {x = isoX, y = isoY}
    else
        GameState.currentTile = nil
    end
end

-- 7. Actualización de Callbacks de UI
local old_update = love.update
function love.update(dt)
    if old_update then old_update(dt) end
    f017_updateUI()
    f009_updateCoordinates()
end

local old_draw = love.draw
function love.draw()
    if old_draw then old_draw() end
    f018_drawUI()
end

local old_mousepressed = love.mousepressed
function love.mousepressed(x, y, button)
    if f019_handleUIClick(x, y, button) then return end
    if old_mousepressed then old_mousepressed(x, y, button) end
end

-- 1. Definición de Tipos de Edificios
Buildings = {
    types = {
        house = {
            name = "Casa",
            cost = 100,
            size = {width = 1, height = 1},
            income = 10,
            maintenance = 2,
            population = 5,
            min_height = 1,  -- Altura mínima requerida
            max_height = 3   -- Altura máxima permitida
        },
        shop = {
            name = "Tienda",
            cost = 200,
            size = {width = 1, height = 1},
            income = 25,
            maintenance = 5,
            population = 0,
            min_height = 1,
            max_height = 3
        }
    },
    current_rotation = "right"  -- right o left
}

-- 2. Inicialización del Sistema de Edificios
function f020_initBuildingSystem()
    -- Asegurar que existe el almacén de edificios
    GameState.buildings = {}
    
    -- Añadir botones de construcción
    local buildingButtons = {
        {
            id = "build_house",
            file = "btn_house.png",
            tooltip = "Construir Casa (100$)",
            x = 90,
            color = {0.7, 0.8, 1.0},
            building_type = "house"
        },
        {
            id = "build_shop",
            file = "btn_shop.png",
            tooltip = "Construir Tienda (200$)",
            x = 130,
            color = {0.8, 1.0, 0.7},
            building_type = "shop"
        },
        {
            id = "delete_building",
            file = "btn_delete.png",
            tooltip = "Demoler Edificio",
            x = 170,
            color = {1.0, 0.5, 0.5}
        }
    }
    
    -- Añadir botones al sistema UI
    for _, btnDef in ipairs(buildingButtons) do
        pcall(function()
            UI.images.buttons[btnDef.id] = love.graphics.newImage("assets/ui/" .. btnDef.file)
        end)
        
        table.insert(UI.buttons, {
            id = btnDef.id,
            sprite_id = btnDef.id,
            x = btnDef.x,
            y = (UI.toolbar_height - UI.button_size) / 2,
            width = UI.button_size,
            height = UI.button_size,
            tooltip = btnDef.tooltip,
            color = btnDef.color,
            building_type = btnDef.building_type
        })
    end
end

-- 3. Verificación de Construcción
function f021_canBuildAt(buildingType, x, y)
    local buildingInfo = Buildings.types[buildingType]
    if not buildingInfo then return false, "Tipo de edificio inválido" end
    
    -- Verificar dinero
    if GameState.resources.money < buildingInfo.cost then
        return false, "Fondos insuficientes"
    end
    
    -- Verificar límites del mapa
    if x < 1 or y < 1 or 
       x + buildingInfo.size.width > MAP.width or 
       y + buildingInfo.size.height > MAP.height then
        return false, "Fuera de límites"
    end
    
    -- Verificar altura
    local height = GameState.heightmap[y][x]
    if height < buildingInfo.min_height then
        return false, "Terreno muy bajo"
    end
    if height > buildingInfo.max_height then
        return false, "Terreno muy alto"
    end
    
    -- Verificar ocupación
    for checkY = y, y + buildingInfo.size.height - 1 do
        for checkX = x, x + buildingInfo.size.width - 1 do
            if GameState.buildings[checkY] and GameState.buildings[checkY][checkX] then
                return false, "Espacio ocupado"
            end
            -- Verificar que el terreno es uniforme
            if GameState.heightmap[checkY][checkX] ~= height then
                return false, "Terreno irregular"
            end
        end
    end
    
    return true
end

-- 4. Colocación de Edificios
function f022_placeBuilding(buildingType, x, y)
    local canBuild, reason = f021_canBuildAt(buildingType, x, y)
    if not canBuild then return false, reason end
    
    local buildingInfo = Buildings.types[buildingType]
    
    -- Crear el edificio
    local building = {
        type = buildingType,
        rotation = Buildings.current_rotation,
        health = 100,
        constructed_at = love.timer.getTime()
    }
    
    -- Colocar edificio
    for placeY = y, y + buildingInfo.size.height - 1 do
        if not GameState.buildings[placeY] then
            GameState.buildings[placeY] = {}
        end
        for placeX = x, x + buildingInfo.size.width - 1 do
            GameState.buildings[placeY][placeX] = building
        end
    end
    
    -- Aplicar costos y efectos
    GameState.resources.money = GameState.resources.money - buildingInfo.cost
    GameState.resources.population = GameState.resources.population + buildingInfo.population
    
    return true
end

-- 5. Eliminación de Edificios
function f023_removeBuilding(x, y)
    if not GameState.buildings[y] or not GameState.buildings[y][x] then
        return false
    end
    
    local building = GameState.buildings[y][x]
    local buildingInfo = Buildings.types[building.type]
    
    -- Revertir efectos
    GameState.resources.population = GameState.resources.population - buildingInfo.population
    
    -- Eliminar edificio
    GameState.buildings[y][x] = nil
    
    return true
end

-- 6. Dibujo de Edificios
function f024_drawBuildings()
    love.graphics.push()
    love.graphics.translate(WINDOW.width/2 + Camera.x, WINDOW.height/4 + Camera.y)
    love.graphics.scale(Camera.zoom)
    
    for y, row in pairs(GameState.buildings) do
        for x, building in pairs(row) do
            -- Solo dibujar esquina superior izquierda
            if not (row[x-1] == building or 
                   (GameState.buildings[y-1] and GameState.buildings[y-1][x] == building)) then
                local screenX, screenY = f006_isoToScreen(x-0.5, y-0.5, GameState.heightmap[y][x])
                
                -- Color según tipo
                if building.type == "house" then
                    love.graphics.setColor(0.7, 0.7, 1, 1)
                else
                    love.graphics.setColor(0.7, 1, 0.7, 1)
                end
                
                -- Dibujar edificio simple
                local buildingHeight = TILE.height * 2
                love.graphics.polygon('fill',
                    screenX, screenY - buildingHeight,
                    screenX + TILE.width/2, screenY - TILE.height - buildingHeight,
                    screenX, screenY - TILE.height*2 - buildingHeight,
                    screenX - TILE.width/2, screenY - TILE.height - buildingHeight
                )
                
                -- Aplicar sombreado a las caras del edificio
                local baseColor = {0.7, 0.7, 1, 1}  -- Para casas
                if building.type == "shop" then
                    baseColor = {0.7, 1, 0.7, 1}
                end
                
                -- Cara frontal (más oscura)
                local frontColor = f042_applyShading(baseColor, f043_getTileShadingFactor("SOUTHEAST"))
                love.graphics.setColor(frontColor)
                love.graphics.polygon('fill',
                    screenX - TILE.width/2, screenY - TILE.height - buildingHeight,
                    screenX - TILE.width/2, screenY - TILE.height,
                    screenX, screenY,
                    screenX, screenY - buildingHeight
                )
                
                -- Cara lateral (medio oscura)
                local sideColor = f042_applyShading(baseColor, f043_getTileShadingFactor("SOUTHWEST"))
                love.graphics.setColor(sideColor)
                love.graphics.polygon('fill',
                    screenX + TILE.width/2, screenY - TILE.height - buildingHeight,
                    screenX + TILE.width/2, screenY - TILE.height,
                    screenX, screenY,
                    screenX, screenY - buildingHeight
                )
            end
        end
    end
    
    love.graphics.pop()
end

-- 7. Preview de Edificios
function f025_drawBuildingPreview()
    if not GameState.currentTile or not GameState.activeTool then return end
    
    -- Verificar si estamos en modo construcción
    local buildingType = GameState.activeTool:match("build_(.+)")
    if not buildingType then return end
    
    local x, y = GameState.currentTile.x, GameState.currentTile.y
    local buildingInfo = Buildings.types[buildingType]
    if not buildingInfo then return end
    
    -- Obtener estado de construcción
    local canBuild, reason = f021_canBuildAt(buildingType, x, y)
    local previewColor = canBuild and {0, 1, 0, 0.3} or {1, 0, 0, 0.3}
    
    love.graphics.push()
    love.graphics.translate(WINDOW.width/2 + Camera.x, WINDOW.height/4 + Camera.y)
    love.graphics.scale(Camera.zoom)
    
    -- Dibujar área de construcción
    love.graphics.setColor(previewColor)
    for previewY = y, y + buildingInfo.size.height - 1 do
        for previewX = x, x + buildingInfo.size.width - 1 do
            local x1, y1 = f006_isoToScreen(previewX-1, previewY-1, GameState.heightmap[previewY][previewX])
            local x2, y2 = f006_isoToScreen(previewX, previewY-1, GameState.heightmap[previewY][previewX])
            local x3, y3 = f006_isoToScreen(previewX, previewY, GameState.heightmap[previewY][previewX])
            local x4, y4 = f006_isoToScreen(previewX-1, previewY, GameState.heightmap[previewY][previewX])
            
            love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3, x4, y4)
        end
    end
    
    -- Mostrar mensaje de error si no se puede construir
    if not canBuild then
        local screenX, screenY = f006_isoToScreen(x, y, GameState.heightmap[y][x])
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(reason, screenX - 50, screenY - 20)
    end
    
    love.graphics.pop()
end

-- 8. Manejo de Input de Construcción
function f026_handleBuildingInput(x, y, button)
    if not GameState.currentTile then return false end
    
    local buildingType = GameState.activeTool:match("build_(.+)")
    if buildingType then
        return f022_placeBuilding(buildingType, GameState.currentTile.x, GameState.currentTile.y)
    elseif GameState.activeTool == "delete_building" then
        return f023_removeBuilding(GameState.currentTile.x, GameState.currentTile.y)
    end
    
    return false
end

-- 1. Sistema Económico
Economy = {
    update_interval = 1.0,  -- Actualizar cada segundo
    time_accumulated = 0,
    tax_rate = 0.1,        -- 10% de impuestos base
    base_happiness = 100    -- Felicidad base
}


-- Rotación de Edificios
function f028_handleBuildingRotation()
    if love.keyboard.isDown('r') and GameState.activeTool and 
       GameState.activeTool:match("build_") then
        Buildings.current_rotation = Buildings.current_rotation == "right" and "left" or "right"
    end
end

-- 2. Inicialización de Economía
function f030_initEconomy()
    GameState.resources = {
        money = 1000,
        population = 0,
        happiness = 100,
        last_income = 0,
        last_expenses = 0
    }
    
    -- Panel económico
    UI.economy_panel = {
        visible = false,
        x = WINDOW.width - 200,
        y = UI.toolbar_height + 10,
        width = 190,
        height = 100
    }
    
    -- Añadir botón de economía
    table.insert(UI.buttons, {
        id = "economy_panel",
        x = WINDOW.width - 40,
        y = (UI.toolbar_height - UI.button_size) / 2,
        width = UI.button_size,
        height = UI.button_size,
        tooltip = "Panel Económico",
        color = {1.0, 0.8, 0.2}
    })
end

-- 3. Actualización de Economía
function f031_updateEconomy(dt)
    Economy.time_accumulated = Economy.time_accumulated + dt
    
    if Economy.time_accumulated >= Economy.update_interval then
        -- Cálculos básicos
        local income = GameState.resources.population * Economy.tax_rate * 100
        local expenses = 0
        
        -- Calcular gastos de edificios
        for y, row in pairs(GameState.buildings) do
            for x, building in pairs(row) do
                expenses = expenses + Buildings.types[building.type].maintenance
            end
        end
        
        -- Actualizar recursos
        GameState.resources.money = GameState.resources.money + income - expenses
        GameState.resources.last_income = income
        GameState.resources.last_expenses = expenses
        
        -- Actualizar felicidad
        GameState.resources.happiness = math.max(0, math.min(100,
            Economy.base_happiness + 
            (GameState.resources.money > 0 and 10 or -10)
        ))
        
        Economy.time_accumulated = 0
    end
end

-- 4. Panel Económico
function f032_drawEconomyPanel()
    if not UI.economy_panel.visible then return end
    
    local panel = UI.economy_panel
    
    -- Fondo
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle('fill', panel.x, panel.y, panel.width, panel.height)
    
    -- Borde
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle('line', panel.x, panel.y, panel.width, panel.height)
    
    -- Información económica
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Dinero: $%d", GameState.resources.money), 
                       panel.x + 10, panel.y + 10)
    love.graphics.print(string.format("Población: %d", GameState.resources.population), 
                       panel.x + 10, panel.y + 30)
    love.graphics.print(string.format("Ingresos: $%d", GameState.resources.last_income), 
                       panel.x + 10, panel.y + 50)
    love.graphics.print(string.format("Gastos: $%d", GameState.resources.last_expenses), 
                       panel.x + 10, panel.y + 70)
end

-- 5. Sistema de Objetivos
Objectives = {
    current_level = 1,
    levels = {
        {
            name = "Villa Inicial",
            description = "Establece tu primera villa",
            requirements = {
                population = 20,
                money = 2000,
                buildings = {
                    house = 4,
                    shop = 1
                }
            },
            rewards = {
                money = 1000
            }
        },
        {
            name = "Pueblo Próspero",
            description = "Expande tu comunidad",
            requirements = {
                population = 50,
                money = 5000,
                happiness = 70,
                buildings = {
                    house = 10,
                    shop = 3
                }
            },
            rewards = {
                money = 2000
            }
        }
    }
}

-- 6. Inicialización de Objetivos
function f036_initObjectives()
    GameState.objectives = {
        current_level = 1,
        completed_levels = {},
        current_progress = {}
    }
    
    -- Panel de objetivos
    UI.objectives_panel = {
        visible = true,
        x = 10,
        y = UI.toolbar_height + 10,
        width = 200,
        height = 150
    }
    
    -- Botón de objetivos
    table.insert(UI.buttons, {
        id = "objectives",
        x = 210,
        y = (UI.toolbar_height - UI.button_size) / 2,
        width = UI.button_size,
        height = UI.button_size,
        tooltip = "Objetivos",
        color = {1.0, 0.8, 0.3}
    })
end

-- 7. Verificar Progreso de Objetivos
function f037_checkObjectives()
    local current = Objectives.levels[GameState.objectives.current_level]
    if not current then return end
    
    local progress = {
        population = {
            current = GameState.resources.population,
            required = current.requirements.population,
            completed = GameState.resources.population >= current.requirements.population
        },
        money = {
            current = GameState.resources.money,
            required = current.requirements.money,
            completed = GameState.resources.money >= current.requirements.money
        },
        happiness = {
            current = GameState.resources.happiness,
            required = current.requirements.happiness,
            completed = GameState.resources.happiness >= (current.requirements.happiness or 0)
        },
        buildings = {}
    }
    
    -- Verificar edificios
    if current.requirements.buildings then
        for building_type, required_amount in pairs(current.requirements.buildings) do
            local count = 0
            for y, row in pairs(GameState.buildings) do
                for x, building in pairs(row) do
                    if building.type == building_type then
                        count = count + 1
                    end
                end
            end
            
            progress.buildings[building_type] = {
                current = count,
                required = required_amount,
                completed = count >= required_amount
            }
        end
    end
    
    -- Actualizar progreso
    GameState.objectives.current_progress = progress
    
    -- Verificar si el nivel está completado
    local all_completed = progress.population.completed and 
                         progress.money.completed and
                         progress.happiness.completed
    
    for _, building_progress in pairs(progress.buildings) do
        all_completed = all_completed and building_progress.completed
    end
    
    if all_completed and not GameState.objectives.completed_levels[GameState.objectives.current_level] then
        f038_completeLevel()
    end
end

-- 8. Completar Nivel
function f038_completeLevel()
    local current = Objectives.levels[GameState.objectives.current_level]
    
    -- Dar recompensas
    if current.rewards.money then
        GameState.resources.money = GameState.resources.money + current.rewards.money
    end
    
    -- Marcar nivel como completado
    GameState.objectives.completed_levels[GameState.objectives.current_level] = true
    
    -- Avanzar al siguiente nivel
    GameState.objectives.current_level = GameState.objectives.current_level + 1
    
    -- Mostrar mensaje de felicitación
    GameState.message = {
        text = "¡Nivel Completado!",
        time = 3,
        color = {1, 1, 0, 1}
    }
end

-- 9. Panel de Objetivos
function f039_drawObjectivesPanel()
    if not UI.objectives_panel.visible then return end
    
    local panel = UI.objectives_panel
    local progress = GameState.objectives.current_progress
    local current = Objectives.levels[GameState.objectives.current_level]
    
    if not current then return end
    
    -- Fondo
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle('fill', panel.x, panel.y, panel.width, panel.height)
    
    -- Título
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print(current.name, panel.x + 10, panel.y + 10)
    
    -- Progreso
    local y = panel.y + 40
    
    local function drawProgressBar(label, current, required, completed)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(label, panel.x + 10, y)
        
        -- Barra de progreso
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle('fill', panel.x + 10, y + 20, 180, 10)
        
        local progress_width = math.min(1, current / required) * 180
        love.graphics.setColor(completed and {0, 1, 0} or {1, 0.5, 0})
        love.graphics.rectangle('fill', panel.x + 10, y + 20, progress_width, 10)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("%d/%d", current, required), 
                          panel.x + 150, y)
        
        return y + 35
    end
    
    if progress.population then
        y = drawProgressBar("Población", 
                          progress.population.current,
                          progress.population.required,
                          progress.population.completed)
    end
    
    if progress.money then
        y = drawProgressBar("Dinero", 
                          progress.money.current,
                          progress.money.required,
                          progress.money.completed)
    end
    
    if progress.buildings then
        for building_type, data in pairs(progress.buildings) do
            y = drawProgressBar(Buildings.types[building_type].name,
                              data.current,
                              data.required,
                              data.completed)
        end
    end
end

-- 1. Sistema de Guardado
SaveSystem = {
    save_folder = "saves",
    current_save = nil,
    autosave_interval = 300  -- 5 minutos
}

-- 2. Inicialización del Sistema de Guardado
function f033_initSaveSystem()
    love.filesystem.createDirectory(SaveSystem.save_folder)
    
    -- Botón de guardado
    table.insert(UI.buttons, {
        id = "save_game",
        x = WINDOW.width - 80,
        y = (UI.toolbar_height - UI.button_size) / 2,
        width = UI.button_size,
        height = UI.button_size,
        tooltip = "Guardar/Cargar",
        color = {0.2, 0.7, 1.0}
    })
end

-- 3. Funciones de Guardado
function f034_saveGame()
    local state = {
        heightmap = GameState.heightmap,
        buildings = GameState.buildings,
        resources = GameState.resources,
        objectives = GameState.objectives,
        version = "1.0"
    }
    
    -- Crear nombre de archivo con timestamp
    local filename = string.format("save_%s.sav", os.date("%Y%m%d_%H%M%S"))
    
    -- Convertir estado a string
    local success = love.filesystem.write(
        SaveSystem.save_folder .. "/" .. filename,
        "PLACEHOLDER_SAVE_" .. os.time()
    )
    
    if success then
        print("Juego guardado: " .. filename)
        return true
    else
        print("Error al guardar")
        return false
    end
end

-- 4. Función de Carga
function f035_loadGame(filename)
    if not filename then return false end
    
    if not love.filesystem.getInfo(SaveSystem.save_folder .. "/" .. filename) then
        print("Archivo no encontrado")
        return false
    end
    
    print("Cargando: " .. filename)
    return true
end

-- 5. Callbacks Principales de LÖVE
function love.load()
    if f001_initGame() then
        print("Game initialized successfully")
    else
        print("Error initializing game")
    end
end

function love.update(dt)
    -- Actualizar cámara
    if love.keyboard.isDown('w') then
        Camera.y = Camera.y + Camera.speed * dt
    end
    if love.keyboard.isDown('s') then
        Camera.y = Camera.y - Camera.speed * dt
    end
    if love.keyboard.isDown('a') then
        Camera.x = Camera.x + Camera.speed * dt
    end
    if love.keyboard.isDown('d') then
        Camera.x = Camera.x - Camera.speed * dt
    end
    
    -- Actualizar rotación de edificios
    f028_handleBuildingRotation()
    
    -- Actualizar economía
    f031_updateEconomy(dt)
    
    -- Actualizar objetivos
    f037_checkObjectives()
    
    -- Actualizar UI
    f017_updateUI()
    
    -- Actualizar coordenadas del cursor
    f009_updateCoordinates()
    
    -- Actualizar mensajes temporales
    if GameState.message and GameState.message.time > 0 then
        GameState.message.time = GameState.message.time - dt
        if GameState.message.time <= 0 then
            GameState.message = nil
        end
    end
end

function love.draw()
    -- Limpiar pantalla
    love.graphics.clear(0.2, 0.3, 0.4)
    
    -- Dibujar terreno y edificios
    f013_drawTerrain()
    f024_drawBuildings()
    f045_drawNature()          -- Dibujar elementos naturales
    
    -- Dibujar UI
    f018_drawUI()
    
    -- Dibujar paneles
    f032_drawEconomyPanel()
    f039_drawObjectivesPanel()
    
    -- Dibujar preview de construcción
    if GameState.activeTool and GameState.activeTool:match("^build_") then
        f025_drawBuildingPreview()
    end
    
    -- Dibujar mensaje si existe
    if GameState.message and GameState.message.time > 0 then
        love.graphics.setColor(GameState.message.color)
        local font = love.graphics.getFont()
        local text_width = font:getWidth(GameState.message.text)
        love.graphics.print(
            GameState.message.text,
            WINDOW.width/2 - text_width/2,
            WINDOW.height/4
        )
    end
end
    if GameState.activeTool then
        if GameState.activeTool:match("^build_") or 
          GameState.activeTool == "delete_building" then
        f026_handleBuildingInput(x, y, button)
    elseif GameState.activeTool:match("^place_") then
        f046_handleNatureInput(x, y, button)
    else
        f015_handleTerrainInput(x, y, button)
    end
end
function love.mousepressed(x, y, button)
    -- Manejar UI primero
    if f019_handleUIClick(x, y, button) then 
        return 
    end
    
    -- Luego manejar construcción/terreno
    if button == 1 then
        if GameState.activeTool then
            if GameState.activeTool:match("^build_") or 
               GameState.activeTool == "delete_building" then
                f026_handleBuildingInput(x, y, button)
            elseif GameState.activeTool:match("^place_") then
                f046_handleNatureInput(x, y, button)
            else
                f015_handleTerrainInput(x, y, button)
            end
        end
    elseif button == 3 then
        -- Iniciar arrastre de cámara
        Camera.drag = true
        Camera.drag_start = {
            x = x - Camera.x,
            y = y - Camera.y
        }
    end
end


function love.mousereleased(x, y, button)
    if button == 3 then
        Camera.drag = false
        Camera.drag_start = nil
    end
end

function love.mousemoved(x, y, dx, dy)
    if Camera.drag then
        Camera.x = x - Camera.drag_start.x
        Camera.y = y - Camera.drag_start.y
    end
end

function love.wheelmoved(x, y)
    -- Zoom con la rueda del ratón
    local old_zoom = Camera.zoom
    Camera.zoom = math.max(0.5, math.min(2, Camera.zoom + y * 0.1))
    
    -- Ajustar posición de la cámara para mantener el punto bajo el cursor
    if old_zoom ~= Camera.zoom then
        local mx, my = love.mouse.getPosition()
        local wx = (mx - WINDOW.width/2 - Camera.x) / old_zoom
        local wy = (my - WINDOW.height/4 - Camera.y) / old_zoom
        
        Camera.x = mx - wx * Camera.zoom - WINDOW.width/2
        Camera.y = my - wy * Camera.zoom - WINDOW.height/4
    end
end

-- 6. Funciones de Ayuda para el Sistema de Guardado
function f040_serializeGameState()
    -- TODO: Implementar serialización real del estado del juego
    return "PLACEHOLDER_STATE"
end

function f041_deserializeGameState(data)
    -- TODO: Implementar deserialización real del estado del juego
    return true
end


-- Función de previsualización para naturaleza (después de f025_drawBuildingPreview)
function f047_drawNaturePreview()
    if not GameState.currentTile or GameState.activeTool ~= "place_forest" then
        return
    end

    local x, y = GameState.currentTile.x, GameState.currentTile.y
    local natureInfo = NATURE.TYPES.forest
    
    -- Verificar si se puede colocar
    local height = GameState.heightmap[y][x]
    local canPlace = true
    local reason = ""
    
    -- Verificar altura
    if height < natureInfo.min_height or height > natureInfo.max_height then
        canPlace = false
        reason = "Altura inadecuada"
    end
    
    -- Verificar dinero
    if GameState.resources.money < natureInfo.cost then
        canPlace = false
        reason = "Fondos insuficientes"
    end
    
    -- Verificar ocupación
    if (GameState.nature[y] and GameState.nature[y][x]) or
       (GameState.buildings[y] and GameState.buildings[y][x]) then
        canPlace = false
        reason = "Espacio ocupado"
    end
    
    love.graphics.push()
    love.graphics.translate(WINDOW.width/2 + Camera.x, WINDOW.height/4 + Camera.y)
    love.graphics.scale(Camera.zoom)
    
    -- Dibujar área de previsualización
    local x1, y1 = f006_isoToScreen(x-1, y-1, height)
    local x2, y2 = f006_isoToScreen(x, y-1, height)
    local x3, y3 = f006_isoToScreen(x, y, height)
    local x4, y4 = f006_isoToScreen(x-1, y, height)
    
    -- Color según si se puede colocar
    if canPlace then
        love.graphics.setColor(0, 1, 0, 0.3)
    else
        love.graphics.setColor(1, 0, 0, 0.3)
    end
    
    -- Dibujar tile de previsualización
    love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3, x4, y4)
    
    -- Si se puede colocar, mostrar previsualización del árbol
    if canPlace then
        local screenX, screenY = f006_isoToScreen(x-0.5, y-0.5, height)
        local forestSprite = love.graphics.newImage(NATURE.TYPES.forest.sprite)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(forestSprite, screenX - forestSprite:getWidth()/2, 
                         screenY - forestSprite:getHeight())
    end
    
    -- Mostrar mensaje de error si no se puede colocar
    if not canPlace then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(reason, x1, y1 - 20)
    end
    
    love.graphics.pop()
end

-- Modificación de la función love.draw() completa
function love.draw()
    -- Limpiar pantalla
    love.graphics.clear(0.2, 0.3, 0.4)
    
    -- Dibujar terreno y edificios
    f013_drawTerrain()
    f024_drawBuildings()
    f045_drawNature()
    
    -- Dibujar UI
    f018_drawUI()
    
    -- Dibujar paneles
    f032_drawEconomyPanel()
    f039_drawObjectivesPanel()
    
    -- Dibujar previews
    if GameState.activeTool then
        if GameState.activeTool:match("^build_") then
            f025_drawBuildingPreview()
        elseif GameState.activeTool:match("^place_") then
            f047_drawNaturePreview()
        end
    end
    
    -- Dibujar mensaje si existe
    if GameState.message and GameState.message.time > 0 then
        love.graphics.setColor(GameState.message.color)
        local font = love.graphics.getFont()
        local text_width = font:getWidth(GameState.message.text)
        love.graphics.print(
            GameState.message.text,
            WINDOW.width/2 - text_width/2,
            WINDOW.height/4
        )
    end
end