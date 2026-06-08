// inventory_screen.dart
// ─────────────────────
// Inventar-Verwaltungs-Screen der StageSync App.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inventory_provider.dart';
import '../providers/network_state_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredInventoryProvider);
    final allItems = ref.watch(inventoryProvider);
    final activeFilter = ref.watch(inventoryFilterProvider);
    final isReady = ref.watch(isNetworkReadyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FilterChipBar(activeFilter: activeFilter),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${items.length} / ${allItems.length}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: items.isEmpty
          ? _EmptyState(hasFilter: activeFilter != null)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, i) => _InventoryItemCard(
                item: items[i],
                onTap: () => _showStatusSheet(context, ref, items[i]),
              ),
            ),
      floatingActionButton: isReady
          ? FloatingActionButton.extended(
              onPressed: () => _showAddItemDialog(context, ref),
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Item hinzufügen'),
            )
          : null,
    );
  }

  void _showStatusSheet(
      BuildContext context, WidgetRef ref, InventoryItemDisplay item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _StatusChangeSheet(item: item, ref: ref),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddItemDialog(ref: ref),
    );
  }
}

// ─── Filter Chip Bar ──────────────────────────────────────────────────────────

class _FilterChipBar extends ConsumerWidget {
  final InventoryStatus? activeFilter;
  const _FilterChipBar({required this.activeFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _FChip(
            label: 'Alle',
            selected: activeFilter == null,
            color: Theme.of(context).colorScheme.primary,
            onSelected: () =>
                ref.read(inventoryFilterProvider.notifier).state = null,
          ),
          ...InventoryStatus.values.map((s) => _FChip(
                label: s.label,
                selected: activeFilter == s,
                color: inventoryStatusColor(s),
                onSelected: () =>
                    ref.read(inventoryFilterProvider.notifier).state = s,
              )),
        ],
      ),
    );
  }
}

class _FChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;
  const _FChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: color.withValues(alpha: 0.25),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: selected ? color : null,
          fontWeight: selected ? FontWeight.bold : null,
        ),
        side: BorderSide(color: selected ? color : Colors.transparent),
      ),
    );
  }
}

// ─── Inventory Item Card ──────────────────────────────────────────────────────

class _InventoryItemCard extends StatelessWidget {
  final InventoryItemDisplay item;
  final VoidCallback onTap;
  const _InventoryItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final st = item.status;
    final color = inventoryStatusColor(st);
    final diff = DateTime.now().difference(item.lastUpdated);
    final timeLabel = diff.inSeconds < 10
        ? 'Gerade'
        : diff.inMinutes < 1
            ? 'Vor ${diff.inSeconds}s'
            : diff.inHours < 1
                ? 'Vor ${diff.inMinutes}min'
                : 'Vor ${diff.inHours}h';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                    child:
                        Icon(inventoryStatusIcon(st), color: color, size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.shortId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusBadge(status: st, color: color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.locationTag != null) ...[
                          Icon(Icons.place_outlined,
                              size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(item.locationTag!,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.schedule_outlined,
                            size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(timeLabel,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: item.isSyncedToServer
                    ? const Icon(Icons.cloud_done,
                        size: 16, color: Colors.green)
                    : const Icon(Icons.cloud_upload_outlined,
                        size: 16, color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InventoryStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Status Bottom Sheet ──────────────────────────────────────────────────────

class _StatusChangeSheet extends StatelessWidget {
  final InventoryItemDisplay item;
  final WidgetRef ref;
  const _StatusChangeSheet({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status ändern',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(item.shortId,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            ...InventoryStatus.values.map((s) {
              final isActive = item.statusId == s.code;
              final color = inventoryStatusColor(s);
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isActive ? color : Colors.transparent),
                  ),
                  child: Icon(inventoryStatusIcon(s), color: color, size: 18),
                ),
                title: Text(s.label,
                    style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal)),
                trailing:
                    isActive ? Icon(Icons.check_circle, color: color) : null,
                onTap: () {
                  if (!isActive) {
                    ref
                        .read(inventoryProvider.notifier)
                        .updateStatus(item.itemId, s.code);
                  }
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Add Item Dialog ──────────────────────────────────────────────────────────

class _AddItemDialog extends StatefulWidget {
  final WidgetRef ref;
  const _AddItemDialog({required this.ref});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _idCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  InventoryStatus _selectedStatus = InventoryStatus.inPlace;
  bool _sending = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neues Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _idCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item-ID / QR-Code',
                hintText: 'z.B. PROP-001',
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locCtrl,
              decoration: const InputDecoration(
                labelText: 'Ort (optional)',
                hintText: 'z.B. Bühne links',
                prefixIcon: Icon(Icons.place_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Anfangsstatus',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: InventoryStatus.values.map((s) {
                final sel = _selectedStatus == s;
                final color = inventoryStatusColor(s);
                return ChoiceChip(
                  label: Text(s.label),
                  selected: sel,
                  selectedColor: color.withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _selectedStatus = s),
                  labelStyle: TextStyle(
                    color: sel ? color : null,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(color: sel ? color : Colors.transparent),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _sending ? null : _submit,
          icon: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Senden'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() => _sending = true);
    await widget.ref.read(inventoryProvider.notifier).addItem(
          itemId: id,
          statusId: _selectedStatus.code,
          locationTag:
              _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Keine Items mit diesem Status'
                : 'Kein Inventar vorhanden',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Filter oben ändern oder zurücksetzen.'
                : 'Tippe auf „Item hinzufügen" um das erste\nItem über das BLE-Mesh zu übertragen.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Shared theme helpers ─────────────────────────────────────────────────────

Color inventoryStatusColor(InventoryStatus s) => switch (s) {
      InventoryStatus.inPlace => Colors.green,
      InventoryStatus.checkedOut => Colors.orange,
      InventoryStatus.missing => Colors.red,
      InventoryStatus.damaged => Colors.amber,
    };

IconData inventoryStatusIcon(InventoryStatus s) => switch (s) {
      InventoryStatus.inPlace => Icons.check_circle_outline,
      InventoryStatus.checkedOut => Icons.outbox_outlined,
      InventoryStatus.missing => Icons.search_off,
      InventoryStatus.damaged => Icons.warning_amber_outlined,
    };
