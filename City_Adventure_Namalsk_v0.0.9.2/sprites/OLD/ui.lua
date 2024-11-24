-- UI.lua
local Defs = require("definitions")

local UI = {}
UI.__index = UI

function UI:new(resourceManager)
    local ui = {
        resourceManager = resourceManager,
        panels = {},
        activeTooltip = nil,
        buildMenu = {
            visible = false,
            selectedCategory = nil,
            scroll = 0,
            buttons = {}
        },
        toolPanel = {
            visible = true,
            activeTool = nil,
            brushSize = 1
        },
        notifications = {}
    }
    setmetatable(ui, self)
    ui:initializePanels()
    return ui
end

function UI:initializePanels()
    -- Panel superior con recursos
    self.panels.top = {
        x = 0,
        y = 0,
        width = love.graphics.getWidth(),
        height = Defs.UI.SIZES.PANEL_HEIGHT,
        visible = true
    }
    
    -- Panel de herramientas (izquierda)
    self.panels.tools = {
        x = 10,
        y = Defs.UI.SIZES.PANEL_HEIGHT + 10,
        width = Defs.UI.SIZES.BUTTON_SIZE + 20,
        height = 200,
        visible = true
    }
    
    -- Panel de construcción (derecha)
    self.panels.build = {
        x = love.graphics.getWidth() - Defs.UI.SIZES.MENU_WIDTH,
        y = Defs.UI.SIZES.PANEL_HEIGHT,
        width = Defs.UI.SIZES.MENU_WIDTH,
        height = love.graphics.getHeight() - Defs.UI.SIZES.PANEL_HEIGHT,
        visible = false
    }
    
    -- Inicializar botones del menú de construcción
    self:initializeBuildButtons()
end

function UI:initializeBuildButtons()
    self.buildMenu.buttons = {}
    for i, category in ipairs(Defs.CATEGORIES) do
        table.insert(self.buildMenu.buttons, {
            id = category.id,
            name = category.name,
            icon = category.icon,
            y = Defs.UI.SIZES.PANEL_HEIGHT + (i-1) * 40
        })
    end
end

function UI:draw()
    self:drawPanels()
    self:drawTooltip()
    self:drawNotifications()
end

function UI:drawPanels()
    -- Panel superior
    self:drawTopPanel()
    
    -- Panel de herramientas
    if self.panels.tools.visible then
        self:drawToolsPanel()
    end
    
    -- Panel de construcción
    if self.panels.build.visible then
        self:drawBuildPanel()
    end
end

function UI:drawTopPanel()
    -- Fondo del panel
    love.graphics.setColor(Defs.UI.COLORS.PANEL)
    love.graphics.rectangle('fill', 
        self.panels.top.x, 
        self.panels.top.y, 
        self.panels.top.width, 
        self.panels.top.height
    )
    
    -- Información de recursos
    love.graphics.setColor(Defs.UI.COLORS.TEXT)
    local resources = self.resourceManager:getResources()
    local x = 10
    
    -- Dinero
    love.graphics.print(string.format("$%d", resources.money), x, 10)
    x = x + 100
    
    -- Población
    if resources.population then
        love.graphics.print(string.format("População: %d", resources.population), x, 10)
        x = x + 150
    end
    
    -- Otros recursos si existen
    if resources.power then
        love.graphics.print(string.format("Energia: %d/%d", 
            resources.power.supply or 0, 
            resources.power.demand or 0), x, 10)
        x = x + 150
    end
end

