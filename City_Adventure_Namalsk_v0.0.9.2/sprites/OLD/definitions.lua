-- definitions.lua
local Definitions = {
    SYSTEM = {
        WINDOW = {
            WIDTH = 1024,
            HEIGHT = 768,
            MIN_WIDTH = 800,
            MIN_HEIGHT = 600
        },
        GRID = {
            SIZE = 100,
            TILE_WIDTH = 64,
            TILE_HEIGHT = 32,
            ISO_SCALE_X = 32,    -- TILE_WIDTH / 2
            ISO_SCALE_Y = 16     -- TILE_HEIGHT / 2
        },
        CAMERA = {
            MOVE_SPEED = 500,
            ZOOM_SPEED = 0.1,
            MIN_ZOOM = 0.5,
            MAX_ZOOM = 2,
            DEFAULT_ZOOM = 1
        }
    },

    TERRAIN_SYSTEM = {
        HEIGHT_STEP = 16,
        MAX_HEIGHT = 5,
        MIN_HEIGHT = 0,
        COLORS = {
            water = {0.2, 0.5, 0.8, 0.8},
            grass = {0.4, 0.8, 0.4},
            dirt = {0.76, 0.7, 0.5},
            slope = {
                flat = {0.45, 0.75, 0.45},
                right = {0.4, 0.7, 0.4},
                left = {0.35, 0.65, 0.35}
            }
        }
    },

    BUILDINGS = {
        HOUSE = {
            id = "house",
            name = "Casa",
            sprite = "house",
            size = {width = 1, height = 1},
            cost = 100,
            category = "residential"
        },
        HOUSE_MEDIUM = {
            id = "house_medium",
            name = "Casa Mediana",
            sprite = "house_medium",
            size = {width = 2, height = 2},
            cost = 200,
            category = "residential"
        },
        FACTORY = {
            id = "factory",
            name = "Fábrica",
            sprite = "factory",
            size = {width = 2, height = 2},
            cost = 500,
            category = "industrial"
        },
        MARKET = {
            id = "market",
            name = "Mercado",
            sprite = "supermarket",
            size = {width = 2, height = 1},
            cost = 300,
            category = "commercial"
        }
    },

    ROADS = {
        STRAIGHT = {
            id = "road_straight",
            name = "Carretera",
            sprite = "road_straight",
            cost = 10
        },
        CORNER = {
            id = "road_corner",
            name = "Curva",
            sprite = "road_corner",
            cost = 10
        },
        INTERSECTION = {
            id = "road_cross",
            name = "Intersección",
            sprite = "road_cross",
            cost = 15
        }
    },

    CATEGORIES = {
        {
            id = "residential",
            name = "Residencial",
            icon = "category_residential"
        },
        {
            id = "commercial",
            name = "Comercial",
            icon = "category_commercial"
        },
        {
            id = "industrial",
            name = "Industrial",
            icon = "category_industrial"
        },
        {
            id = "infrastructure",
            name = "Infraestructura",
            icon = "category_roads"
        },
        {
            id = "terrain",
            name = "Terreno",
            icon = "category_terrain"
        }
    },

    UI = {
        COLORS = {
            PANEL = {0.2, 0.2, 0.2, 0.9},
            BUTTON = {0.3, 0.3, 0.3, 1},
            BUTTON_HOVER = {0.4, 0.4, 0.4, 1},
            BUTTON_ACTIVE = {0.5, 0.5, 0.8, 1},
            TEXT = {1, 1, 1, 1},
            ERROR = {1, 0.3, 0.3, 1},
            SUCCESS = {0.3, 1, 0.3, 1},
            PREVIEW_VALID = {0, 1, 0, 0.3},
            PREVIEW_INVALID = {1, 0, 0, 0.3}
        },
        SIZES = {
            PANEL_HEIGHT = 40,
            BUTTON_SIZE = 32,
            MENU_WIDTH = 200
        }
    },

    GAME_RULES = {
        STARTING_MONEY = 5000,
        MIN_TERRAIN_HEIGHT = 0,
        MAX_TERRAIN_HEIGHT = 5,
        TERRAIN_MODIFICATION_COST = 10,
        MAX_SLOPE = 1
    }
}

-- Funciones de utilidad
function Definitions.getBuildingById(id)
    for _, building in pairs(Definitions.BUILDINGS) do
        if building.id == id then
            return building
        end
    end
    return nil
end

function Definitions.getRoadById(id)
    for _, road in pairs(Definitions.ROADS) do
        if road.id == id then
            return road
        end
    end
    return nil
end

function Definitions.getBuildingsByCategory(category)
    local buildings = {}
    for _, building in pairs(Definitions.BUILDINGS) do
        if building.category == category then
            table.insert(buildings, building)
        end
    end
    return buildings
end

return Definitions