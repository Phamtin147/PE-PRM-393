import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class DetailScreen extends StatefulWidget {
  final Recipe recipe;

  const DetailScreen({super.key, required this.recipe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Recipe _recipe;
  final _recipeService = RecipeService();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Edit form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingsController;
  late TextEditingController _notesController;
  String? _selectedCategory;
  String? _selectedDifficulty;
  bool _editSubmitted = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _recipe.name);
    _cookTimeController = TextEditingController(text: _recipe.cookTime.toString());
    _servingsController = TextEditingController(
      text: _recipe.servings != null ? _recipe.servings.toString() : '',
    );
    _notesController = TextEditingController(text: _recipe.notes ?? '');
    _selectedCategory = _recipe.category;
    _selectedDifficulty = _recipe.difficulty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    try {
      await _recipeService.toggleFavorite(_recipe.id, _recipe.favorite);
      setState(() {
        _recipe = _recipe.copyWith(favorite: !_recipe.favorite);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: $e')),
      );
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _editSubmitted = true;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cookTime = int.parse(_cookTimeController.text.trim());
      final servings = _servingsController.text.trim().isNotEmpty
          ? int.tryParse(_servingsController.text.trim())
          : null;

      final updatedRecipe = _recipe.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        cookTime: cookTime,
        servings: servings,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      await _recipeService.updateRecipe(updatedRecipe);

      if (!mounted) return;
      setState(() {
        _recipe = updatedRecipe;
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe updated successfully'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e is FirebaseException && e.message != null) {
          _errorMessage = e.message;
        } else {
          _errorMessage = e.toString();
        }
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Recipe', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF0071E3), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _recipeService.deleteRecipe(_recipe.id);
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete recipe: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Recipe' : _recipe.name,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(
                _recipe.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: _recipe.favorite ? const Color(0xFFFF9500) : const Color(0xFF86868B),
                size: 26,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 22),
              onPressed: () {
                _initControllers();
                setState(() {
                  _isEditing = true;
                  _errorMessage = null;
                  _editSubmitted = false;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3B30), size: 22),
              onPressed: _handleDelete,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: _isEditing ? _buildEditForm() : _buildViewMode(),
      ),
    );
  }

  Widget _buildViewMode() {
    const primaryColor = Color(0xFF0071E3);
    const inkColor = Color(0xFF1D1D1F);
    const secondaryInk = Color(0xFF6E6E73);
    const hairline = Color(0xFFE5E5EA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hairline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _recipe.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: inkColor,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (_recipe.favorite)
                    const Icon(Icons.star_rounded, color: Color(0xFFFF9500), size: 28),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDetailBadge(
                    icon: Icons.timer_outlined,
                    label: '${_recipe.cookTime} min',
                    color: primaryColor,
                    bgColor: const Color(0xFFE8F2FD),
                  ),
                  _buildDetailBadge(
                    icon: Icons.restaurant_rounded,
                    label: _recipe.category,
                    color: inkColor,
                    bgColor: const Color(0xFFF5F5F7),
                  ),
                  _buildDetailBadge(
                    icon: Icons.speed_rounded,
                    label: _recipe.difficulty,
                    color: _getDifficultyColor(_recipe.difficulty),
                    bgColor: _getDifficultyColor(_recipe.difficulty).withValues(alpha: 0.1),
                  ),
                  if (_recipe.servings != null)
                    _buildDetailBadge(
                      icon: Icons.people_outline_rounded,
                      label: '${_recipe.servings} servings',
                      color: const Color(0xFF5856D6),
                      bgColor: const Color(0xFFF3F0FF),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: hairline, height: 1),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.notes_rounded, size: 18, color: secondaryInk),
                  const SizedBox(width: 8),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: inkColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEFEFF4)),
                ),
                child: Text(
                  (_recipe.notes != null && _recipe.notes!.trim().isNotEmpty)
                      ? _recipe.notes!
                      : 'No notes provided for this recipe.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: (_recipe.notes != null && _recipe.notes!.trim().isNotEmpty)
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFF86868B),
                    fontStyle: (_recipe.notes != null && _recipe.notes!.trim().isNotEmpty)
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    const inkColor = Color(0xFF1D1D1F);
    const hairline = Color(0xFFE5E5EA);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        autovalidateMode: _editSubmitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Recipe Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: inkColor,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isEditing = false;
                              _errorMessage = null;
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: hairline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
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