function UI:drawToolsPanel()
    -- Fondo del panel
    love.graphics.setColor(Defs.UI.COLORS.PANEL)
    love.graphics.rectangle('fill',
        self.panels.tools.x,
        self.panels.tools.y,
        self.panels.tools.width,
        self.panels.tools.height
    )
    
    -- Herramientas de terreno
    local y = self.panels.tools.y + 10
    local tools = {"raise", "lower", "level"}
    
    for _, tool in ipairs(tools) do
        local isActive = self.toolPanel.activeTool == tool
        love.graphics.setColor(isActive and Defs.UI.COLORS.BUTTON_ACTIVE or Defs.UI.COLORS.BUTTON)
        love.graphics.rectangle('fill',
            self.panels.tools.x + 10,
            y,
            Defs.UI.SIZES.BUTTON_SIZE,
            Defs.UI.SIZES.BUTTON_SIZE
        )
        
        if sprites["terrain_" .. tool] then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sprites["terrain_" .. tool],
                self.panels.tools.x + 14,
                y + 4
            )
        end
        
        y = y + Defs.UI.SIZES.BUTTON_SIZE + 5
    end
    
    -- Tamaño del pincel si hay una herramienta activa
    if self.toolPanel.activeTool then
        love.graphics.setColor(Defs.UI.COLORS.TEXT)
        love.graphics.print("Tamaño: " .. self.toolPanel.brushSize,
            self.panels.tools.x + 10,
            y + 10
        )
    end
end

function UI:drawBuildPanel()
    -- Fondo del panel
    love.graphics.setColor(Defs.UI.COLORS.PANEL)
    love.graphics.rectangle('fill',
        self.panels.build.x,
        self.panels.build.y,
        self.panels.build.width,
        self.panels.build.height
    )
    
    -- Botones de categorías
    for _, button in ipairs(self.buildMenu.buttons) do
        local isSelected = self.buildMenu.selectedCategory == button.id
        love.graphics.setColor(isSelected and Defs.UI.COLORS.BUTTON_ACTIVE or Defs.UI.COLORS.BUTTON)
        love.graphics.rectangle('fill',
            self.panels.build.x,
            button.y,
            self.panels.build.width,
            40
        )
        
        -- Icono si existe
        if sprites[button.icon] then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sprites[button.icon],
                self.panels.build.x + 5,
                button.y + 4
            )
        end
        
        -- Nombre
        love.graphics.setColor(Defs.UI.COLORS.TEXT)
        love.graphics.print(button.name,
            self.panels.build.x + 40,
            button.y + 12
        )
    end
    
    -- Contenido de la categoría seleccionada
    if self.buildMenu.selectedCategory then
        self:drawCategoryContent()
    end
end

function UI:drawCategoryContent()
    local items = {}
    if self.buildMenu.selectedCategory == "residential" or
       self.buildMenu.selectedCategory == "commercial" or
       self.buildMenu.selectedCategory == "industrial" then
        items = Defs.getBuildingsByCategory(self.buildMenu.selectedCategory)
    end
    
    local y = self.panels.build.y + #self.buildMenu.buttons * 40 - self.buildMenu.scroll
    for _, item in ipairs(items) do
        if y + 40 > self.panels.build.y and y < self.panels.build.y + self.panels.build.height then
            love.graphics.setColor(Defs.UI.COLORS.BUTTON)
            love.graphics.rectangle('fill',
                self.panels.build.x,
                y,
                self.panels.build.width,
                40
            )
            
            if sprites[item.sprite] then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(sprites[item.sprite],
                    self.panels.build.x + 5,
                    y + 4,
                    0, 0.5, 0.5
                )
            end
            
            love.graphics.setColor(Defs.UI.COLORS.TEXT)
            love.graphics.print(item.name,
                self.panels.build.x + 40,
                y + 5
            )
            love.graphics.print(string.format("$%d", item.cost),
                self.panels.build.x + 40,
                y + 22
            )
        end
        y = y + 40
    end
end

function UI:drawTooltip()
    if not self.activeTooltip then return end
    
    local mx, my = love.mouse.getPosition()
    local text = self.activeTooltip
    local font = love.graphics.getFont()
    local width = font:getWidth(text) + 20
    local height = font:getHeight() + 10
    
    -- Ajustar posición para que no se salga de la pantalla
    local x = mx + 10
    local y = my + 10
    if x + width > love.graphics.getWidth() then
        x = love.graphics.getWidth() - width
    end
    if y + height > love.graphics.getHeight() then
        y = love.graphics.getHeight() - height
    end
    
    -- Dibujar tooltip
    love.graphics.setColor(Defs.UI.COLORS.PANEL)
    love.graphics.rectangle('fill', x, y, width, height)
    love.graphics.setColor(Defs.UI.COLORS.TEXT)
    love.graphics.print(text, x + 10, y + 5)
