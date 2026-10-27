import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _booksCollection => _firestore.collection('books');

  Stream<List<Book>> getBooksStream(String userId) {
    return _booksCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
      books.sort((a, b) {
        final titleCompare = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (titleCompare != 0) return titleCompare;
        return a.author.toLowerCase().compareTo(b.author.toLowerCase());
      });
      return books;
    });
  }

  Future<void> addBook(Book book) async {
    // Check for duplicate title + author for this user (case-insensitive)
    final existingSnapshot = await _booksCollection
        .where('userId', isEqualTo: book.userId)
        .get();

    final isDuplicate = existingSnapshot.docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final existingTitle = (data['title']?.toString() ?? '').trim().toLowerCase();
      final existingAuthor = (data['author']?.toString() ?? '').trim().toLowerCase();
      return existingTitle == book.title.trim().toLowerCase() &&
          existingAuthor == book.author.trim().toLowerCase();
    });

    if (isDuplicate) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'A book with this title and author already exists.',
      );
    }

    final docRef = _booksCollection.doc(
      Book.generateDocId(book.userId, book.title, book.author),
    );

    final newBook = book.copyWith(id: docRef.id);
    await docRef.set(newBook.toMap());
  }

  Future<void> updateBook(Book book) async {
    // Check if another book by this user already has the updated title + author
    final existingSnapshot = await _booksCollection
        .where('userId', isEqualTo: book.userId)
        .get();

    final isDuplicate = existingSnapshot.docs.any((doc) {
      if (doc.id == book.id) return false;
      final data = doc.data() as Map<String, dynamic>;
      final existingTitle = (data['title']?.toString() ?? '').trim().toLowerCase();
      final existingAuthor = (data['author']?.toString() ?? '').trim().toLowerCase();
      return existingTitle == book.title.trim().toLowerCase() &&
          existingAuthor == book.author.trim().toLowerCase();
    });

    if (isDuplicate) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'A book with this title and author already exists.',
      );
    }

    await _booksCollection.doc(book.id).update(book.toMap());
  }

  Future<void> toggleFavorite(String bookId, bool currentFavorite) async {
    await _booksCollection.doc(bookId).update({
      'favorite': !currentFavorite,
    });
  }

  Future<void> deleteBook(String bookId) async {
    await _booksCollection.doc(bookId).delete();
  }
}
