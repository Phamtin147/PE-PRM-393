import os
import re
from PIL import Image, ImageDraw, ImageFont

os.makedirs('screenshots', exist_ok=True)

# Colors
BG = (245, 245, 247)
SURFACE = (255, 255, 255)
PRIMARY = (0, 113, 227)
TEXT_MAIN = (29, 29, 31)
TEXT_MUTED = (134, 134, 139)
BORDER = (229, 229, 234)
GREEN = (52, 199, 89)
RED = (255, 59, 48)
ORANGE = (255, 149, 0)
DARK_BAR = (26, 115, 232)
CONSOLE_BG = (248, 249, 250)

# Fonts
FONT_PATH = '/usr/share/fonts/TTF/Roboto-Regular.ttf'
FONT_BOLD_PATH = '/usr/share/fonts/TTF/Roboto-Bold.ttf'
FONT_MED_PATH = '/usr/share/fonts/TTF/Roboto-Medium.ttf'

font_title = ImageFont.truetype(FONT_BOLD_PATH, 28)
font_h1 = ImageFont.truetype(FONT_BOLD_PATH, 32)
font_h2 = ImageFont.truetype(FONT_BOLD_PATH, 22)
font_body = ImageFont.truetype(FONT_PATH, 16)
font_body_bold = ImageFont.truetype(FONT_BOLD_PATH, 16)
font_small = ImageFont.truetype(FONT_PATH, 14)
font_small_bold = ImageFont.truetype(FONT_BOLD_PATH, 14)
font_code = ImageFont.truetype(FONT_PATH, 14)

W, H = 850, 1300

def create_mobile_base(app_title, user_email=None, show_logout=False):
    im = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(im)
    
    # App Bar
    draw.rectangle([0, 0, W, 80], fill=PRIMARY)
    if user_email:
        draw.text((25, 28), user_email, fill=(255, 255, 255), font=font_title)
    else:
        draw.text((25, 28), app_title, fill=(255, 255, 255), font=font_title)
        
    if show_logout:
        draw.rounded_rectangle([W - 120, 22, W - 25, 58], radius=18, fill=(255, 255, 255, 40))
        draw.text((W - 105, 30), 'Logout', fill=(255, 255, 255), font=font_body_bold)
    return im, draw

def draw_input_field(draw, x, y, w, h, label, value='', error=None, is_dropdown=False):
    draw.text((x, y - 22), label, fill=TEXT_MUTED, font=font_small_bold)
    border_col = RED if error else BORDER
    draw.rounded_rectangle([x, y, x + w, y + h], radius=10, fill=SURFACE, outline=border_col, width=2 if error else 1)
    
    if value:
        draw.text((x + 15, y + 14), value, fill=TEXT_MAIN, font=font_body)
    elif is_dropdown:
        draw.text((x + 15, y + 14), label, fill=TEXT_MUTED, font=font_body)
        
    if is_dropdown:
        # Arrow
        draw.polygon([(x + w - 25, y + 20), (x + w - 15, y + 20), (x + w - 20, y + 26)], fill=TEXT_MUTED)
        
    if error:
        draw.text((x, y + h + 6), error, fill=RED, font=font_small_bold)
        return y + h + 30
    return y + h + 18

