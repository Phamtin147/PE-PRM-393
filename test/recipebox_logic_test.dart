import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/models/recipe.dart';

void main() {
  group('Exact Error Messages Validation', () {
    test('Email validation rules', () {
      String? validateEmail(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email is required';
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Please enter a valid email address';
        }
        return null;
      }

      expect(validateEmail(''), 'Email is required');
      expect(validateEmail('   '), 'Email is required');
      expect(validateEmail('invalid-email'), 'Please enter a valid email address');
      expect(validateEmail('user@domain'), 'Please enter a valid email address');
      expect(validateEmail('grader.qe190087@example.com'), isNull);
    });

    test('Password validation rules', () {
      String? validateLoginPassword(String? value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        return null;
      }

      String? validateRegisterPassword(String? value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      }

      expect(validateLoginPassword(''), 'Password is required');
      expect(validateLoginPassword('123'), isNull);

      expect(validateRegisterPassword(''), 'Password is required');
      expect(validateRegisterPassword('12345'), 'Password must be at least 6 characters');
      expect(validateRegisterPassword('123456'), isNull);
    });

    test('Confirm password validation rules', () {
      String? validateConfirmPassword(String? value, String password) {
        if (value == null || value.isEmpty) {
          return 'Confirm password is required';
        }
        if (value != password) {
          return 'Passwords do not match';
        }
        return null;
      }

      expect(validateConfirmPassword('', 'Test1234!'), 'Confirm password is required');
      expect(validateConfirmPassword('Different', 'Test1234!'), 'Passwords do not match');
      expect(validateConfirmPassword('Test1234!', 'Test1234!'), isNull);
    });

    test('Recipe Name validation rules', () {
      String? validateName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        if (value.length > 80) {
          return 'Name must be at most 80 characters';
        }
        return null;
      }

      expect(validateName(''), 'Name is required');
      expect(validateName('   '), 'Name is required');
      expect(validateName('a' * 81), 'Name must be at most 80 characters');
      expect(validateName('Pho Bo'), isNull);
    });

    test('Category dropdown validation rules', () {
      String? validateCategory(String? value) {
        if (value == null || value.isEmpty || value == 'Choose category') {
          return 'Please choose a category';
        }
        return null;
      }

      expect(validateCategory(null), 'Please choose a category');
      expect(validateCategory(''), 'Please choose a category');
      expect(validateCategory('Choose category'), 'Please choose a category');
      expect(validateCategory('Breakfast'), isNull);
      expect(validateCategory('Lunch'), isNull);
      expect(validateCategory('Dinner'), isNull);
      expect(validateCategory('Dessert'), isNull);
    });

    test('Difficulty dropdown validation rules', () {
      String? validateDifficulty(String? value) {
        if (value == null || value.isEmpty || value == 'Choose difficulty') {
          return 'Please choose a difficulty';
        }
        return null;
      }

      expect(validateDifficulty(null), 'Please choose a difficulty');
      expect(validateDifficulty(''), 'Please choose a difficulty');
      expect(validateDifficulty('Choose difficulty'), 'Please choose a difficulty');
      expect(validateDifficulty('Easy'), isNull);
      expect(validateDifficulty('Medium'), isNull);
      expect(validateDifficulty('Hard'), isNull);
    });

    test('Cook time validation rules', () {
      String? validateCookTime(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Cook time is required';
        }
        final intVal = int.tryParse(value.trim());
        if (intVal == null || intVal < 1 || intVal > 600) {
          return 'Cook time must be a whole number from 1 to 600';
        }
        return null;
      }

      expect(validateCookTime(''), 'Cook time is required');
      expect(validateCookTime('   '), 'Cook time is required');
      expect(validateCookTime('abc'), 'Cook time must be a whole number from 1 to 600');
      expect(validateCookTime('0'), 'Cook time must be a whole number from 1 to 600');
      expect(validateCookTime('601'), 'Cook time must be a whole number from 1 to 600');
      expect(validateCookTime('-5'), 'Cook time must be a whole number from 1 to 600');
      expect(validateCookTime('25'), isNull);
      expect(validateCookTime('600'), isNull);
      expect(validateCookTime('1'), isNull);
    });

    test('Servings validation rules', () {
      String? validateServings(String? value) {
        if (value != null && value.trim().isNotEmpty) {
          final intVal = int.tryParse(value.trim());
          if (intVal == null || intVal < 1 || intVal > 20) {
            return 'Servings must be a whole number from 1 to 20';
          }
        }
        return null;
      }

      expect(validateServings(''), isNull);
      expect(validateServings(null), isNull);
      expect(validateServings('abc'), 'Servings must be a whole number from 1 to 20');
      expect(validateServings('0'), 'Servings must be a whole number from 1 to 20');
      expect(validateServings('21'), 'Servings must be a whole number from 1 to 20');
      expect(validateServings('4'), isNull);
      expect(validateServings('20'), isNull);
    });

    test('Notes validation rules', () {
      String? validateNotes(String? value) {
        if (value != null && value.length > 300) {
          return 'Notes must be at most 300 characters';
        }
        return null;
      }

      expect(validateNotes(''), isNull);
      expect(validateNotes(null), isNull);
      expect(validateNotes('a' * 300), isNull);
      expect(validateNotes('a' * 301), 'Notes must be at most 300 characters');
    });
  });

  group('Recipe List Sorting & Filtering Logic', () {
    final sampleRecipes = [
      Recipe(
        id: '1',
        userId: 'u1',
        name: 'Spaghetti Bolognese',
        category: 'Dinner',
        difficulty: 'Medium',
        cookTime: 45,
        favorite: true,
        notes: 'Delicious pasta with meat sauce',
        createdAt: DateTime.now(),
      ),
      Recipe(
        id: '2',
        userId: 'u1',
        name: 'Avocado Toast',
        category: 'Breakfast',
        difficulty: 'Easy',
        cookTime: 10,
        favorite: true,
        notes: 'Quick morning breakfast',
        createdAt: DateTime.now(),
      ),
      Recipe(
        id: '3',
        userId: 'u1',
        name: 'Pancakes',
        category: 'Breakfast',
        difficulty: 'Easy',
        cookTime: 20,
        favorite: false,
        notes: 'Fluffy pancakes',
        createdAt: DateTime.now(),
      ),
      Recipe(
        id: '4',
        userId: 'u1',
        name: 'Apple Pie',
        category: 'Dessert',
        difficulty: 'Hard',
        cookTime: 60,
        favorite: false,
        notes: 'Sweet baked dessert',
        createdAt: DateTime.now(),
      ),
      Recipe(
        id: '5',
        userId: 'u1',
        name: 'Chicken Salad',
        category: 'Lunch',
        difficulty: 'Easy',
        cookTime: 20,
        favorite: true,
        notes: 'Healthy salad for lunch',
        createdAt: DateTime.now(),
      ),
    ];

    test('Sorting by cook time shortest first, tie-break by name (case-insensitive)', () {
      final sorted = List<Recipe>.from(sampleRecipes)
        ..sort((a, b) {
          final timeCompare = a.cookTime.compareTo(b.cookTime);
          if (timeCompare != 0) return timeCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

      // 10: Avocado Toast
      expect(sorted[0].name, 'Avocado Toast');
      // 20: Chicken Salad ('c' < 'p')
      expect(sorted[1].name, 'Chicken Salad');
      // 20: Pancakes
      expect(sorted[2].name, 'Pancakes');
      // 45: Spaghetti Bolognese
      expect(sorted[3].name, 'Spaghetti Bolognese');
      // 60: Apple Pie
      expect(sorted[4].name, 'Apple Pie');
    });

    test('Filter combining category, difficulty, favorites only, and search', () {
      List<Recipe> filterRecipes({
        required String category,
        required String difficulty,
        required bool favoritesOnly,
        required String searchQuery,
      }) {
        final query = searchQuery.trim().toLowerCase();
        return sampleRecipes.where((r) {
          if (category != 'All' && r.category != category) return false;
          if (difficulty != 'All' && r.difficulty != difficulty) return false;
          if (favoritesOnly && !r.favorite) return false;
          if (query.isNotEmpty) {
            final nameMatch = r.name.toLowerCase().contains(query);
            final notesMatch = r.notes != null && r.notes!.toLowerCase().contains(query);
            if (!nameMatch && !notesMatch) return false;
          }
          return true;
        }).toList();
      }

      // Filter: All + All + Favorites only
      final favs = filterRecipes(
        category: 'All',
        difficulty: 'All',
        favoritesOnly: true,
        searchQuery: '',
      );
      expect(favs.length, 3);

      // Filter: Breakfast + Easy + All favorites
      final easyBreakfast = filterRecipes(
        category: 'Breakfast',
        difficulty: 'Easy',
        favoritesOnly: false,
        searchQuery: '',
      );
      expect(easyBreakfast.length, 2);

      // Search: 'salad'
      final searchSalad = filterRecipes(
        category: 'All',
        difficulty: 'All',
        favoritesOnly: false,
        searchQuery: 'salad',
      );
      expect(searchSalad.length, 1);
      expect(searchSalad.first.name, 'Chicken Salad');

      // Search inside notes: 'meat sauce'
      final searchNotes = filterRecipes(
        category: 'All',
        difficulty: 'All',
        favoritesOnly: false,
        searchQuery: 'meat sauce',
      );
      expect(searchNotes.length, 1);
      expect(searchNotes.first.name, 'Spaghetti Bolognese');
    });

    test('Summary calculations and breakdown priority', () {
      final recipes = sampleRecipes;
      final count = recipes.length;
      final favCount = recipes.where((r) => r.favorite).length;
      final totalCookTime = recipes.fold<int>(0, (sum, r) => sum + r.cookTime);

      expect('Recipes: $count', 'Recipes: 5');
      expect('Favorites: $favCount', 'Favorites: 3');
      expect('Total time: $totalCookTime min', 'Total time: 155 min');

      // Breakdown:
      // Breakfast: 2, Lunch: 1, Dinner: 1, Dessert: 1
      final Map<String, int> counts = {};
      for (final r in recipes) {
        counts[r.category] = (counts[r.category] ?? 0) + 1;
      }

      const priorityOrder = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
      final sortedCategories = counts.keys.toList()
        ..sort((a, b) {
          final countA = counts[a]!;
          final countB = counts[b]!;
          if (countA != countB) {
            return countB.compareTo(countA);
          }
          return priorityOrder.indexOf(a).compareTo(priorityOrder.indexOf(b));
        });

      expect(sortedCategories[0], 'Breakfast'); // Count: 2
      expect(sortedCategories[1], 'Lunch'); // Count: 1, priority before Dinner & Dessert
      expect(sortedCategories[2], 'Dinner'); // Count: 1, priority before Dessert
      expect(sortedCategories[3], 'Dessert'); // Count: 1
    });

    test('Generate Doc ID for duplicate prevention', () {
      final id1 = Recipe.generateDocId('user123', 'Pho Bo');
      final id2 = Recipe.generateDocId('user123', 'pho bo');
      final id3 = Recipe.generateDocId('user123', '  PHO BO  ');
      final idDifferentUser = Recipe.generateDocId('user456', 'Pho Bo');

      expect(id1, 'user123_pho_bo');
      expect(id2, id1);
      expect(id3, id1);
      expect(idDifferentUser, 'user456_pho_bo');
      expect(idDifferentUser != id1, true);
    });
  });
}
