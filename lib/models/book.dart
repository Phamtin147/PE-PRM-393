import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String? notes;
  final DateTime createdAt;

  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.favorite = false,
    this.notes,
    required this.createdAt,
  });

  static const List<String> genres = [
    'Fiction',
    'Non-Fiction',
    'Academic',
    'Other',
  ];

  static const List<String> statuses = [
    'To Read',
    'Reading',
    'Finished',
  ];

  static String generateDocId(String userId, String title, String author) {
    final cleanTitle = title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final cleanAuthor = author.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return '${userId}_${cleanTitle}_$cleanAuthor';
  }

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime createdDate;
    if (data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is int) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int);
    } else {
      createdDate = DateTime.now();
    }

    return Book(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
      genre: data['genre']?.toString() ?? 'Other',
      status: data['status']?.toString() ?? 'To Read',
      rating: data['rating'] != null ? int.tryParse(data['rating'].toString()) : null,
      favorite: data['favorite'] == true,
      notes: data['notes']?.toString(),
      createdAt: createdDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'author': author,
      'genre': genre,
      'status': status,
      'rating': rating,
      'favorite': favorite,
      'notes': notes ?? '',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Book copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    String? genre,
    String? status,
    int? rating,
    bool? favorite,
    String? notes,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      favorite: favorite ?? this.favorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