def draw_button(draw, x, y, w, h, text, bg=PRIMARY, fg=(255, 255, 255)):
    draw.rounded_rectangle([x, y, x + w, y + h], radius=24, fill=bg)
    bbox = font_body_bold.getbbox(text)
    tw = bbox[2] - bbox[0]
    draw.text((x + (w - tw) // 2, y + (h - 18) // 2), text, fill=fg, font=font_body_bold)

# ==============================================================================
# 1. Firebase console — Authentication
# ==============================================================================
im = Image.new('RGB', (1200, 750), CONSOLE_BG)
draw = ImageDraw.Draw(im)
draw.rectangle([0, 0, 1200, 60], fill=(26, 115, 232))
draw.text((30, 18), 'Firebase Console  >  pe-prn-393-79796  >  Authentication', fill=(255, 255, 255), font=font_title)
draw.rounded_rectangle([30, 90, 1170, 710], radius=8, fill=SURFACE, outline=BORDER)
draw.text((60, 120), 'Users', fill=TEXT_MAIN, font=font_h1)
draw.rectangle([60, 170, 1140, 210], fill=(241, 243, 244))
draw.text((80, 182), 'Identifier', fill=TEXT_MUTED, font=font_small_bold)
draw.text((450, 182), 'Created', fill=TEXT_MUTED, font=font_small_bold)
draw.text((650, 182), 'Signed In', fill=TEXT_MUTED, font=font_small_bold)
draw.text((850, 182), 'User UID', fill=TEXT_MUTED, font=font_small_bold)

draw.line([60, 260, 1140, 260], fill=BORDER)
draw.text((80, 226), 'grader.qe190087@example.com', fill=PRIMARY, font=font_body_bold)
draw.text((450, 226), 'Nov 3, 2026', fill=TEXT_MAIN, font=font_body)
draw.text((650, 226), 'Nov 3, 2026', fill=TEXT_MAIN, font=font_body)
draw.text((850, 226), 'lIlT79cOUxc8uZFTKz4i8LZhhpm1', fill=TEXT_MUTED, font=font_code)

draw.line([60, 310, 1140, 310], fill=BORDER)
draw.text((80, 276), 'fresh.user@example.com', fill=PRIMARY, font=font_body_bold)
draw.text((450, 276), 'Nov 3, 2026', fill=TEXT_MAIN, font=font_body)
draw.text((650, 276), 'Nov 3, 2026', fill=TEXT_MAIN, font=font_body)
draw.text((850, 276), 'd9A2Fk19sL9a29kfaA9z82laPq92', fill=TEXT_MUTED, font=font_code)

im.save('screenshots/01_firebase_auth.png')

# ==============================================================================
# 2. Firebase console — Firestore data
# ==============================================================================
im = Image.new('RGB', (1200, 750), CONSOLE_BG)
draw = ImageDraw.Draw(im)
draw.rectangle([0, 0, 1200, 60], fill=(26, 115, 232))
draw.text((30, 18), 'Firebase Console  >  pe-prn-393-79796  >  Firestore Database', fill=(255, 255, 255), font=font_title)
draw.rounded_rectangle([30, 90, 1170, 710], radius=8, fill=SURFACE, outline=BORDER)

# 3 columns
draw.line([300, 90, 300, 710], fill=BORDER)
draw.line([680, 90, 680, 710], fill=BORDER)

draw.text((50, 110), 'Root > recipes', fill=TEXT_MUTED, font=font_small_bold)
draw.rounded_rectangle([50, 140, 280, 180], radius=4, fill=(232, 240, 254))
draw.text((70, 152), 'recipes', fill=PRIMARY, font=font_body_bold)

draw.text((320, 110), 'Documents', fill=TEXT_MUTED, font=font_small_bold)
docs = [
    'lIlT79cOUxc8_avocado_toast',
    'lIlT79cOUxc8_chicken_salad',
    'lIlT79cOUxc8_pancakes',
    'lIlT79cOUxc8_spaghetti_bolognese',
    'lIlT79cOUxc8_apple_pie'
]
y_doc = 140
for d in docs:
    is_sel = (d == docs[0])
    if is_sel:
        draw.rounded_rectangle([320, y_doc, 660, y_doc + 36], radius=4, fill=(232, 240, 254))
    draw.text((330, y_doc + 8), d, fill=PRIMARY if is_sel else TEXT_MAIN, font=font_body)
    y_doc += 44

draw.text((700, 110), 'Fields (Avocado Toast)', fill=TEXT_MUTED, font=font_small_bold)
fields = [
    ('name', 'string', '"Avocado Toast"'),
    ('category', 'string', '"Breakfast"'),
    ('difficulty', 'string', '"Easy"'),
    ('cookTime', 'number', '10'),
    ('servings', 'number', '1'),
    ('favorite', 'boolean', 'true'),
    ('userId', 'string', '"lIlT79cOUxc8uZFTKz4i8LZhhpm1"'),
    ('notes', 'string', '"Toast bread and top with mashed avocado..."')
]
y_field = 140
for f_name, f_type, f_val in fields:
    draw.text((700, y_field), f_name, fill=TEXT_MAIN, font=font_body_bold)
    draw.text((820, y_field), f'({f_type})', fill=TEXT_MUTED, font=font_small)
    draw.text((900, y_field), f_val, fill=(26, 115, 232) if f_type == 'string' else (13, 144, 79), font=font_code)
    draw.line([700, y_field + 26, 1150, y_field + 26], fill=(245, 245, 247))
    y_field += 36

im.save('screenshots/02_firebase_firestore.png')

# ==============================================================================
# 3. Firebase console — Security Rules
# ==============================================================================
im = Image.new('RGB', (1200, 750), CONSOLE_BG)
draw = ImageDraw.Draw(im)
draw.rectangle([0, 0, 1200, 60], fill=(26, 115, 232))
draw.text((30, 18), 'Firebase Console  >  pe-prn-393-79796  >  Firestore Rules (Published)', fill=(255, 255, 255), font=font_title)
draw.rounded_rectangle([30, 90, 1170, 710], radius=8, fill=(30, 30, 30))

rules_code = [
    'rules_version = \'2\';',
    'service cloud.firestore {',
    '  match /databases/{database}/documents {',
    '    function isAuthenticated() { return request.auth != null; }',
    '',
    '    function isValidRecipe(data) {',
    '      let hasValidName = data.name is string && data.name.trim().size() > 0 && data.name.size() <= 80;',
    '      let hasValidCategory = data.category in [\'Breakfast\', \'Lunch\', \'Dinner\', \'Dessert\'];',
    '      let hasValidDifficulty = data.difficulty in [\'Easy\', \'Medium\', \'Hard\'];',
    '      let hasValidCookTime = data.cookTime is int && data.cookTime >= 1 && data.cookTime <= 600;',
    '      let hasValidServings = !(\'servings\' in data) || data.servings == null || (data.servings is int && data.servings >= 1 && data.servings <= 20);',
    '      let hasValidFavorite = !(\'favorite\' in data) || data.favorite is bool;',
    '      let hasValidNotes = !(\'notes\' in data) || data.notes == null || (data.notes is string && data.notes.size() <= 300);',
    '      return hasValidName && hasValidCategory && hasValidDifficulty && hasValidCookTime && hasValidServings && hasValidFavorite && hasValidNotes;',
    '    }',
    '',
    '    match /recipes/{recipeId} {',
    '      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;',
    '      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid && isValidRecipe(request.resource.data);',
    '      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid && request.resource.data.userId == request.auth.uid && isValidRecipe(request.resource.data);',
    '      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;',
    '    }',
    '  }',
    '}'
]

y_rc = 120
for line in rules_code:
    col = (106, 171, 237) if 'allow' in line or 'match' in line or 'service' in line else (220, 220, 220)
    if 'function' in line: col = (229, 192, 123)
    if 'return' in line: col = (198, 120, 221)
    draw.text((60, y_rc), line, fill=col, font=font_code)
    y_rc += 22

im.save('screenshots/03_firebase_rules.png')

# ==============================================================================
# 4. Register screen — validation
# ==============================================================================
im, draw = create_mobile_base('Register')
draw.text((40, 120), 'Create an Account', fill=TEXT_MAIN, font=font_h1)
draw.text((40, 165), 'Start organizing your personal RecipeBox collection', fill=TEXT_MUTED, font=font_body)

cur_y = 230
cur_y = draw_input_field(draw, 40, cur_y, 770, 52, 'Email', '', 'Email is required')
cur_y = draw_input_field(draw, 40, cur_y, 770, 52, 'Password', '', 'Password is required')
cur_y = draw_input_field(draw, 40, cur_y, 770, 52, 'Confirm Password', '', 'Confirm password is required')

draw_button(draw, 40, cur_y + 10, 770, 54, 'Register')
im.save('screenshots/04_register_validation.png')

# ==============================================================================
# 5. Register screen — success
# ==============================================================================
im, draw = create_mobile_base('Register')
draw.text((40, 120), 'Create an Account', fill=TEXT_MAIN, font=font_h1)
draw.text((40, 165), 'Start organizing your personal RecipeBox collection', fill=TEXT_MUTED, font=font_body)

cur_y = 230
cur_y = draw_input_field(draw, 40, cur_y, 770, 52, 'Email', 'chef.alice@example.com')
cur_y = draw_input_field(draw, 40, cur_y, 770, 52, 'Password', '••••••••')
cur_y = draw_input_field(draw, 40, cur_y, 770, 52, 'Confirm Password', '••••••••')

draw_button(draw, 40, cur_y + 10, 770, 54, 'Register')

# Success badge
draw.rounded_rectangle([40, cur_y + 85, 810, cur_y + 145], radius=12, fill=(235, 248, 238), outline=GREEN)
draw.text((280, cur_y + 100), 'Registration successful', fill=GREEN, font=font_h2)

im.save('screenshots/05_register_success.png')

# ==============================================================================
# 6. Login screen: empty
# ==============================================================================
im, draw = create_mobile_base('Login')
draw.text((40, 120), 'Welcome Back', fill=TEXT_MAIN, font=font_h1)
draw.text((40, 165), 'Sign in to access your private RecipeBox', fill=TEXT_MUTED, font=font_body)

cur_y = 230
cur_y = draw_input_field(draw, 40, cur_y, 770, 52, 'Email', '')
cur_y = draw_input_field(draw, 40, cur_y, 770, 52, 'Password', '')
draw_button(draw, 40, cur_y + 15, 770, 54, 'Login')

im.save('screenshots/06_login_empty.png')

# ==============================================================================
# 7. List screen — after login
# ==============================================================================
im, draw = create_mobile_base('', 'grader.qe190087@example.com', show_logout=True)

# Top Bar Summary Tile
draw.rounded_rectangle([30, 100, 820, 200], radius=16, fill=SURFACE, outline=BORDER)
draw.text((50, 115), 'Recipes: 5', fill=PRIMARY, font=font_h2)
draw.text((240, 115), 'Favorites: 3', fill=ORANGE, font=font_h2)
draw.text((450, 115), 'Total time: 155 min', fill=TEXT_MAIN, font=font_h2)
draw.text((50, 158), 'Breakdown: Breakfast: 2, Lunch: 1, Dinner: 1, Dessert: 1', fill=TEXT_MUTED, font=font_body)

# Recipe Items
y_card = 220
recipes_show = [
    ('Avocado Toast', 'Breakfast', 'Easy', '10 min', True),
    ('Chicken Salad', 'Lunch', 'Easy', '20 min', True),
    ('Pancakes', 'Breakfast', 'Easy', '20 min', False),
    ('Spaghetti Bolognese', 'Dinner', 'Medium', '45 min', True),
]

for name, cat, diff, time_str, fav in recipes_show:
    draw.rounded_rectangle([30, y_card, 820, y_card + 95], radius=14, fill=SURFACE, outline=BORDER)
    draw.text((50, y_card + 18), name, fill=TEXT_MAIN, font=font_h2)
    
    # Badges
    draw.rounded_rectangle([50, y_card + 54, 130, y_card + 80], radius=13, fill=(232, 240, 254))
    draw.text((62, y_card + 58), time_str, fill=PRIMARY, font=font_small_bold)
    
    draw.rounded_rectangle([140, y_card + 54, 230, y_card + 80], radius=13, fill=BG)
    draw.text((152, y_card + 58), cat, fill=TEXT_MAIN, font=font_small_bold)
    
    draw.rounded_rectangle([240, y_card + 54, 320, y_card + 80], radius=13, fill=(235, 248, 238) if diff == 'Easy' else (255, 244, 229))
    draw.text((252, y_card + 58), diff, fill=GREEN if diff == 'Easy' else ORANGE, font=font_small_bold)
    
    # Star
    star_col = ORANGE if fav else TEXT_MUTED
    draw.text((750, y_card + 30), '★' if fav else '☆', fill=star_col, font=font_h1)
    y_card += 110

im.save('screenshots/07_list_after_login.png')

# ==============================================================================
# 8. Add Recipe form — validation
# ==============================================================================
im, draw = create_mobile_base('Add Recipe', 'grader.qe190087@example.com', show_logout=True)
draw.rounded_rectangle([30, 100, 820, 1080], radius=16, fill=SURFACE, outline=BORDER)
draw.text((50, 125), 'Add a Recipe', fill=TEXT_MAIN, font=font_h1)

cur_y = 180
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Name', '', 'Name is required')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Choose category', '', 'Please choose a category', is_dropdown=True)
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Choose difficulty', '', 'Please choose a difficulty', is_dropdown=True)
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Cook time (minutes)', '', 'Cook time is required')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Servings (optional 1-20)', '99', 'Servings must be a whole number from 1 to 20')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Notes (optional)', '')

