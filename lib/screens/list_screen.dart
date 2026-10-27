import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import 'home_screen.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _authService = AuthService();
  final _bookService = BookService();

  Stream<List<Book>>? _booksStream;

  // Add Book Form Controllers & State
  final _addFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _ratingController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedGenre;
  String? _selectedStatus;
  bool _addSubmitted = false;
  bool _isAdding = false;
  int _formResetCount = 0;
  String? _addSuccessMessage;
  String? _addErrorMessage;

  // Filters & Search State
  String _selectedGenreFilter = 'All';
  String _selectedStatusFilter = 'All';
  bool _favoritesOnly = false;
  int _filterResetCount = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _booksStream = _bookService.getBooksStream(user.uid);
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
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

  Future<void> _handleAddBook(String userId) async {
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
      final rating = _ratingController.text.trim().isNotEmpty
          ? int.tryParse(_ratingController.text.trim())
          : null;

      final newBook = Book(
        id: '',
        userId: userId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _selectedGenre!,
        status: _selectedStatus!,
        rating: rating,
        favorite: false,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      await _bookService.addBook(newBook);

      if (!mounted) return;
      setState(() {
        _addSuccessMessage = 'Book added';
        _titleController.clear();
        _authorController.clear();
        _ratingController.clear();
        _notesController.clear();
        _selectedGenre = null;
        _selectedStatus = null;
        _addSubmitted = false;
        _addErrorMessage = null;
        _formResetCount++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book added'),
          backgroundColor: Colors.green,
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
      _selectedGenreFilter = 'All';
      _selectedStatusFilter = 'All';
      _favoritesOnly = false;
      _searchController.clear();
      _searchQuery = '';
      _filterResetCount++;
    });
  }

  List<Book> _applyFilters(List<Book> books) {
    return books.where((book) {
      // Genre filter
      if (_selectedGenreFilter != 'All' && book.genre != _selectedGenreFilter) {
        return false;
      }
      // Status filter
      if (_selectedStatusFilter != 'All' && book.status != _selectedStatusFilter) {
        return false;
      }
      // Favorites only filter
      if (_favoritesOnly && !book.favorite) {
        return false;
      }
      // Search box filter (title or author contains typed text, case-insensitive, spaces trimmed)
      if (_searchQuery.isNotEmpty) {
        final titleMatch = book.title.toLowerCase().contains(_searchQuery);
        final authorMatch = book.author.toLowerCase().contains(_searchQuery);
        if (!titleMatch && !authorMatch) {
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

    if (_booksStream == null && user != null) {
      _booksStream = _bookService.getBooksStream(user.uid);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            userEmail,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.white, size: 18),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: user == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<Book>>(
                stream: _booksStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allBooks = snapshot.data ?? [];
                  final filteredBooks = _applyFilters(allBooks);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAddBookCard(user.uid),
                        const SizedBox(height: 16),
                        _buildFilterSection(),
                        const SizedBox(height: 16),
                        _buildSummarySection(filteredBooks),
                        const SizedBox(height: 16),
                        _buildBookList(filteredBooks),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildAddBookCard(String userId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _addFormKey,
          autovalidateMode: _addSubmitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add a book',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('add_genre_$_formResetCount'),
                initialValue: _selectedGenre,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('add_status_$_formResetCount'),
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rating (optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value != null && value.length > 300) {
                    return 'Notes must be at most 300 characters';
                  }
                  return null;
                },
              ),
              if (_addSuccessMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    _addSuccessMessage!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (_addErrorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    _addErrorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isAdding ? null : () => _handleAddBook(userId),
                child: _isAdding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Add Book',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters & Search',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search title or author...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('filter_genre_$_filterResetCount'),
                    initialValue: _selectedGenreFilter,
                    decoration: const InputDecoration(
                      labelText: 'Genre',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All')),
                      ...Book.genres.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedGenreFilter = val ?? 'All';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('filter_status_$_filterResetCount'),
                    initialValue: _selectedStatusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All')),
                      ...Book.statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatusFilter = val ?? 'All';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('favorites only'),
                Switch(
                  value: _favoritesOnly,
                  activeThumbColor: Colors.deepPurple,
                  onChanged: (val) {
                    setState(() {
                      _favoritesOnly = val;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(List<Book> books) {
    final totalBooks = books.length;
    final totalFavorites = books.where((b) => b.favorite).length;

    // Breakdown with one row per status that appears
    final statusCounts = <String, int>{};
    for (final b in books) {
      statusCounts[b.status] = (statusCounts[b.status] ?? 0) + 1;
    }

    // Status with the most books first (equal counts: To Read, then Reading, then Finished)
    const priority = {'To Read': 0, 'Reading': 1, 'Finished': 2};
    final sortedStatuses = statusCounts.keys.toList()
      ..sort((a, b) {
        final countCompare = statusCounts[b]!.compareTo(statusCounts[a]!);
        if (countCompare != 0) return countCompare;
        return (priority[a] ?? 99).compareTo(priority[b] ?? 99);
      });

    return Card(
      elevation: 2,
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Books: $totalBooks',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Favorites: $totalFavorites',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (sortedStatuses.isNotEmpty) ...[
              const Divider(height: 20),
              ...sortedStatuses.map((status) {
                final count = statusCounts[status]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '$status: $count',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(List<Book> books) {
    if (books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'No books found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailScreen(book: book),
                ),
              );
            },
            title: Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Author: ${book.author}'),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book.genre,
                        style: TextStyle(fontSize: 11, color: Colors.deepPurple.shade900),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book.status,
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                book.favorite ? Icons.star : Icons.star_border,
                color: book.favorite ? Colors.amber : Colors.grey,
              ),
              onPressed: () async {
                await _bookService.toggleFavorite(book.id, book.favorite);
              },
            ),
          ),
        );
      },
    );
  }
}
