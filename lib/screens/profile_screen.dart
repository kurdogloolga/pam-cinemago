import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: null,
            tooltip: 'Настройки профиля',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 44,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Анастасия Иванова',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Участник CinemaGo',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _ProfileSection(
            title: 'Личные данные',
            children: const [
              _ProfileInfoTile(
                icon: Icons.email_outlined,
                title: 'Электронная почта',
                subtitle: 'anastasia.ivanova@example.com',
              ),
              _ProfileInfoTile(
                icon: Icons.phone_outlined,
                title: 'Телефон',
                subtitle: '+373 69 123 456',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileSection(
            title: 'Настройки',
            children: const [
              _ProfileInfoTile(
                icon: Icons.notifications_outlined,
                title: 'Уведомления',
                subtitle: 'Напоминания о предстоящих сеансах',
                trailing: Icon(Icons.toggle_on_outlined),
              ),
              _ProfileInfoTile(
                icon: Icons.language_outlined,
                title: 'Язык приложения',
                subtitle: 'Русский',
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileSection(
            title: 'Информация',
            children: const [
              _ProfileInfoTile(
                icon: Icons.help_outline,
                title: 'Помощь и поддержка',
                trailing: Icon(Icons.chevron_right),
              ),
              _ProfileInfoTile(
                icon: Icons.description_outlined,
                title: 'Правила и условия',
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CinemaGo · версия 1.0.0',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}
