import 'dart:io';

void main() {
  final docxDir = Directory(r'C:\Users\Tin\.gemini\antigravity\scratch\docx_builder');
  if (docxDir.existsSync()) {
    docxDir.deleteSync(recursive: true);
  }
  docxDir.createSync(recursive: true);

  final relsDir = Directory('${docxDir.path}/_rels')..createSync(recursive: true);
  final wordDir = Directory('${docxDir.path}/word')..createSync(recursive: true);

  File('${docxDir.path}/[Content_Types].xml').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''');

  File('${relsDir.path}/.rels').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''');

  final captions = [
    '1. Firebase console — Authentication: the Users list showing your test account.',
    '2. Firebase console — Firestore data: the books collection with at least 3 sample documents belonging to your test account.',
    '3. Firebase console — Security Rules: the Rules tab showing the rules you actually have published, not just saved in an editor.',
    '4. Register screen — validation: the form submitted empty, showing the error messages.',
    '5. Register screen — success: right after a successful sign-up, showing Registration successful.',
    '6. Login screen: the empty sign-in form.',
    '7. List screen — after login: showing the user\'s e-mail, the Logout button, and at least 3 books already in the list.',
    '8. Add Book form — validation: the form submitted empty or with bad input, showing the error messages.',
    '9. Add Book form — success: right after adding a book, showing Book added and the new book now in the list.',
    '10. Filters and search: the genre filter, the status filter, the favorites-only switch, and the search box each changing what is shown.',
    '11. Summary: the Books and Favorites counts and the status breakdown visible, with more than one status represented.',
    '12. Detail screen — view mode: one book\'s full details (title, author, genre, status, rating, notes).',
    '13. Detail screen — edit mode, validation: an edit submitted with bad input, showing the error messages.',
    '14. Detail screen — after Save: showing the edited values now saved.',
    '15. Favorite toggle and Delete: a before/after pair showing the star toggled, and a book deleted and gone from the list.',
    '16. Empty state: the List screen with the text No books found.',
  ];

  final buffer = StringBuffer();
  buffer.writeln('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="5000" w:type="pct"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="6" w:space="0" w:color="000000"/>
          <w:left w:val="single" w:sz="6" w:space="0" w:color="000000"/>
          <w:bottom w:val="single" w:sz="6" w:space="0" w:color="000000"/>
          <w:right w:val="single" w:sz="6" w:space="0" w:color="000000"/>
          <w:insideH w:val="single" w:sz="6" w:space="0" w:color="000000"/>
          <w:insideV w:val="single" w:sz="6" w:space="0" w:color="000000"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="5000" w:type="pct"/>
            <w:tcMar>
              <w:top w:w="160" w:type="dxa"/>
              <w:left w:w="160" w:type="dxa"/>
              <w:bottom w:w="160" w:type="dxa"/>
              <w:right w:w="160" w:type="dxa"/>
            </w:tcMar>
          </w:tcPr>
          <w:p>
            <w:r><w:t>Student Code: QE190087  Full Name: Pham Trung Tin  GitHub Repository URL: https://github.com/Phamtin147/PE-PRM-393  APK Download Link: https://github.com/Phamtin147/PE-PRM-393/releases/download/v1.0/app-release.apk  Firebase Project ID: pe-prn-393  Test account email: grader.qe190087@example.com  Test account password: Test1234!</w:t></w:r>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p><w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>PRM393 - Practical Exam Report &amp; Screenshots</w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>''');

  for (final caption in captions) {
    buffer.writeln('''    <w:p><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>$caption</w:t></w:r></w:p>
    <w:p><w:r><w:i/><w:t>[Paste screenshot here]</w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>''');
  }

  buffer.writeln('''  </w:body>
</w:document>''');

  File('${wordDir.path}/document.xml').writeAsStringSync(buffer.toString());
  print('Docx files generated in ${docxDir.path}');
}