end

function UI:drawNotifications()
    local x = 10
    local y = love.graphics.getHeight() - 100
    
    for i = #self.notifications, 1, -1 do
        local notification = self.notifications[i]
        if notification.alpha > 0 then
            love.graphics.setColor(1, 1, 1, notification.alpha)
            love.graphics.print(notification.text, x, y)
            y = y - 20
        end
    end
end

function UI:update(dt)
    -- Actualizar notificaciones
    for i = #self.notifications, 1, -1 do
        local notification = self.notifications[i]
        notification.alpha = notification.alpha - dt
        if notification.alpha <= 0 then
            table.remove(self.notifications, i)
        end
    end
end

function UI:handleMousePressed(x, y, button)
    if button == 1 then
        -- Verificar click en herramientas
        if self:isInsideToolsPanel(x, y) then
            return self:handleToolClick(x, y)
        end
        
        -- Verificar click en menú de construcción
        if self.panels.build.visible and self:isInsideBuildPanel(x, y) then
            return self:handleBuildMenuClick(x, y)
        end
    end
    return false
end

function UI:isInsideToolsPanel(x, y)
    return x >= self.panels.tools.x and
           x <= self.panels.tools.x + self.panels.tools.width and
           y >= self.panels.tools.y and
           y <= self.panels.tools.y + self.panels.tools.height
end

function UI:isInsideBuildPanel(x, y)
    return x >= self.panels.build.x and
           x <= self.panels.build.x + self.panels.build.width and
           y >= self.panels.build.y and
           y <= self.panels.build.y + self.panels.build.height
end

function UI:handleToolClick(x, y)
    local toolY = self.panels.tools.y + 10
    local tools = {"raise", "lower", "level"}
    
    for _, tool in ipairs(tools) do
        if y >= toolY and y < toolY + Defs.UI.SIZES.BUTTON_SIZE then
            self.toolPanel.activeTool = tool
            return true
        end
        toolY = toolY + Defs.UI.SIZES.BUTTON_SIZE + 5
    end
    
    return false
end

function UI:handleBuildMenuClick(x, y)
    -- Click en categorías
    for _, button in ipairs(self.buildMenu.buttons) do
        if y >= button.y and y < button.y + 40 then
            self.buildMenu.selectedCategory = button.id
            self.buildMenu.scroll = 0
            return true
        end
    end
    
    -- Click en items de la categoría
    if self.buildMenu.selectedCategory then
        local itemY = self.panels.build.y + #self.buildMenu.buttons * 40 - self.buildMenu.scroll
        local items = Defs.getBuildingsByCategory(self.buildMenu.selectedCategory)
        
        for _, item in ipairs(items) do
            if y >= itemY and y < itemY + 40 then
                if self.onItemSelected then
                    self.onItemSelected(item)
                end
                return true
            end
            itemY = itemY + 40
        end
    end
    
    return false
end

function UI:toggleBuildMenu()
    self.panels.build.visible = not self.panels.build.visible
    if not self.panels.build.visible then
        self.buildMenu.selectedCategory = nil
    end
end

function UI:addNotification(text)
    table.insert(self.notifications, {
        text = text,
        alpha = 1
    })
end

function UI:setTooltip(text)
    self.activeTooltip = text
end

function UI:clearTooltip()
    self.activeTooltip = nil
end

function UI:resize(w, h)
    self.panels.top.width = w
    self.panels.build.x = w - Defs.UI.SIZES.MENU_WIDTH
    self.panels.build.height = h - Defs.UI.SIZES.PANEL_HEIGHT
end

return UI