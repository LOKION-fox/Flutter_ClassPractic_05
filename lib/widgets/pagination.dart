import 'package:flutter/material.dart';

class Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final int size;

  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const Pagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.size,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment:
          WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: [
        IconButton(
          tooltip: 'Первая страница',
          onPressed: page > 1
              ? () => onPageChanged(1)
              : null,
          icon: const Icon(
            Icons.first_page,
          ),
        ),

        IconButton(
          tooltip: 'Предыдущая страница',
          onPressed: page > 1
              ? () => onPageChanged(
                    page - 1,
                  )
              : null,
          icon: const Icon(
            Icons.chevron_left,
          ),
        ),

        Text(
          'Страница $page из $totalPages',
        ),

        IconButton(
          tooltip: 'Следующая страница',
          onPressed: page < totalPages
              ? () => onPageChanged(
                    page + 1,
                  )
              : null,
          icon: const Icon(
            Icons.chevron_right,
          ),
        ),

        IconButton(
          tooltip: 'Последняя страница',
          onPressed: page < totalPages
              ? () => onPageChanged(
                    totalPages,
                  )
              : null,
          icon: const Icon(
            Icons.last_page,
          ),
        ),

        const SizedBox(width: 12),

        Text(
          'Всего записей: $total',
        ),

        const SizedBox(width: 12),

        const Text('На странице:'),

        DropdownButton<int>(
          value: size,
          items: const [
            DropdownMenuItem(
              value: 10,
              child: Text('10'),
            ),
            DropdownMenuItem(
              value: 25,
              child: Text('25'),
            ),
            DropdownMenuItem(
              value: 50,
              child: Text('50'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onSizeChanged(value);
            }
          },
        ),
      ],
    );
  }
}