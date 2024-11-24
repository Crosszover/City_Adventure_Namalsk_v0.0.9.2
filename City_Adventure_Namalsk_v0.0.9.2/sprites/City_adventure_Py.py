import pygame
import os
import json
from typing import Dict, List, Tuple

# 1.0 - INITIALIZATION
def init_game() -> Tuple[pygame.surface.Surface, pygame.time.Clock]:
    """Initialize pygame and create main window"""
    pygame.init()
    screen = pygame.display.set_mode((800, 600))
    pygame.display.set_caption("Simple City Builder")
    clock = pygame.time.Clock()
    return screen, clock

# 2.0 - ASSET MANAGEMENT
def load_assets() -> Dict[str, pygame.surface.Surface]:
    """Load all game assets from the same directory"""
    assets = {}
    asset_files = {
        "grass": "grass.png",
        "house": "house.png",
        "shop": "shop.png",
        "factory": "factory.png"
    }
    
    for key, filename in asset_files.items():
        try:
            assets[key] = pygame.image.load(os.path.join(os.path.dirname(__file__), filename))
        except pygame.error:
            # Create colored rectangles as fallback if images not found
            surface = pygame.Surface((32, 32))
            surface.fill(get_fallback_color(key))
            assets[key] = surface
    return assets

def get_fallback_color(building_type: str) -> Tuple[int, int, int]:
    """Fallback colors for missing assets"""
    colors = {
        "grass": (34, 139, 34),    # Green
        "house": (255, 0, 0),      # Red
        "shop": (0, 0, 255),       # Blue
        "factory": (128, 128, 128)  # Gray
    }
    return colors.get(building_type, (0, 0, 0))

# 3.0 - GRID MANAGEMENT
def init_grid(width: int = 20, height: int = 15) -> List[List[str]]:
    """Initialize empty grid with grass"""
    return [["grass" for _ in range(width)] for _ in range(height)]

def get_grid_pos(mouse_pos: Tuple[int, int], cell_size: int = 32) -> Tuple[int, int]:
    """Convert mouse position to grid coordinates"""
    x, y = mouse_pos
    return (x // cell_size, y // cell_size)

# 4.0 - BUILDING MANAGEMENT
def place_building(grid: List[List[str]], pos: Tuple[int, int], building: str) -> bool:
    """Place a building at the specified position"""
    x, y = pos
    if 0 <= y < len(grid) and 0 <= x < len(grid[0]):
        grid[y][x] = building
        return True
    return False

# 5.0 - RENDERING
def render_grid(screen: pygame.surface.Surface, grid: List[List[str]], 
                assets: Dict[str, pygame.surface.Surface], cell_size: int = 32):
    """Render the entire grid"""
    for y in range(len(grid)):
        for x in range(len(grid[0])):
            cell_type = grid[y][x]
            screen.blit(assets[cell_type], (x * cell_size, y * cell_size))

# 6.0 - GAME STATE MANAGEMENT
def save_game(grid: List[List[str]], filename: str = "city_save.json"):
    """Save current game state to file"""
    with open(filename, 'w') as f:
        json.dump(grid, f)

def load_game(filename: str = "city_save.json") -> List[List[str]]:
    """Load game state from file"""
    try:
        with open(filename, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return init_grid()

# 7.0 - MAIN GAME LOOP
def main():
    screen, clock = init_game()
    assets = load_assets()
    grid = init_grid()
    current_building = "house"
    
    running = True
    while running:
        # Event handling
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.MOUSEBUTTONDOWN:
                grid_pos = get_grid_pos(pygame.mouse.get_pos())
                place_building(grid, grid_pos, current_building)
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_1:
                    current_building = "house"
                elif event.key == pygame.K_2:
                    current_building = "shop"
                elif event.key == pygame.K_3:
                    current_building = "factory"
                elif event.key == pygame.K_s:
                    save_game(grid)
                elif event.key == pygame.K_l:
                    grid = load_game()
        
        # Rendering
        screen.fill((0, 0, 0))
        render_grid(screen, grid, assets)
        pygame.display.flip()
        clock.tick(60)

    pygame.quit()

if __name__ == "__main__":
    main()