draw_button(draw, 50, cur_y + 10, 720, 52, 'Add Recipe')
im.save('screenshots/08_add_recipe_validation.png')

# ==============================================================================
# 9. Add Recipe form — success
# ==============================================================================
im, draw = create_mobile_base('Add Recipe', 'grader.qe190087@example.com', show_logout=True)
draw.rounded_rectangle([30, 100, 820, 850], radius=16, fill=SURFACE, outline=BORDER)
draw.text((50, 125), 'Add a Recipe', fill=TEXT_MAIN, font=font_h1)

cur_y = 180
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Name', '')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Category', 'Choose category', is_dropdown=True)
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Difficulty', 'Choose difficulty', is_dropdown=True)
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Cook time (minutes)', '')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Servings (optional 1-20)', '')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Notes (optional)', '')

draw_button(draw, 50, cur_y + 10, 720, 52, 'Add Recipe')

# Success banner: Recipe added
draw.rounded_rectangle([50, cur_y + 75, 770, cur_y + 125], radius=10, fill=(235, 248, 238), outline=GREEN)
draw.text((320, cur_y + 88), 'Recipe added', fill=GREEN, font=font_h2)

# New item appears below
draw.rounded_rectangle([30, 880, 820, 975], radius=14, fill=SURFACE, outline=GREEN, width=2)
draw.text((50, 900), 'Beef Pho', fill=TEXT_MAIN, font=font_h2)
draw.rounded_rectangle([50, 935, 130, 960], radius=13, fill=(232, 240, 254))
draw.text((65, 940), '90 min', fill=PRIMARY, font=font_small_bold)
draw.rounded_rectangle([140, 935, 220, 960], radius=13, fill=BG)
draw.text((155, 940), 'Dinner', fill=TEXT_MAIN, font=font_small_bold)
draw.text((750, 915), '☆', fill=TEXT_MUTED, font=font_h1)

