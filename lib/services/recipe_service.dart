import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _recipesCollection => _firestore.collection('recipes');

  Stream<List<Recipe>> getRecipesStream(String userId) {
    return _recipesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final recipes = snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
      recipes.sort((a, b) {
        final timeCompare = a.cookTime.compareTo(b.cookTime);
        if (timeCompare != 0) return timeCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return recipes;
    });
  }

  Future<void> addRecipe(Recipe recipe) async {
    // Check for duplicate name for this user (case-insensitive)
    final existingSnapshot = await _recipesCollection
        .where('userId', isEqualTo: recipe.userId)
        .get();

    final isDuplicate = existingSnapshot.docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final existingName = (data['name']?.toString() ?? '').trim().toLowerCase();
      return existingName == recipe.name.trim().toLowerCase();
    });

    if (isDuplicate) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'A recipe with this name already exists.',
      );
    }

    final docRef = _recipesCollection.doc(
      Recipe.generateDocId(recipe.userId, recipe.name),
    );

    final newRecipe = recipe.copyWith(id: docRef.id);
    await docRef.set(newRecipe.toMap());
  }

  Future<void> updateRecipe(Recipe recipe) async {
    // Check if another recipe by this user already has the updated name
    final existingSnapshot = await _recipesCollection
        .where('userId', isEqualTo: recipe.userId)
        .get();

    final isDuplicate = existingSnapshot.docs.any((doc) {
      if (doc.id == recipe.id) return false;
      final data = doc.data() as Map<String, dynamic>;
      final existingName = (data['name']?.toString() ?? '').trim().toLowerCase();
      return existingName == recipe.name.trim().toLowerCase();
    });

    if (isDuplicate) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'A recipe with this name already exists.',
      );
    }

    await _recipesCollection.doc(recipe.id).update(recipe.toMap());
  }

  Future<void> toggleFavorite(String recipeId, bool currentFavorite) async {
    await _recipesCollection.doc(recipeId).update({
      'favorite': !currentFavorite,
    });
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _recipesCollection.doc(recipeId).delete();
  }
}
