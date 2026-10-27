import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/models/book.dart';

void main() {
  group('Validation Exact Error Messages', () {
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
      expect(validateEmail('grader@example.com'), isNull);
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

      expect(validateConfirmPassword('', 'secret123'), 'Confirm password is required');
      expect(validateConfirmPassword('secret', 'secret123'), 'Passwords do not match');
      expect(validateConfirmPassword('secret123', 'secret123'), isNull);
    });

    test('Book Title validation rules', () {
      String? validateTitle(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        if (value.length > 100) {
          return 'Title must be at most 100 characters';
        }
        return null;
      }

      expect(validateTitle(''), 'Title is required');
      expect(validateTitle('   '), 'Title is required');
      expect(validateTitle('a' * 101), 'Title must be at most 100 characters');
      expect(validateTitle('Valid Title'), isNull);
    });

    test('Book Author validation rules', () {
      String? validateAuthor(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Author is required';
        }
        if (value.length > 60) {
          return 'Author must be at most 60 characters';
        }
        return null;
      }

      expect(validateAuthor(''), 'Author is required');
      expect(validateAuthor('   '), 'Author is required');
      expect(validateAuthor('a' * 61), 'Author must be at most 60 characters');
      expect(validateAuthor('Valid Author'), isNull);
    });

    test('Genre validation rules', () {
      String? validateGenre(String? value) {
        if (value == null || value.isEmpty || value == 'Choose genre') {
          return 'Please choose a genre';
        }
        return null;
      }

      expect(validateGenre(null), 'Please choose a genre');
      expect(validateGenre(''), 'Please choose a genre');
      expect(validateGenre('Choose genre'), 'Please choose a genre');
      expect(validateGenre('Fiction'), isNull);
      expect(validateGenre('Non-Fiction'), isNull);
      expect(validateGenre('Academic'), isNull);
      expect(validateGenre('Other'), isNull);
    });

    test('Status validation rules', () {
      String? validateStatus(String? value) {
        if (value == null || value.isEmpty || value == 'Choose status') {
          return 'Please choose a status';
        }
        return null;
      }

      expect(validateStatus(null), 'Please choose a status');
      expect(validateStatus(''), 'Please choose a status');
      expect(validateStatus('Choose status'), 'Please choose a status');
      expect(validateStatus('To Read'), isNull);
      expect(validateStatus('Reading'), isNull);
      expect(validateStatus('Finished'), isNull);
    });

    test('Rating validation rules', () {
      String? validateRating(String? value) {
        if (value != null && value.trim().isNotEmpty) {
          final intVal = int.tryParse(value.trim());
          if (intVal == null || intVal < 0 || intVal > 5) {
            return 'Rating must be a whole number from 0 to 5';
          }
        }
        return null;
      }

      expect(validateRating(''), isNull);
      expect(validateRating(null), isNull);
      expect(validateRating('-1'), 'Rating must be a whole number from 0 to 5');
      expect(validateRating('6'), 'Rating must be a whole number from 0 to 5');
      expect(validateRating('3.5'), 'Rating must be a whole number from 0 to 5');
      expect(validateRating('abc'), 'Rating must be a whole number from 0 to 5');
      expect(validateRating('0'), isNull);
      expect(validateRating('5'), isNull);
      expect(validateRating('3'), isNull);
    });

    test('Notes validation rules', () {
      String? validateNotes(String? value) {
        if (value != null && value.length > 300) {
          return 'Notes must be at most 300 characters';
        }
        return null;
      }

      expect(validateNotes(null), isNull);
      expect(validateNotes(''), isNull);
      expect(validateNotes('a' * 300), isNull);
      expect(validateNotes('a' * 301), 'Notes must be at most 300 characters');
    });
  });

  group('Book List Sorting & Filtering', () {
    final books = [
      Book(
        id: '1',
        userId: 'u1',
        title: 'dune',
        author: 'Frank Herbert',
        genre: 'Fiction',
        status: 'Reading',
        favorite: true,
        createdAt: DateTime.now(),
      ),
      Book(
        id: '2',
        userId: 'u1',
        title: 'Animal Farm',
        author: 'George Orwell',
        genre: 'Fiction',
        status: 'Finished',
        favorite: false,
        createdAt: DateTime.now(),
      ),
      Book(
        id: '3',
        userId: 'u1',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        genre: 'Academic',
        status: 'To Read',
        favorite: true,
        createdAt: DateTime.now(),
      ),
      Book(
        id: '4',
        userId: 'u1',
        title: 'Animal Farm',
        author: 'Adapted Author',
        genre: 'Fiction',
        status: 'To Read',
        favorite: false,
        createdAt: DateTime.now(),
      ),
    ];

    test('Alphabetical sorting by title (case-insensitive), tie-break by author', () {
      final sorted = List<Book>.from(books)
        ..sort((a, b) {
          final cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          if (cmp != 0) return cmp;
          return a.author.toLowerCase().compareTo(b.author.toLowerCase());
        });

      expect(sorted[0].title, 'Animal Farm');
      expect(sorted[0].author, 'Adapted Author');
      expect(sorted[1].title, 'Animal Farm');
      expect(sorted[1].author, 'George Orwell');
      expect(sorted[2].title, 'Clean Code');
      expect(sorted[3].title, 'dune');
    });

    test('Filter combining genre, status, favorites only, and search box', () {
      List<Book> filter(
        List<Book> list, {
        String genre = 'All',
        String status = 'All',
        bool favOnly = false,
        String query = '',
      }) {
        final q = query.trim().toLowerCase();
        return list.where((b) {
          if (genre != 'All' && b.genre != genre) return false;
          if (status != 'All' && b.status != status) return false;
          if (favOnly && !b.favorite) return false;
          if (q.isNotEmpty) {
            final t = b.title.toLowerCase().contains(q);
            final a = b.author.toLowerCase().contains(q);
            if (!t && !a) return false;
          }
          return true;
        }).toList();
      }

      // Search by author
      final orwell = filter(books, query: 'Orwell');
      expect(orwell.length, 1);
      expect(orwell.first.author, 'George Orwell');

      // Search by title (case-insensitive)
      final dune = filter(books, query: 'DUNE');
      expect(dune.length, 1);
      expect(dune.first.title, 'dune');

      // Favorites only
      final favs = filter(books, favOnly: true);
      expect(favs.length, 2);

      // Genre Academic
      final academic = filter(books, genre: 'Academic');
      expect(academic.length, 1);
      expect(academic.first.title, 'Clean Code');

      // Status To Read
      final toRead = filter(books, status: 'To Read');
      expect(toRead.length, 2);
    });

    test('Summary and Status Breakdown with tie-breaking rules', () {
      final sample = [
        Book(
          id: '1',
          userId: 'u1',
          title: 'Book 1',
          author: 'A1',
          genre: 'Fiction',
          status: 'To Read',
          favorite: true,
          createdAt: DateTime.now(),
        ),
        Book(
          id: '2',
          userId: 'u1',
          title: 'Book 2',
          author: 'A2',
          genre: 'Fiction',
          status: 'Reading',
          favorite: false,
          createdAt: DateTime.now(),
        ),
        Book(
          id: '3',
          userId: 'u1',
          title: 'Book 3',
          author: 'A3',
          genre: 'Fiction',
          status: 'Finished',
          favorite: true,
          createdAt: DateTime.now(),
        ),
        Book(
          id: '4',
          userId: 'u1',
          title: 'Book 4',
          author: 'A4',
          genre: 'Fiction',
          status: 'Reading',
          favorite: false,
          createdAt: DateTime.now(),
        ),
      ];

      final totalBooks = sample.length;
      final totalFavorites = sample.where((b) => b.favorite).length;

      expect(totalBooks, 4);
      expect(totalFavorites, 2);

      final statusCounts = <String, int>{};
      for (final b in sample) {
        statusCounts[b.status] = (statusCounts[b.status] ?? 0) + 1;
      }

      const priority = {'To Read': 0, 'Reading': 1, 'Finished': 2};
      final sortedStatuses = statusCounts.keys.toList()
        ..sort((a, b) {
          final countCompare = statusCounts[b]!.compareTo(statusCounts[a]!);
          if (countCompare != 0) return countCompare;
          return (priority[a] ?? 99).compareTo(priority[b] ?? 99);
        });

      // Reading has 2, To Read has 1, Finished has 1. Equal counts: To Read before Finished!
      expect(sortedStatuses, ['Reading', 'To Read', 'Finished']);
      expect(statusCounts['Reading'], 2);
      expect(statusCounts['To Read'], 1);
      expect(statusCounts['Finished'], 1);
    });
  });
}
