import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String difficulty;
  final int cookTime;
  final int? servings;
  final bool favorite;
  final String? notes;
  final DateTime createdAt;

  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    this.servings,
    this.favorite = false,
    this.notes,
    required this.createdAt,
  });

  static const List<String> categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
  ];

  static const List<String> difficulties = [
    'Easy',
    'Medium',
    'Hard',
  ];

  static String generateDocId(String userId, String name) {
    final cleanName = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return '${userId}_$cleanName';
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime createdDate;
    if (data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is int) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int);
    } else {
      createdDate = DateTime.now();
    }

    return Recipe(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Breakfast',
      difficulty: data['difficulty']?.toString() ?? 'Easy',
      cookTime: data['cookTime'] is int
          ? data['cookTime'] as int
          : int.tryParse(data['cookTime']?.toString() ?? '0') ?? 0,
      servings: data['servings'] != null
          ? int.tryParse(data['servings'].toString())
          : null,
      favorite: data['favorite'] == true,
      notes: data['notes']?.toString(),
      createdAt: createdDate,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'difficulty': difficulty,
      'cookTime': cookTime,
      'favorite': favorite,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (servings != null) {
      map['servings'] = servings;
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      map['notes'] = notes!.trim();
    }

    return map;
  }

  Recipe copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? difficulty,
    int? cookTime,
    int? servings,
    bool? favorite,
    String? notes,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      favorite: favorite ?? this.favorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