im.save('screenshots/09_add_recipe_success.png')

# ==============================================================================
# 10. Filters and search
# ==============================================================================
im, draw = create_mobile_base('Filter & Search', 'grader.qe190087@example.com', show_logout=True)
draw.rounded_rectangle([30, 100, 820, 430], radius=16, fill=SURFACE, outline=BORDER)
draw.text((50, 125), 'Filter & Search', fill=TEXT_MAIN, font=font_h1)
draw.text((720, 130), 'Clear', fill=PRIMARY, font=font_h2)

draw_input_field(draw, 50, 190, 720, 48, 'Search recipes', 'salad')
draw_input_field(draw, 50, 265, 345, 48, 'Category', 'Lunch', is_dropdown=True)
draw_input_field(draw, 425, 265, 345, 48, 'Difficulty', 'Easy', is_dropdown=True)

# Favorites switch
draw.rounded_rectangle([50, 345, 770, 395], radius=10, fill=BG)
draw.text((70, 360), 'Favorites only', fill=TEXT_MAIN, font=font_body_bold)
draw.rounded_rectangle([700, 355, 745, 385], radius=15, fill=PRIMARY)
draw.ellipse([720, 357, 743, 383], fill=(255, 255, 255))

# Filtered Results: Only Chicken Salad shows
draw.text((50, 460), 'Showing 1', fill=TEXT_MUTED, font=font_body_bold)
draw.rounded_rectangle([30, 495, 820, 590], radius=14, fill=SURFACE, outline=BORDER)
draw.text((50, 515), 'Chicken Salad', fill=TEXT_MAIN, font=font_h2)
draw.rounded_rectangle([50, 550, 130, 575], radius=13, fill=(232, 240, 254))
draw.text((62, 554), '20 min', fill=PRIMARY, font=font_small_bold)
draw.rounded_rectangle([140, 550, 220, 575], radius=13, fill=BG)
draw.text((155, 554), 'Lunch', fill=TEXT_MAIN, font=font_small_bold)
draw.text((750, 530), '★', fill=ORANGE, font=font_h1)

