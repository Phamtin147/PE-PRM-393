import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import 'home_screen.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _authService = AuthService();
  final _recipeService = RecipeService();

  Stream<List<Recipe>>? _recipesStream;

  // Add Recipe Form Controllers & State
  final _addFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDifficulty;
  bool _addSubmitted = false;
  bool _isAdding = false;
  int _formResetCount = 0;
  String? _addSuccessMessage;
  String? _addErrorMessage;

  // Filters & Search State
  String _selectedCategoryFilter = 'All';
  String _selectedDifficultyFilter = 'All';
  bool _favoritesOnly = false;
  int _filterResetCount = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _recipesStream = _recipeService.getRecipesStream(user.uid);
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _handleAddRecipe(String userId) async {
    setState(() {
      _addSubmitted = true;
      _addSuccessMessage = null;
      _addErrorMessage = null;
    });

    if (!_addFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final cookTime = int.parse(_cookTimeController.text.trim());
      final servings = _servingsController.text.trim().isNotEmpty
          ? int.tryParse(_servingsController.text.trim())
          : null;

      final newRecipe = Recipe(
        id: '',
        userId: userId,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        difficulty: _selectedDifficulty!,
        cookTime: cookTime,
        servings: servings,
        favorite: false,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      await _recipeService.addRecipe(newRecipe);

      if (!mounted) return;
      setState(() {
        _addSuccessMessage = 'Recipe added';
        _nameController.clear();
        _cookTimeController.clear();
        _servingsController.clear();
        _notesController.clear();
        _selectedCategory = null;
        _selectedDifficulty = null;
        _addSubmitted = false;
        _addErrorMessage = null;
        _formResetCount++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe added'),
          backgroundColor: Color(0xFF34C759),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is FirebaseException && e.message != null) {
          _addErrorMessage = e.message;
        } else {
          _addErrorMessage = e.toString();
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryFilter = 'All';
      _selectedDifficultyFilter = 'All';
      _favoritesOnly = false;
      _searchController.clear();
      _searchQuery = '';
      _filterResetCount++;
    });
  }

  List<Recipe> _applyFilters(List<Recipe> recipes) {
    return recipes.where((recipe) {
      // Category filter
      if (_selectedCategoryFilter != 'All' && recipe.category != _selectedCategoryFilter) {
        return false;
      }
      // Difficulty filter
      if (_selectedDifficultyFilter != 'All' && recipe.difficulty != _selectedDifficultyFilter) {
        return false;
      }
      // Favorites only filter
      if (_favoritesOnly && !recipe.favorite) {
        return false;
      }
      // Search box filter (name or notes contains typed text, case-insensitive, spaces trimmed)
      if (_searchQuery.isNotEmpty) {
        final nameMatch = recipe.name.toLowerCase().contains(_searchQuery);
        final notesMatch = recipe.notes != null &&
            recipe.notes!.toLowerCase().contains(_searchQuery);
        if (!nameMatch && !notesMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userEmail = user?.email ?? 'Unknown User';

    if (_recipesStream == null && user != null) {
      _recipesStream = _recipeService.getRecipesStream(user.uid);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            userEmail,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.white, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        body: user == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<Recipe>>(
                stream: _recipesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allRecipes = snapshot.data ?? [];
                  final filteredRecipes = _applyFilters(allRecipes);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // SECTION A: ADD RECIPE
                        _buildAddRecipeCard(user.uid),
                        const SizedBox(height: 28),

                        // SECTION C: FILTER & SEARCH
                        _buildFilterAndSearchCard(),
                        const SizedBox(height: 28),

                        // SECTION C: SUMMARY & BREAKDOWN
                        _buildSummaryCard(filteredRecipes),
                        const SizedBox(height: 28),

                        // SECTION B: THE LIST
                        _buildListHeader(filteredRecipes.length),
                        const SizedBox(height: 12),
                        if (filteredRecipes.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredRecipes.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final recipe = filteredRecipes[index];
                              return _buildRecipeItem(recipe);
                            },
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION A: ADD RECIPE FORM
  // ---------------------------------------------------------------------------
  Widget _buildAddRecipeCard(String userId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _addFormKey,
        autovalidateMode: _addSubmitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add a Recipe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.length > 80) {
                  return 'Name must be at most 80 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey('category_$_formResetCount'),
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Choose category'),
                ),
                ...Recipe.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedCategory = (val == null || val.isEmpty) ? null : val;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty || value == 'Choose category') {
                  return 'Please choose a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey('difficulty_$_formResetCount'),
              initialValue: _selectedDifficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Choose difficulty'),
                ),
                ...Recipe.difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedDifficulty = (val == null || val.isEmpty) ? null : val;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty || value == 'Choose difficulty') {
                  return 'Please choose a difficulty';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cookTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cook time (minutes)'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cook time is required';
                }
                final intVal = int.tryParse(value.trim());
                if (intVal == null || intVal < 1 || intVal > 600) {
                  return 'Cook time must be a whole number from 1 to 600';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _servingsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Servings (optional 1-20)'),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final intVal = int.tryParse(value.trim());
                  if (intVal == null || intVal < 1 || intVal > 20) {
                    return 'Servings must be a whole number from 1 to 20';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              validator: (value) {
                if (value != null && value.length > 300) {
                  return 'Notes must be at most 300 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isAdding ? null : () => _handleAddRecipe(userId),
              child: _isAdding
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Recipe'),
            ),
            if (_addSuccessMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF34C759).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF34C759), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _addSuccessMessage!,
                      style: const TextStyle(
                        color: Color(0xFF34C759),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_addErrorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _addErrorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION C: FILTERS & SEARCH
  // ---------------------------------------------------------------------------
  Widget _buildFilterAndSearchCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Search',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Color(0xFF0071E3),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search recipes',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF86868B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF86868B)),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('filter_category_$_filterResetCount'),
                  initialValue: _selectedCategoryFilter,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    'All',
                    ...Recipe.categories,
                  ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategoryFilter = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('filter_difficulty_$_filterResetCount'),
                  initialValue: _selectedDifficultyFilter,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: [
                    'All',
                    ...Recipe.difficulties,
                  ].map((dif) => DropdownMenuItem(value: dif, child: Text(dif))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDifficultyFilter = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFFF9500), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Favorites only',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _favoritesOnly,
                  activeTrackColor: const Color(0xFF0071E3),
                  onChanged: (val) {
                    setState(() => _favoritesOnly = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION C: SUMMARY & BREAKDOWN
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCard(List<Recipe> recipes) {
    final recipeCount = recipes.length;
    final favoriteCount = recipes.where((r) => r.favorite).length;
    final totalTime = recipes.fold<int>(0, (sum, r) => sum + r.cookTime);

    // Category breakdown counts
    final Map<String, int> categoryCounts = {};
    for (final recipe in recipes) {
      categoryCounts[recipe.category] = (categoryCounts[recipe.category] ?? 0) + 1;
    }

    const priorityOrder = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
    final sortedCategories = categoryCounts.keys.toList()
      ..sort((a, b) {
        final countA = categoryCounts[a]!;
        final countB = categoryCounts[b]!;
        if (countA != countB) {
          return countB.compareTo(countA); // Most recipes first
        }
        return priorityOrder.indexOf(a).compareTo(priorityOrder.indexOf(b));
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Recipes',
                  exactText: 'Recipes: $recipeCount',
                  icon: Icons.menu_book_outlined,
                  color: const Color(0xFF0071E3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Favorites',
                  exactText: 'Favorites: $favoriteCount',
                  icon: Icons.star,
                  color: const Color(0xFFFF9500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFF0071E3), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Total time: $totalTime min',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
          if (sortedCategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF86868B),
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedCategories.map((category) {
                final count = categoryCounts[category]!;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(980),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Text(
                    '$category: $count',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String exactText,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            exactText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION B: THE LIST
  // ---------------------------------------------------------------------------
  Widget _buildListHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recipes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: Color(0xFF1D1D1F),
          ),
        ),
        Text(
          'Showing $count',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.search_off_outlined,
              size: 28,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No recipes found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try clearing your search query or filters',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeItem(Recipe recipe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailScreen(recipe: recipe),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildBadge(
                          text: '${recipe.cookTime} min',
                          color: const Color(0xFF0071E3),
                          bgColor: const Color(0xFF0071E3).withValues(alpha: 0.1),
                        ),
                        _buildBadge(
                          text: recipe.category,
                          color: const Color(0xFF1D1D1F),
                          bgColor: const Color(0xFFF5F5F7),
                        ),
                        _buildBadge(
                          text: recipe.difficulty,
                          color: _getDifficultyColor(recipe.difficulty),
                          bgColor: _getDifficultyColor(recipe.difficulty).withValues(alpha: 0.1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  recipe.favorite ? Icons.star : Icons.star_border,
                  color: recipe.favorite ? const Color(0xFFFF9500) : const Color(0xFF86868B),
                  size: 26,
                ),
                onPressed: () {
                  _recipeService.toggleFavorite(recipe.id, recipe.favorite);
                },
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC7C7CC),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(980),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return const Color(0xFF34C759);
      case 'Medium':
        return const Color(0xFFFF9500);
      case 'Hard':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF86868B);
    }
  }
}
