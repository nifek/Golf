import pygame
import json

# --- CONFIG ---
# NEW: Logical size (the "real" iPhone screen)
LOGICAL_WIDTH = 414 
LOGICAL_HEIGHT = 896

# NEW: Window scaling
SCALE_FACTOR = 0.8 # 80% of original size. Change this to fit your screen!
WINDOW_WIDTH = int(LOGICAL_WIDTH * SCALE_FACTOR)
WINDOW_HEIGHT = int(LOGICAL_HEIGHT * SCALE_FACTOR)
# ---

BG_COLOR = (20, 20, 40)
TERRAIN_COLOR = (150, 75, 0)
PLAYER_COLOR = (0, 0, 0)
HOLE_COLOR = (0, 200, 0)
POINT_COLOR = (255, 255, 0)
GRID_COLOR = (50, 50, 70) 
SNAP_CURSOR_COLOR = (255, 0, 0) 

# --- Grid config ---
DEFAULT_GRID_SIZE = 20
MIN_GRID_SIZE = 5
MAX_GRID_SIZE = 100

# --- DATA STORAGE ---
player_pos = None
hole_pos = None
terrain_polygons = [] 
current_polygon = []
snap_enabled = True  
grid_size = DEFAULT_GRID_SIZE

# --- COORDINATE CONVERSION (MODIFIED) ---
# Now uses LOGICAL dimensions to calculate the final JSON coords
def to_spritekit_coords(pos):
    pygame_x, pygame_y = pos
    # Use LOGICAL_WIDTH and LOGICAL_HEIGHT
    swift_x = pygame_x - (LOGICAL_WIDTH / 2)
    swift_y = (LOGICAL_HEIGHT / 2) - pygame_y 
    return {"x": swift_x, "y": swift_y}

# --- SAVE FUNCTION (Unchanged) ---
# This function doesn't care about the window, only the
# logical coordinates (player_pos, etc.) which are already correct.
def save_level(filename="MyLevel.json"):
    if not player_pos or not hole_pos:
        print("ERROR: You must place a Player and a Hole before saving.")
        return
    # ... (rest of save function is identical to before) ...
    print(f"Saving level to {filename}...")
    level_data = {
        "levelName": "My New Level",
        "playerStartPosition": to_spritekit_coords(player_pos),
        "hole": {
            "position": to_spritekit_coords(hole_pos),
            "radius": 20
        },
        "terrain": []
    }
    for poly in terrain_polygons:
        if not poly:
            continue
        anchor_pos_pygame = poly[0]
        anchor_pos_swift = to_spritekit_coords(anchor_pos_pygame)
        terrain_block = {
            "position": anchor_pos_swift,
            "vertices": []
        }
        for vertex in poly:
            rel_x = vertex[0] - anchor_pos_pygame[0]
            rel_y = vertex[1] - anchor_pos_pygame[1]
            swift_rel_vertex = {"x": rel_x, "y": -rel_y}
            terrain_block["vertices"].append(swift_rel_vertex)
        level_data["terrain"].append(terrain_block)
    with open(filename, 'w') as f:
        json.dump(level_data, f, indent=2)
    print("Level saved!")


# --- HELPER FUNCTIONS (MODIFIED) ---
# All calculations now use logical_pos and grid_size
def snap_to_grid(pos):
    x, y = pos
    snapped_x = round(x / grid_size) * grid_size
    snapped_y = round(y / grid_size) * grid_size
    return (snapped_x, snapped_y)

# Draw grid on the full-sized LOGICAL canvas
def draw_grid(surface):
    for x in range(0, LOGICAL_WIDTH, grid_size):
        pygame.draw.line(surface, GRID_COLOR, (x, 0), (x, LOGICAL_HEIGHT))
    for y in range(0, LOGICAL_HEIGHT, grid_size):
        pygame.draw.line(surface, GRID_COLOR, (0, y), (LOGICAL_WIDTH, y))

# --- PYGAME SETUP ---
pygame.init()
# NEW: Create the main window at the smaller, scaled size
screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
# NEW: Create the full-size "canvas" we will draw on
design_surface = pygame.Surface((LOGICAL_WIDTH, LOGICAL_HEIGHT))

pygame.display.set_caption("iPhone 16 Golf Editor (Scaled Preview)")
font = pygame.font.SysFont(None, 24)

# --- MAIN LOOP ---
running = True
mode = "PLAYER" 
print("--- iPhone Golf Level Editor (Scaled) ---")
print(f"Logical Size: {LOGICAL_WIDTH}x{LOGICAL_HEIGHT}")
print(f"Window Size: {WINDOW_WIDTH}x{WINDOW_HEIGHT} ({SCALE_FACTOR*100}%)")
print("Controls:")
print("  Modes: 'P' (Player) | 'H' (Hole) | 'T' (Terrain)")
print("  Grid : 'G' (Toggle Snap) | '+' (Grid Bigger) | '-' (Grid Smaller)")
print("  File : 'S' (Save) | 'C' (Clear) | 'R' (Reset ALL)")
print(f"Current Mode: {mode} | Grid Size: {grid_size} | Grid Snap: ON")

