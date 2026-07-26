import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/bottom_sheet_shell.dart';
import '../../../domain/entities/address.dart';
import '../../providers/auth_controller.dart';
import '../../providers/repository_providers.dart';

/// Address book — list, add, edit and delete the user's saved addresses.
class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final signedIn = ref.watch(authControllerProvider).isAuthenticated;

    if (!signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Addresses')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: c.muted),
              const SizedBox(height: 12),
              const Text('Sign in to manage addresses'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        backgroundColor: c.green,
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_outlined, size: 56, color: c.muted),
                  const SizedBox(height: 12),
                  const Text('No saved addresses yet'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: AppSpacing.page,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _AddressCard(
              address: list[i],
              onEdit: () => _openForm(context, ref, existing: list[i]),
              onDelete: () => _delete(context, ref, list[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {Address? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressForm(existing: existing),
    );
    ref.invalidate(addressesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Address a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text(a.formatted),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(addressRepositoryProvider).remove(a.id);
      ref.invalidate(addressesProvider);
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard(
      {required this.address, required this.onEdit, required this.onDelete});
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: c.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    if (address.isDefault)
                      const AppTag('Default', variant: TagVariant.green),
                  ],
                ),
                const SizedBox(height: 4),
                Text(address.formatted,
                    style: TextStyle(fontSize: 12.5, color: c.muted)),
              ],
            ),
          ),
          IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, size: 20, color: c.muted)),
          IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.redAccent)),
        ],
      ),
    );
  }
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm({this.existing});
  final Address? existing;

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  late final _label = TextEditingController(text: widget.existing?.label ?? 'Home');
  late final _line = TextEditingController(text: widget.existing?.line ?? '');
  late final _area = TextEditingController(text: widget.existing?.area ?? '');
  late final _city =
      TextEditingController(text: widget.existing?.city ?? 'Navi Mumbai');
  late final _pincode =
      TextEditingController(text: widget.existing?.pincode ?? '');
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final ctl in [_label, _line, _area, _city, _pincode]) {
      ctl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_line.text.trim().length < 3) {
      setState(() => _error = 'Enter the full address line');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = AddressInput(
      label: _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
      line: _line.text.trim(),
      area: _area.text.trim(),
      city: _city.text.trim(),
      pincode: _pincode.text.trim(),
      isDefault: _isDefault,
    );
    try {
      final repo = ref.read(addressRepositoryProvider);
      if (widget.existing == null) {
        await repo.add(input);
      } else {
        await repo.update(widget.existing!.id, input);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not save: $e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetShell(
      title: widget.existing == null ? 'Add address' : 'Edit address',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Label', _label, hint: 'Home / Office'),
          _field('Address line', _line, hint: 'Flat, building, street'),
          Row(
            children: [
              Expanded(child: _field('Area', _area)),
              const SizedBox(width: 10),
              Expanded(child: _field('City', _city)),
            ],
          ),
          _field('Pincode', _pincode, keyboard: TextInputType.number),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set as default'),
            value: _isDefault,
            activeThumbColor: context.colors.green,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12.5)),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save address'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctl,
      {String? hint, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.muted)),
          const SizedBox(height: 4),
          TextField(
            controller: ctl,
            keyboardType: keyboard,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
