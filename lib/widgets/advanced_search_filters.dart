import 'package:flutter/material.dart';
import '../models/transaction.dart';

class SearchFilters {
  final String? searchQuery;
  final DateTimeRange? dateRange;
  final RangeValues? amountRange;
  final List<String> selectedCategories;
  final List<TransactionType> selectedTypes;
  final List<String> selectedTags;
  final String? sortBy; // 'date', 'amount', 'category'
  final bool sortAscending;

  SearchFilters({
    this.searchQuery,
    this.dateRange,
    this.amountRange,
    this.selectedCategories = const [],
    this.selectedTypes = const [],
    this.selectedTags = const [],
    this.sortBy = 'date',
    this.sortAscending = false,
  });

  SearchFilters copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    RangeValues? amountRange,
    List<String>? selectedCategories,
    List<TransactionType>? selectedTypes,
    List<String>? selectedTags,
    String? sortBy,
    bool? sortAscending,
  }) {
    return SearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange ?? this.dateRange,
      amountRange: amountRange ?? this.amountRange,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedTags: selectedTags ?? this.selectedTags,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get isEmpty =>
      (searchQuery?.isEmpty ?? true) &&
      dateRange == null &&
      amountRange == null &&
      selectedCategories.isEmpty &&
      selectedTypes.isEmpty &&
      selectedTags.isEmpty;

  // Clear all filters
  SearchFilters clear() => SearchFilters();
}

class AdvancedSearchFilters extends StatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onFiltersChanged;
  final List<String> availableCategories;
  final List<String> availableTags;
  final double minAmount;
  final double maxAmount;

  const AdvancedSearchFilters({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
    required this.availableCategories,
    required this.availableTags,
    this.minAmount = 0.0,
    this.maxAmount = 10000.0,
  });

  @override
  State<AdvancedSearchFilters> createState() => _AdvancedSearchFiltersState();
}

