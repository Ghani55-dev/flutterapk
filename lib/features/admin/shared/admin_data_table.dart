import 'package:flutter/material.dart';

class AdminDataTableColumn {
  final String label;
  final bool isNumeric;
  final String? field; // Database field name for sorting

  AdminDataTableColumn({
    required this.label,
    this.isNumeric = false,
    this.field,
  });
}

class AdminDataTable extends StatelessWidget {
  final List<AdminDataTableColumn> columns;
  final int itemCount;
  final bool isLoading;
  final String? searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final Widget? filters;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;
  final DataRow Function(BuildContext context, int index) rowBuilder;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field, bool ascending)? onSort;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.itemCount,
    required this.rowBuilder,
    this.isLoading = false,
    this.searchQuery,
    this.onSearchChanged,
    this.searchHint = 'Search...',
    this.filters,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSearch = onSearchChanged != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar (Search + Filters)
          if (hasSearch || filters != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (hasSearch)
                    SizedBox(
                      width: 320,
                      height: 44,
                      child: TextField(
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 20),
                          hintText: searchHint,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                  if (filters != null) filters!,
                ],
              ),
            ),

          if (isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),

          // Scrollable Grid Content
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 64,
                  ),
                  child: DataTable(
                    sortColumnIndex: sortField != null
                        ? columns.indexWhere((c) => c.field == sortField)
                        : null,
                    sortAscending: sortAscending,
                    headingRowColor: WidgetStateProperty.all(
                      theme.brightness == Brightness.light
                          ? Colors.grey.shade50
                          : Colors.grey.shade900,
                    ),
                    columns: columns.map((col) {
                      final isSortable = col.field != null && onSort != null;
                      return DataColumn(
                        label: Text(
                          col.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        numeric: col.isNumeric,
                        onSort: isSortable
                            ? (colIndex, ascending) {
                                onSort!(col.field!, ascending);
                              }
                            : null,
                      );
                    }).toList(),
                    rows: List.generate(
                      itemCount,
                      (index) => rowBuilder(context, index),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Footer (Pagination)
          if (onPageChanged != null && totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Page $currentPage of $totalPages',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1 ? () => onPageChanged!(currentPage - 1) : null,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage < totalPages ? () => onPageChanged!(currentPage + 1) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
