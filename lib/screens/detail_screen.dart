import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class DetailScreen extends StatefulWidget {
  final Book book;

  const DetailScreen({super.key, required this.book});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Book _book;
  final _bookService = BookService();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Edit form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _ratingController;
  late TextEditingController _notesController;
  String? _selectedGenre;
  String? _selectedStatus;
  bool _editSubmitted = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _initControllers();
  }

  void _initControllers() {
    _titleController = TextEditingController(text: _book.title);
    _authorController = TextEditingController(text: _book.author);
    _ratingController = TextEditingController(
      text: _book.rating != null ? _book.rating.toString() : '',
    );
    _notesController = TextEditingController(text: _book.notes ?? '');
    _selectedGenre = _book.genre;
    _selectedStatus = _book.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    try {
      await _bookService.toggleFavorite(_book.id, _book.favorite);
      setState(() {
        _book = _book.copyWith(favorite: !_book.favorite);
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
      final rating = _ratingController.text.trim().isNotEmpty
          ? int.tryParse(_ratingController.text.trim())
          : null;

      final updatedBook = _book.copyWith(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _selectedGenre,
        status: _selectedStatus,
        rating: rating,
        notes: _notesController.text.trim(),
      );

      await _bookService.updateBook(updatedBook);

      if (!mounted) return;
      setState(() {
        _book = updatedBook;
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book updated successfully')),
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
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookService.deleteBook(_book.id);
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete book: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Book' : _book.title),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(
                _book.favorite ? Icons.star : Icons.star_border,
                color: _book.favorite ? Colors.amber : Colors.white,
              ),
              onPressed: _toggleFavorite,
              tooltip: 'Favorite',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _initControllers();
                setState(() {
                  _isEditing = true;
                  _editSubmitted = false;
                  _errorMessage = null;
                });
              },
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _handleDelete,
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: _isEditing ? _buildEditMode() : _buildViewMode(),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _book.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _book.favorite ? Icons.star : Icons.star_border,
                        color: _book.favorite ? Colors.amber : Colors.grey,
                        size: 32,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${_book.author}',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Divider(height: 32),
                _buildDetailRow(Icons.category, 'Genre', _book.genre),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.bookmark, 'Status', _book.status),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.star_rate,
                  'Rating',
                  _book.rating != null ? '${_book.rating} / 5' : 'No rating',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.notes,
                  'Notes',
                  (_book.notes != null && _book.notes!.isNotEmpty)
                      ? _book.notes!
                      : 'No notes provided',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      autovalidateMode: _editSubmitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              if (value.length > 100) {
                return 'Title must be at most 100 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Author',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Author is required';
              }
              if (value.length > 60) {
                return 'Author must be at most 60 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedGenre,
            decoration: const InputDecoration(
              labelText: 'Genre',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Choose genre'),
              ),
              ...Book.genres.map((g) => DropdownMenuItem(value: g, child: Text(g))),
            ],
            onChanged: (val) {
              setState(() {
                _selectedGenre = (val == null || val.isEmpty) ? null : val;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty || value == 'Choose genre') {
                return 'Please choose a genre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Choose status'),
              ),
              ...Book.statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: (val) {
              setState(() {
                _selectedStatus = (val == null || val.isEmpty) ? null : val;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty || value == 'Choose status') {
                return 'Please choose a status';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ratingController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Rating (optional 0-5)',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final intVal = int.tryParse(value.trim());
                if (intVal == null || intVal < 0 || intVal > 5) {
                  return 'Rating must be a whole number from 0 to 5';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
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
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _handleSave,
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
    );
  }
}
