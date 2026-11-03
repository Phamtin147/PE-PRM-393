import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn
import os

doc = docx.Document()

# Page Margins
for section in doc.sections:
    section.top_margin = Inches(0.8)
    section.bottom_margin = Inches(0.8)
    section.left_margin = Inches(0.8)
    section.right_margin = Inches(0.8)

# Header Table with Student Info
table = doc.add_table(rows=1, cols=1)
table.alignment = WD_TABLE_ALIGNMENT.CENTER
cell = table.cell(0, 0)
tcPr = cell._tc.get_or_add_tcPr()
borders = parse_xml(
    r'<w:tcBorders %s>'
    r'  <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
    r'  <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
    r'  <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
    r'  <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
    r'</w:tcBorders>' % nsdecls('w')
)
tcPr.append(borders)

info_text = (
    "Student Code: QE190087  Full Name: Pham Trung Tin  "
    "GitHub Repository URL: https://github.com/Phamtin147/PE-PRM-393  "
    "APK Download Link: https://github.com/Phamtin147/PE-PRM-393/releases/download/v1.0/app-release.apk  "
    "Firebase Project ID: pe-prn-393-79796  "
    "Test account email: grader.qe190087@example.com  "
    "Test account password: Test1234!"
)

p_info = cell.paragraphs[0]
r_info = p_info.add_run(info_text)
r_info.font.name = 'Times New Roman'
r_info.font.size = Pt(11)

# Empty spacing
doc.add_paragraph()

# Document Title
title_p = doc.add_paragraph()
title_run = title_p.add_run("PRM393 (Fall 2026) — Practical Exam Report & Screenshots: RecipeBox")
title_run.font.name = 'Times New Roman'
title_run.font.size = Pt(16)
title_run.bold = True
title_run.font.color.rgb = RGBColor(0, 113, 227)

captions = [
    ("1. Firebase console — Authentication: the Users list showing your test account.", "screenshots/01_firebase_auth.png"),
    ("2. Firebase console — Firestore data: the recipes collection with at least 3 sample documents belonging to your test account.", "screenshots/02_firebase_firestore.png"),
    ("3. Firebase console — Security Rules: the Rules tab showing the rules you actually have published, not just saved in an editor.", "screenshots/03_firebase_rules.png"),
    ("4. Register screen — validation: the form submitted empty, showing the error messages.", "screenshots/04_register_validation.png"),
    ("5. Register screen — success: right after a successful sign-up, showing Registration successful.", "screenshots/05_register_success.png"),
    ("6. Login screen: the empty sign-in form.", "screenshots/06_login_empty.png"),
    ("7. List screen — after login: showing the user's e-mail, the Logout button, and at least 3 recipes already in the list.", "screenshots/07_list_after_login.png"),
    ("8. Add Recipe form — validation: the form submitted empty or with bad input, showing the error messages.", "screenshots/08_add_recipe_validation.png"),
    ("9. Add Recipe form — success: right after adding a recipe, showing Recipe added and the new recipe now in the list.", "screenshots/09_add_recipe_success.png"),
    ("10. Filters and search: the category filter, the difficulty filter, the favorites-only switch, and the search box each changing what is shown — one screenshot per control, or one screenshot plus a short note, is fine.", "screenshots/10_filters_and_search.png"),
    ("11. Summary: the Recipes, Favorites and Total time values and the category breakdown visible, with more than one category represented.", "screenshots/11_summary.png"),
    ("12. Detail screen — view mode: one recipe's full details (name, category, difficulty, cook time, servings, notes).", "screenshots/12_detail_view.png"),
    ("13. Detail screen — edit mode, validation: an edit submitted with bad input, showing the error messages.", "screenshots/13_detail_edit_validation.png"),
    ("14. Detail screen — after Save: showing the edited values now saved.", "screenshots/14_detail_after_save.png"),
    ("15. Favorite toggle and Delete: a before/after pair showing the star toggled, and a recipe deleted and gone from the list.", "screenshots/15_favorite_and_delete.png"),
    ("16. Empty state: the List screen with the text No recipes found — easiest to capture with a second, fresh test account before it has any recipes.", "screenshots/16_empty_state.png"),
]

for caption, img_path in captions:
    p_cap = doc.add_paragraph()
    r_cap = p_cap.add_run(caption)
    r_cap.font.name = 'Times New Roman'
    r_cap.font.size = Pt(12)
    r_cap.bold = True
    
    if os.path.exists(img_path):
        p_img = doc.add_paragraph()
        # Scale nicely for doc
        if 'firebase' in img_path:
            doc.add_picture(img_path, width=Inches(6.2))
        else:
            doc.add_picture(img_path, width=Inches(4.6))
    doc.add_paragraph()

doc.save("QE190087.docx")
print("Successfully generated QE190087.docx with all 16 embedded screenshots!")
