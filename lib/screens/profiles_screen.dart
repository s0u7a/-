import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/models.dart';
import '../providers/profile_provider.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, prov),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final p = prov.profiles[i];
          final isActive = p.id == prov.activeProfileId;
          return Container(
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary.withOpacity(0.1) : AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: isActive ? Border.all(color: AppTheme.primary.withOpacity(0.4)) : null,
            ),
            child: ListTile(
              leading: Text(p.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                  if (!isActive)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _confirmDelete(context, prov, p),
                    ),
                ],
              ),
              onTap: () {
                prov.setActive(p.id!);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, ProfileProvider prov) {
    final nameCtrl = TextEditingController();
    String selectedEmoji = Profile.defaultEmojis.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text('新しいプロフィール'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: '名前',
                  filled: true,
                  fillColor: AppTheme.surface,
                ),
              ),
              const SizedBox(height: 16),
              const Text('アイコン', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Profile.defaultEmojis.map((e) {
                  final sel = e == selectedEmoji;
                  return GestureDetector(
                    onTap: () => setLocal(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: sel ? Border.all(color: AppTheme.primary) : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  prov.addProfile(nameCtrl.text, selectedEmoji);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProfileProvider prov, Profile p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('${p.name}を削除'),
        content: const Text('このプロフィールの統計も全て削除されます', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              prov.deleteProfile(p.id!);
              Navigator.pop(ctx);
            },
            child: const Text('削除', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
