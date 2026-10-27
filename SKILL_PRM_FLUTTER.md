---
name: prm-flutter-firebase-pro
description: Expert guide and battle-tested patterns for building Flutter + Firebase mobile apps for PRM practical exams (FPT University) with Apple-inspired minimalist design, zero-bug real-time reactive UI, rock-solid security rules, and CI/CD automated release builds.
metadata:
  model: inherit
---

# PRM Practical Exam - Flutter & Firebase Pro Guide

A comprehensive, production-grade guide designed for developers and AI agents implementing Flutter + Firebase mobile applications for university practical exams (specifically **PRM393 / PRM392 / PRN** at FPT University) and production apps.

---

## 1. Top 7 Critical Pitfalls & Standard Solutions

### Pitfall 1: `StreamBuilder` Reloading/Flickering on `setState()`
* **The Bug:** Calling `getBooksStream()` (or any Firestore query) directly inside `build()`:
  ```dart
  // ❌ ANTI-PATTERN: Creates a new Stream on every build/setState!
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Book>>(
      stream: _bookService.getBooksStream(userId), // ⚠️ Resets connectionState to waiting!
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // ⚠️ Flickers spinner and destroys form state!
        }
        ...
      },
    );
  }
  ```
* **The Root Cause:** Whenever a dropdown changes, user types in search, or filters are clicked, `setState()` triggers `build()`. A brand new stream instance is created, `StreamBuilder` sees a new stream, resets to `ConnectionState.waiting`, displays a spinner, destroys all child widget state (including form validation and focused inputs), and appears to "reload the page" on every click.
* **The Solution:** Always initialize the Stream **once** in `initState()` (or memoize it):
  ```dart
  // ✅ CORRECT PATTERN:
  Stream<List<Book>>? _booksStream;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _booksStream = _bookService.getBooksStream(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Book>>(
      stream: _booksStream,
      builder: (context, snapshot) {
        // Only show spinner on initial load when NO data has arrived yet
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final books = snapshot.data ?? [];
        ...
      },
    );
  }
  ```

---

### Pitfall 2: Browser Password Autofill Popup on Web (Edge / Chrome)
* **The Bug:** Clicking into the password input causes the browser to pop up saved password suggestions or automatically fill credentials, obscuring form controls and triggering unwanted value changes.
* **The Solution:** Use `AutofillHints.oneTimeCode` combined with suggestions/autocorrect disabled:
  ```dart
  TextFormField(
    controller: _passwordController,
    obscureText: _obscurePassword,
    enableSuggestions: false,
    autocorrect: false,
    autofillHints: const [AutofillHints.oneTimeCode], // Tells browser not to suggest saved credentials
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Password is required';
      return null;
    },
  )
  ```

---

### Pitfall 3: Form Validation Lost Due to Dynamic Dropdown Keys
* **The Bug:** Binding dynamic keys like `key: ValueKey('genre_$_selectedGenre')` to `DropdownButtonFormField`:
  ```dart
  // ❌ ANTI-PATTERN: Changing the key destroys the widget on selection!
  DropdownButtonFormField(
    key: ValueKey('genre_$_selectedGenre'),
  )
  ```
  Every time the user selects an item, `_selectedGenre` changes, causing Flutter to destroy the existing widget and recreate a fresh one. This causes dropdowns to snap shut, lose focus, and wipe out validation error messages.
* **The Solution:** Use an independent **reset counter** that only increments when the form is explicitly cleared or reset:
  ```dart
  // ✅ CORRECT PATTERN:
  int _formResetCount = 0;

  void _clearForm() {
    _titleController.clear();
    _authorController.clear();
    _selectedGenre = null;
    _formResetCount++; // Only change key when form is reset
  }

  DropdownButtonFormField<String>(
    key: ValueKey('add_genre_$_formResetCount'),
    initialValue: _selectedGenre,
    items: [...],
    onChanged: (val) {
      setState(() => _selectedGenre = val); // Key remains stable during user selection!
    },
  )
  ```

---