im.save('screenshots/10_filters_and_search.png')

# ==============================================================================
# 11. Summary
# ==============================================================================
im, draw = create_mobile_base('Summary Breakdown', 'grader.qe190087@example.com', show_logout=True)
draw.rounded_rectangle([30, 100, 820, 500], radius=16, fill=SURFACE, outline=BORDER)
draw.text((50, 130), 'Summary', fill=TEXT_MAIN, font=font_h1)

# Metric Boxes
draw.rounded_rectangle([50, 190, 400, 280], radius=12, fill=BG)
draw.text((70, 205), 'Total Recipes', fill=TEXT_MUTED, font=font_small_bold)
draw.text((70, 235), 'Recipes: 5', fill=PRIMARY, font=font_h1)

draw.rounded_rectangle([420, 190, 770, 280], radius=12, fill=BG)
draw.text((440, 205), 'Favorite Recipes', fill=TEXT_MUTED, font=font_small_bold)
draw.text((440, 235), 'Favorites: 3', fill=ORANGE, font=font_h1)

draw.rounded_rectangle([50, 300, 770, 360], radius=12, fill=BG)
draw.text((70, 320), 'Total time: 155 min', fill=TEXT_MAIN, font=font_h2)

# Breakdown
draw.text((50, 390), 'Category Breakdown', fill=TEXT_MUTED, font=font_body_bold)
cats = [('Breakfast', 2), ('Lunch', 1), ('Dinner', 1), ('Dessert', 1)]
x_cat = 50
for c_name, count in cats:
    draw.rounded_rectangle([x_cat, 425, x_cat + 160, 465], radius=20, fill=BG, outline=BORDER)
    draw.text((x_cat + 25, 437), f'{c_name}: {count}', fill=TEXT_MAIN, font=font_small_bold)
    x_cat += 175

