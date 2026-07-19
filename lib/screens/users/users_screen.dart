import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_exception.dart';
import '../../core/rbac.dart';
import '../../models/user.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_feedback.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _service = UserService();
  List<ManagedUser> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.list();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat user';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({ManagedUser? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserFormSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(ManagedUser u) async {
    final confirmed = await AppFeedback.confirm(context, title: 'Hapus User', message: 'Hapus user "${u.name}"?', danger: true);
    if (!confirmed) return;
    try {
      await _service.delete(u.id);
      if (mounted) AppFeedback.success(context, 'User dihapus');
      _load();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e is ApiException ? e.message : 'Gagal menghapus user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen User')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), backgroundColor: AppColors.brand600, child: const Icon(Icons.add)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final u = _items[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                Text(u.email, style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  StatusBadge(roleLabel(u.role), tone: u.role == AppRole.admin ? BadgeTone.brand : BadgeTone.slate),
                                  const SizedBox(width: 6),
                                  StatusBadge(u.active ? 'Aktif' : 'Nonaktif', tone: u.active ? BadgeTone.green : BadgeTone.red),
                                ]),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openForm(existing: u)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red500), onPressed: () => _delete(u)),
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  final ManagedUser? existing;
  const _UserFormSheet({this.existing});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _service = UserService();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  AppRole _role = AppRole.staff;
  bool _active = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _role = u?.role ?? AppRole.staff;
    _active = u?.active ?? true;
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nama dan email wajib diisi.');
      return;
    }
    if (!_editing && _passwordCtrl.text.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _role.name.toUpperCase(),
    };
    if (_editing) data['active'] = _active;
    if (!_editing || _passwordCtrl.text.isNotEmpty) data['password'] = _passwordCtrl.text;

    try {
      if (_editing) {
        await _service.update(widget.existing!.id, data);
      } else {
        await _service.create(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal menyimpan user';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_editing ? 'Edit User' : 'Tambah User', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: _editing ? 'Password Baru (kosongkan jika tidak diubah)' : 'Password'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AppRole>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: AppRole.values.map((r) => DropdownMenuItem(value: r, child: Text(roleLabel(r)))).toList(),
              onChanged: (v) => setState(() => _role = v ?? AppRole.staff),
            ),
            if (_editing) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                value: _active,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [DropdownMenuItem(value: true, child: Text('Aktif')), DropdownMenuItem(value: false, child: Text('Nonaktif'))],
                onChanged: (v) => setState(() => _active = v ?? true),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red600, fontSize: 12.5)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