### Pitfall 4: Firestore Security Rules & Unique Constraint Enforcement
* **Requirement:** "The database itself must refuse bad data, not only your forms... the same person cannot save the same title + author twice, even if letter case differs; two different people may save the same book."
* **The Architecture:**
  1. **Deterministic Document ID:**
     ```dart
     static String generateDocId(String userId, String title, String author) {
       final cleanTitle = title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
       final cleanAuthor = author.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
       return '${userId}_${cleanTitle}_$cleanAuthor';
     }
     ```
  2. **Client-side Pre-check:** Query existing documents for that user to throw a user-friendly duplicate error before writing.
  3. **Server-side Security Rules (`firestore.rules`):**
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         function isAuthenticated() {
           return request.auth != null;
         }

         function isValidBook(data) {
           let hasValidTitle = data.title is string &&
                               data.title.trim().size() > 0 &&
                               data.title.size() <= 100;

           let hasValidAuthor = data.author is string &&
                                data.author.trim().size() > 0 &&
                                data.author.size() <= 60;

           let hasValidGenre = data.genre in ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
           let hasValidStatus = data.status in ['To Read', 'Reading', 'Finished'];
           let hasValidRating = !('rating' in data) || data.rating == null || (data.rating is int && data.rating >= 0 && data.rating <= 5);
           let hasValidFavorite = !('favorite' in data) || data.favorite is bool;
           let hasValidNotes = !('notes' in data) || data.notes == null || (data.notes is string && data.notes.size() <= 300);

           return hasValidTitle && hasValidAuthor && hasValidGenre && hasValidStatus && hasValidRating && hasValidFavorite && hasValidNotes;
         }

         match /books/{bookId} {
           allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
           allow create: if isAuthenticated() &&
                            request.resource.data.userId == request.auth.uid &&
                            isValidBook(request.resource.data);
           allow update: if isAuthenticated() &&
                            resource.data.userId == request.auth.uid &&
                            request.resource.data.userId == request.auth.uid &&
                            isValidBook(request.resource.data);
           allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
         }
       }
     }
     ```

---

### Pitfall 5: Auth Navigation Flash & Back Button Vulnerability
* **Requirement:** "While the app is still checking whether someone is already logged in, nothing from this screen is shown (no flash of content, no wrong navigation). Pressing the phone’s Back button on the List screen must not return to the Login or Register form."
* **The Solution:**
  1. `AuthGate`:
     ```dart
     class AuthGate extends StatelessWidget {
       const AuthGate({super.key});

       @override
       Widget build(BuildContext context) {
         return StreamBuilder<User?>(
           stream: FirebaseAuth.instance.authStateChanges(),
           builder: (context, snapshot) {
             if (snapshot.connectionState == ConnectionState.waiting) {
               return const Scaffold(body: Center(child: CircularProgressIndicator()));
             }
             if (snapshot.hasData && snapshot.data != null) {
               return const ListScreen();
             }
             return const HomeScreen();
           },
         );
       }
     }
     ```
  2. `PopScope` on Protected Screen:
     ```dart
     PopScope(
       canPop: false, // Prevents Android back button from popping back to login/register
       child: Scaffold(...),
     )
     ```
  3. Push And Remove Until on Login/Logout:
     ```dart
     Navigator.of(context).pushAndRemoveUntil(
       MaterialPageRoute(builder: (_) => const ListScreen()),
       (route) => false,
     );
     ```

---

### Pitfall 6: Local Machine Missing Android SDK / Java
* **The Bug:** University lab computers or restricted Windows machines often lack the Android SDK or command-line tools to build release APKs (`flutter build apk --release` fails).
* **The Solution:** Leverage **GitHub Actions** cloud CI/CD. Push code with `.github/workflows/build.yml` to build the APK and attach it automatically to a GitHub Release:
  ```yaml
  name: Build and Release APK
  on:
    push:
      branches: [ main ]
      tags: [ 'v*' ]
  permissions:
    contents: write
  jobs:
    build:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-java@v4
          with:
            distribution: 'zulu'
            java-version: '17'
        - uses: subosito/flutter-action@v2
          with:
            channel: 'stable'
            cache: true
        - run: flutter pub get
        - run: flutter test
        - run: flutter build apk --release
        - uses: softprops/action-gh-release@v2
          with:
            tag_name: v1.0
            name: "Release v1.0"
            files: build/app/outputs/flutter-apk/app-release.apk
          env:
            GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  ```

---

### Pitfall 7: FPT Submission File Structure
* **Folder Name:** `<StudentCode>` (e.g. `QE190087`)
* **File 1:** `<StudentCode>.docx` — Real Word file with table:
  ```text
  Student Code: QE190087  Full Name: Pham Trung Tin  GitHub Repository URL: https://github.com/Phamtin147/PE-PRM-393  APK Download Link: https://github.com/Phamtin147/PE-PRM-393/releases/download/v1.0/app-release.apk  Firebase Project ID: pe-prn-393  Test account email: grader.qe190087@example.com  Test account password: Test1234!
  ```
  Followed by 16 captioned screenshot placeholders.
* **File 2:** `<StudentCode>.zip` — Source code:
  * `pubspec.yaml` **must be at the top level of the zip** (not inside a subfolder).
  * Includes: `pubspec.lock`, `lib/`, `android/`, `assets/`, `firestore.rules`, `firebase.json`.
  * **Strictly Excluded:** `build/`, `.dart_tool/`, `.git/`, `.gradle/`, and any private service-account keys.

---

## 2. Apple-Inspired Design System Tokens (Integrated)

For modern, premium look-and-feel aligned with Apple's human interface guidelines:

### Colors
```yaml
primary: "#0071E3"          # Action Blue: Primary CTAs, focus rings, active states
primary-focus: "#0071E3"    # 2px outline on interactive elements
link: "#0066CC"             # Link Blue: Light ground links, secondary outlines
link-on-dark: "#2997FF"     # Sky Link: Dark ground links
ink: "#1D1D1F"              # Deep near-black typography (never use pure #000 for body)
ink-secondary: "#424245"    # Secondary legible copy
muted: "#6E6E73"            # Subdued text, table headers, inactive tabs
surface: "#FFFFFF"          # Cards, dialogs, primary containers
surface-alt: "#F5F5F7"      # Parchment: App background, header/footer contrast
surface-dark: "#1D1D1F"     # Dark hero sections, dark mode surface
hairline: "#D2D2D7"         # Subtle 1px dividers
chip: "#DEDEE3"             # Tag/chip background
accent-orange: "#B64400"    # Subtle editorial badge/warning
```

### Typography Hierarchy (San Francisco Style)
| Token | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `hero-display` | 32–40px (Mobile) | 600 (Semibold) | 1.1 | App Title / Hero Banner |
| `title-md` | 20–24px | 600 (Semibold) | 1.2 | Screen Titles, Section Headers |
| `subtitle` | 16–18px | 500 (Medium) | 1.3 | Card Titles, Important Labels |
| `body` | 14–16px | 400 (Regular) | 1.45 | Body Text, Form Inputs, List Items |
| `caption` | 11–12px | 400 (Regular) | 1.35 | Badges, Timestamps, Helper text |

### Component Styling
* **Buttons:**
  * Height: 44px (touch friendly)
  * Border Radius: 980px (Pill shape)
  * Primary: Background `#0071E3`, text `#FFFFFF`, elevation 0 or subtle soft shadow.
  * Secondary / Outlined: 1px border `#0066CC`, text `#0066CC`.
* **Cards & Containers:**
  * Border Radius: 12px – 18px (`rounded.xl`)
  * Elevation: 1–2 (soft blur, subtle shadow `rgba(0,0,0,0.06)`).
  * Spacing: 16px inner padding.
* **Text Inputs:**
  * Border: `OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(0xFFD2D2D7)))`
  * Focus Border: `BorderSide(color: Color(0xFF0071E3), width: 2)`

---

## 3. Pre-Flight Verification Checklist
- [ ] `StreamBuilder` stream is initialized in `initState()`, never in `build()`.
- [ ] Passwords have `autofillHints: const [AutofillHints.oneTimeCode]`.
- [ ] Dropdowns use static/reset keys, not values in keys.
- [ ] `flutter analyze` returns 0 errors and 0 warnings.
- [ ] `flutter test` executes all validation logic and passes 100%.
- [ ] Security rules tested and deployed via Firebase CLI (`firebase deploy --only firestore:rules`).
- [ ] Release APK built and accessible via public link.
- [ ] Test account created on Firebase Auth and pre-populated with at least 3-5 documents.
- [ ] Zip package contains `pubspec.yaml` at root level without `.git`, `build/`, or secret keys.