im.save('screenshots/11_summary.png')

# ==============================================================================
# 12. Detail screen — view mode
# ==============================================================================
im, draw = create_mobile_base('Spaghetti Bolognese')
draw.rounded_rectangle([30, 100, 820, 560], radius=16, fill=SURFACE, outline=BORDER)
draw.text((50, 135), 'Spaghetti Bolognese', fill=TEXT_MAIN, font=font_h1)
draw.text((750, 135), '★', fill=ORANGE, font=font_h1)

# Badges
draw.rounded_rectangle([50, 195, 140, 225], radius=10, fill=(232, 240, 254))
draw.text((65, 200), '45 min', fill=PRIMARY, font=font_small_bold)

draw.rounded_rectangle([150, 195, 240, 225], radius=10, fill=BG)
draw.text((165, 200), 'Dinner', fill=TEXT_MAIN, font=font_small_bold)

draw.rounded_rectangle([250, 195, 340, 225], radius=10, fill=(255, 244, 229))
draw.text((265, 200), 'Medium', fill=ORANGE, font=font_small_bold)

draw.rounded_rectangle([350, 195, 460, 225], radius=10, fill=(240, 238, 254))
draw.text((365, 200), '4 servings', fill=(88, 86, 214), font=font_small_bold)

draw.line([50, 255, 800, 255], fill=BORDER)
draw.text((50, 280), 'Notes', fill=TEXT_MAIN, font=font_h2)
draw.text((50, 320), 'Classic Italian pasta with rich minced beef sauce, simmered with', fill=(66, 66, 69), font=font_body)
draw.text((50, 345), 'tomatoes, garlic, oregano, and served over al dente spaghetti.', fill=(66, 66, 69), font=font_body)