class _AdvancedSearchFiltersState extends State<AdvancedSearchFilters> {
  late SearchFilters _filters;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _searchController = TextEditingController(text: _filters.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilters(SearchFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
    widget.onFiltersChanged(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar with Filter Button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions, descriptions, categories...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _updateFilters(_filters.copyWith(searchQuery: ''));
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  _updateFilters(_filters.copyWith(searchQuery: value));
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _hasActiveFilters ? Colors.blue[600]! : null,
              ),
              onPressed: _showFilterDialog,
              tooltip: 'Advanced Filters',
            ),
            IconButton(
              icon: Icon(
                Icons.sort,
                color: _filters.sortBy != 'date' || _filters.sortAscending 
                    ? Colors.blue[600]! : null,
              ),
              onPressed: _showSortDialog,
              tooltip: 'Sort Options',
            ),
          ],
        ),

        // Active Filters Display
        if (_hasActiveFilters) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._buildActiveFilterChips(),
                // Clear all filters button
                ActionChip(
                  label: const Text('Clear All'),
                  onPressed: () {
                    _searchController.clear();
                    _updateFilters(SearchFilters());
                  },
                  backgroundColor: Colors.red[100],
                  labelStyle: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasActiveFilters =>
      _filters.dateRange != null ||
      _filters.amountRange != null ||
      _filters.selectedTags.isNotEmpty ||
      _filters.selectedCategories.isNotEmpty ||
      _filters.selectedTypes.isNotEmpty ||
      (_filters.searchQuery?.isNotEmpty ?? false) ||
      _filters.sortBy != 'date' ||
      _filters.sortAscending;

  List<Widget> _buildActiveFilterChips() {
    List<Widget> chips = [];

    // Date range chip
    if (_filters.dateRange != null) {
      chips.add(
        Chip(
          label: Text(
            '📅 ${_filters.dateRange!.start.toString().split(' ')[0]} - '
            '${_filters.dateRange!.end.toString().split(' ')[0]}',
          ),
          onDeleted: () {
            _updateFilters(_filters.copyWith(dateRange: null));
          },
          backgroundColor: Colors.blue[100],
        ),
      );
    }

    // Amount range chip
    if (_filters.amountRange != null) {
      chips.add(
        Chip(
          label: Text(
            '💰 \$${_filters.amountRange!.start.toStringAsFixed(0)} - '
            '\$${_filters.amountRange!.end.toStringAsFixed(0)}',
          ),
          onDeleted: () {
            _updateFilters(_filters.copyWith(amountRange: null));
          },
          backgroundColor: Colors.green[100],
        ),
      );
    }

    // Transaction type chips
    for (final type in _filters.selectedTypes) {
      chips.add(
        Chip(
          label: Text(
            type == TransactionType.income ? '📈 Income' : '📉 Expense',
          ),
          onDeleted: () {
            _updateFilters(
              _filters.copyWith(
                selectedTypes: List.from(_filters.selectedTypes)..remove(type),
              ),
            );
          },
          backgroundColor: type == TransactionType.income 
              ? Colors.blue[100] 
              : Colors.orange[100],
        ),
      );
    }

    // Category chips
    for (final category in _filters.selectedCategories) {
      chips.add(
        Chip(
          label: Text('🏷️ $category'),
          onDeleted: () {
            _updateFilters(
              _filters.copyWith(
                selectedCategories: List.from(_filters.selectedCategories)
                  ..remove(category),
              ),
            );
          },
          backgroundColor: Colors.purple[100],
        ),
      );
    }

    // Tag chips
    for (final tag in _filters.selectedTags) {
      chips.add(
        Chip(
          label: Text('#$tag'),
          onDeleted: () {
            _updateFilters(
              _filters.copyWith(
                selectedTags: List.from(_filters.selectedTags)..remove(tag),
              ),
            );
          },
          backgroundColor: Colors.orange[100],
        ),
      );
    }

    // Sort chip
    if (_filters.sortBy != 'date' || _filters.sortAscending) {
      String sortText = 'Sort: ${_filters.sortBy}';
      if (_filters.sortAscending) {
        sortText += ' ↑';
      } else {
        sortText += ' ↓';
      }
      
      chips.add(
        Chip(
          label: Text(sortText),
          onDeleted: () {
            _updateFilters(_filters.copyWith(
              sortBy: 'date',
              sortAscending: false,
            ));
          },
          backgroundColor: Colors.grey[200],
        ),
      );
    }

    return chips;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Filters'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range Filter
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: Text(_filters.dateRange == null
                      ? 'Select Date Range'
                      : '${_filters.dateRange!.start.toString().split(' ')[0]} - '
                        '${_filters.dateRange!.end.toString().split(' ')[0]}'),
                  trailing: _filters.dateRange != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _updateFilters(_filters.copyWith(dateRange: null));
                          },
                        )
                      : null,
                  onTap: () async {
                    final dateRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _filters.dateRange,
                    );
                    if (dateRange != null) {
                      _updateFilters(_filters.copyWith(dateRange: dateRange));
                    }
                  },
                ),

                const Divider(),

                // Amount Range Filter
                const Text('Amount Range', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RangeSlider(
                  values: _filters.amountRange ?? RangeValues(widget.minAmount, widget.maxAmount),
                  min: widget.minAmount,
                  max: widget.maxAmount,
                  divisions: 20,
                  labels: RangeLabels(
                    '\$${(_filters.amountRange?.start ?? widget.minAmount).toStringAsFixed(0)}',
                    '\$${(_filters.amountRange?.end ?? widget.maxAmount).toStringAsFixed(0)}',
                  ),
                  onChanged: (values) {
                    _updateFilters(_filters.copyWith(amountRange: values));
                  },
                ),

                const Divider(),

                // Transaction Type Filter
                const Text('Transaction Types', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TransactionType.values.map((type) {
                    final isSelected = _filters.selectedTypes.contains(type);
                    return FilterChip(
                      label: Text(type == TransactionType.income ? 'Income' : 'Expense'),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newTypes = List<TransactionType>.from(_filters.selectedTypes);
                        if (selected) {
                          newTypes.add(type);
                        } else {
                          newTypes.remove(type);
                        }
                        _updateFilters(_filters.copyWith(selectedTypes: newTypes));
                      },
                    );
                  }).toList(),
                ),

                const Divider(),

                // Category Filter
                if (widget.availableCategories.isNotEmpty) ...[
                  const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.availableCategories.map((category) {
                      final isSelected = _filters.selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newCategories = List<String>.from(_filters.selectedCategories);
                          if (selected) {
                            newCategories.add(category);
                          } else {
                            newCategories.remove(category);
                          }
                          _updateFilters(_filters.copyWith(selectedCategories: newCategories));
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(),
                ],

                // Tags Filter
                if (widget.availableTags.isNotEmpty) ...[
                  const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.availableTags.map((tag) {
                      final isSelected = _filters.selectedTags.contains(tag);
                      return FilterChip(
                        label: Text('#$tag'),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newTags = List<String>.from(_filters.selectedTags);
                          if (selected) {
                            newTags.add(tag);
                          } else {
                            newTags.remove(tag);
                          }
                          _updateFilters(_filters.copyWith(selectedTags: newTags));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _updateFilters(SearchFilters());
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date'),
              value: 'date',
              groupValue: _filters.sortBy,
              onChanged: (value) {
                _updateFilters(_filters.copyWith(sortBy: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('Amount'),
              value: 'amount',
              groupValue: _filters.sortBy,
              onChanged: (value) {
                _updateFilters(_filters.copyWith(sortBy: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('Category'),
              value: 'category',
              groupValue: _filters.sortBy,
              onChanged: (value) {
                _updateFilters(_filters.copyWith(sortBy: value));
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Ascending Order'),
              value: _filters.sortAscending,
              onChanged: (value) {
                _updateFilters(_filters.copyWith(sortAscending: value));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}