while running:
    # --- NEW: Mouse coordinate scaling ---
    # Get mouse position relative to the WINDOW
    window_mouse_pos = pygame.mouse.get_pos()
    # Scale it up to find the LOGICAL position on the design canvas
    logical_mouse_pos = (window_mouse_pos[0] / SCALE_FACTOR, 
                         window_mouse_pos[1] / SCALE_FACTOR)

    # --- Event Handling ---
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
            
        # --- KEY PRESSES (Unchanged) ---
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_s:
                save_level()
            if event.key == pygame.K_p:
                mode = "PLAYER"
                print(f"Mode: PLAYER | Grid: {grid_size} | Snap: {'ON' if snap_enabled else 'OFF'}")
            if event.key == pygame.K_h:
                mode = "HOLE"
                print(f"Mode: HOLE | Grid: {grid_size} | Snap: {'ON'if snap_enabled else 'OFF'}")
            if event.key == pygame.K_t:
                mode = "TERRAIN"
                print(f"Mode: TERRAIN | Grid: {grid_size} | Snap: {'ON'if snap_enabled else 'OFF'}")
            if event.key == pygame.K_c:
                current_polygon = []
                print("Cleared current polygon.")
            if event.key == pygame.K_r:
                player_pos = None
                hole_pos = None
                terrain_polygons = []
                current_polygon = []
                grid_size = DEFAULT_GRID_SIZE
                print("--- RESET ALL ---")
            if event.key == pygame.K_g:
                snap_enabled = not snap_enabled
                print(f"Grid Snap: {'ON' if snap_enabled else 'OFF'}")
            if event.key == pygame.K_MINUS:
                grid_size = max(MIN_GRID_SIZE, grid_size - 5)
                print(f"Grid size set to {grid_size}")
            if event.key == pygame.K_EQUALS or event.key == pygame.K_PLUS:
                grid_size = min(MAX_GRID_SIZE, grid_size + 5)
                print(f"Grid size set to {grid_size}")

        # --- MOUSE CLICKS (MODIFIED) ---
        if event.type == pygame.MOUSEBUTTONDOWN:
            # Use the calculated LOGICAL position for all actions
            pos_to_use = logical_mouse_pos
            
            if snap_enabled:
                pos_to_use = snap_to_grid(logical_mouse_pos)
            
            if mode == "PLAYER":
                player_pos = pos_to_use
                print(f"Player start set at {pos_to_use}")
            
            elif mode == "HOLE":
                hole_pos = pos_to_use
                print(f"Hole set at {pos_to_use}")
            
            elif mode == "TERRAIN":
                if event.button == 1:
                    current_polygon.append(pos_to_use)
                    print(f"Added vertex {pos_to_use}")
                elif event.button == 3:
                    if len(current_polygon) >= 3:
                        terrain_polygons.append(current_polygon)
                        print(f"Finished polygon with {len(current_polygon)} vertices.")
                        current_polygon = []
                    else:
                        print("You need at least 3 vertices to make a polygon.")

    # --- Drawing (MODIFIED) ---
    # First, draw EVERYTHING to the full-size design_surface
    
    design_surface.fill(BG_COLOR)
    
    draw_grid(design_surface) # Draw grid on the surface
    
    # Draw instructions (these are also on the design_surface)
    snap_text = "ON" if snap_enabled else "OFF"
    text = font.render(f"Grid: {grid_size} (+/-) | Snap (G): {snap_text} | Mode: {mode} (P,H,T)", True, (255, 255, 255))
    text_rect = text.get_rect(center=(LOGICAL_WIDTH // 2, 20)) 
    design_surface.blit(text, text_rect)
    text2 = font.render("Save (S) | Clear Shape (C) | Reset All (R)", True, (255, 255, 255))
    text2_rect = text2.get_rect(center=(LOGICAL_WIDTH // 2, 45))
    design_surface.blit(text2, text2_rect)

    # All items are drawn using their LOGICAL coordinates
    if player_pos:
        pygame.draw.circle(design_surface, PLAYER_COLOR, player_pos, 16) 
    if hole_pos:
        pygame.draw.circle(design_surface, HOLE_COLOR, hole_pos, 20) 
    for poly in terrain_polygons:
        pygame.draw.polygon(design_surface, TERRAIN_COLOR, poly)
    if current_polygon:
        for point in current_polygon:
            pygame.draw.circle(design_surface, POINT_COLOR, point, 4)
        if len(current_polygon) > 1:
            pygame.draw.lines(design_surface, POINT_COLOR, False, current_polygon)
    if snap_enabled:
        snapped_pos = snap_to_grid(logical_mouse_pos)
        pygame.draw.circle(design_surface, SNAP_CURSOR_COLOR, snapped_pos, 8, 1) 

    # --- NEW: Final Scaling Step ---
    # Now that drawing is done, scale the whole canvas down to fit the window
    scaled_surface = pygame.transform.scale(design_surface, (WINDOW_WIDTH, WINDOW_HEIGHT))
    
    # Clear the main screen and blit the scaled-down surface
    screen.fill(BG_COLOR)
    screen.blit(scaled_surface, (0, 0))

    pygame.display.flip()

pygame.quit()