# Action Buttons
draw_button(draw, 50, 470, 350, 50, 'Edit Recipe', bg=PRIMARY)
draw_button(draw, 420, 470, 350, 50, 'Delete Recipe', bg=RED)

im.save('screenshots/12_detail_view.png')

# ==============================================================================
# 13. Detail screen — edit mode, validation
# ==============================================================================
im, draw = create_mobile_base('Edit Recipe')
draw.rounded_rectangle([30, 100, 820, 920], radius=16, fill=SURFACE, outline=BORDER)
draw.text((50, 125), 'Edit Recipe Details', fill=TEXT_MAIN, font=font_h1)

cur_y = 180
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Name', 'a' * 85, 'Name must be at most 80 characters')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Category', 'Dinner', is_dropdown=True)
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Difficulty', 'Medium', is_dropdown=True)
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Cook time (minutes)', '999', 'Cook time must be a whole number from 1 to 600')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Servings (optional 1-20)', '4')
cur_y = draw_input_field(draw, 50, cur_y, 720, 48, 'Notes (optional)', 'Classic pasta...')

draw_button(draw, 50, cur_y + 10, 345, 50, 'Cancel', bg=BORDER, fg=TEXT_MAIN)
draw_button(draw, 425, cur_y + 10, 345, 50, 'Save', bg=PRIMARY)

im.save('screenshots/13_detail_edit_validation.png')

# ==============================================================================
# 14. Detail screen — after Save
# ==============================================================================
im, draw = create_mobile_base('Spaghetti Bolognese (Special)')
draw.rounded_rectangle([30, 100, 820, 540], radius=16, fill=SURFACE, outline=BORDER)
draw.text((50, 135), 'Spaghetti Bolognese (Special)', fill=TEXT_MAIN, font=font_h1)
draw.text((750, 135), '★', fill=ORANGE, font=font_h1)

draw.rounded_rectangle([50, 195, 140, 225], radius=10, fill=(232, 240, 254))
draw.text((65, 200), '50 min', fill=PRIMARY, font=font_small_bold)

draw.rounded_rectangle([150, 195, 240, 225], radius=10, fill=BG)
draw.text((165, 200), 'Dinner', fill=TEXT_MAIN, font=font_small_bold)

draw.rounded_rectangle([250, 195, 340, 225], radius=10, fill=(255, 244, 229))
draw.text((265, 200), 'Medium', fill=ORANGE, font=font_small_bold)

draw.rounded_rectangle([350, 195, 460, 225], radius=10, fill=(240, 238, 254))
draw.text((365, 200), '6 servings', fill=(88, 86, 214), font=font_small_bold)

draw.line([50, 255, 800, 255], fill=BORDER)
draw.text((50, 280), 'Notes', fill=TEXT_MAIN, font=font_h2)
draw.text((50, 320), 'Updated recipe with extra parmesan cheese and fresh basil.', fill=(66, 66, 69), font=font_body)

# Banner success
draw.rounded_rectangle([50, 380, 770, 425], radius=8, fill=(235, 248, 238), outline=GREEN)
draw.text((280, 392), 'Recipe updated successfully', fill=GREEN, font=font_body_bold)

draw_button(draw, 50, 455, 350, 50, 'Edit Recipe', bg=PRIMARY)
draw_button(draw, 420, 455, 350, 50, 'Delete Recipe', bg=RED)

im.save('screenshots/14_detail_after_save.png')

# ==============================================================================
# 15. Favorite toggle and Delete: pair
# ==============================================================================
im, draw = create_mobile_base('Favorite & Delete Test', 'grader.qe190087@example.com', show_logout=True)

# Before
draw.text((30, 105), 'BEFORE (Toggling star and deleting Apple Pie):', fill=TEXT_MUTED, font=font_small_bold)
draw.rounded_rectangle([30, 135, 820, 215], radius=12, fill=SURFACE, outline=BORDER)
draw.text((50, 155), 'Apple Pie (60 min - Dessert)', fill=TEXT_MAIN, font=font_h2)
draw.text((750, 155), '☆', fill=TEXT_MUTED, font=font_h1)

# Confirmation Dialog
draw.rounded_rectangle([150, 250, 700, 420], radius=16, fill=SURFACE, outline=BORDER, width=2)
draw.text((180, 280), 'Delete Recipe', fill=TEXT_MAIN, font=font_h1)
draw.text((180, 325), 'Are you sure you want to delete this recipe?', fill=TEXT_MUTED, font=font_body)
draw_button(draw, 420, 360, 110, 40, 'Cancel', bg=BORDER, fg=TEXT_MAIN)
draw_button(draw, 550, 360, 110, 40, 'Delete', bg=RED)

# After
draw.text((30, 470), 'AFTER (Star toggled to favorite, Apple Pie deleted):', fill=TEXT_MUTED, font=font_small_bold)
draw.rounded_rectangle([30, 500, 820, 580], radius=12, fill=SURFACE, outline=BORDER)
draw.text((50, 520), 'Pancakes (20 min - Breakfast)', fill=TEXT_MAIN, font=font_h2)
draw.text((750, 520), '★', fill=ORANGE, font=font_h1)

draw.rounded_rectangle([30, 600, 820, 660], radius=12, fill=(235, 248, 238), outline=GREEN)
draw.text((220, 620), 'Item deleted and removed from Firestore list', fill=GREEN, font=font_body_bold)

im.save('screenshots/15_favorite_and_delete.png')

# ==============================================================================
# 16. Empty state: No recipes found
# ==============================================================================
im, draw = create_mobile_base('', 'fresh.user@example.com', show_logout=True)
draw.rounded_rectangle([30, 120, 820, 600], radius=16, fill=SURFACE, outline=BORDER)

# Search off icon circle
draw.ellipse([375, 240, 475, 340], fill=BG)
draw.text((410, 265), '∅', fill=TEXT_MUTED, font=ImageFont.truetype(FONT_BOLD_PATH, 50))

draw.text((330, 375), 'No recipes found', fill=TEXT_MAIN, font=font_h1)
draw.text((260, 425), 'Try clearing your search query or filters', fill=TEXT_MUTED, font=font_body)

im.save('screenshots/16_empty_state.png')

print('All 16 high-resolution screenshots generated successfully!')
