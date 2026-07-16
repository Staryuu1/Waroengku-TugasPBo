import 'package:flutter/material.dart';
import '../../services/theme_service.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ThemeService.instance.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _ThemeOptionCard(
            mode: ThemeMode.system,
            currentMode: currentMode,
            title: 'Sistem',
            description: 'Mengikuti pengaturan tema perangkat Anda',
            thumbnailColors: const [
              Color(0xFFF6F7F9),
              Color(0xFF121212),
            ],
            onTap: () => _selectMode(ThemeMode.system),
          ),
          const SizedBox(height: 16),
          _ThemeOptionCard(
            mode: ThemeMode.light,
            currentMode: currentMode,
            title: 'Terang',
            description: 'Tampilan cerah untuk siang hari',
            thumbnailColors: const [
              Color(0xFFF6F7F9),
              Color(0xFF4CAF50),
            ],
            onTap: () => _selectMode(ThemeMode.light),
          ),
          const SizedBox(height: 16),
          _ThemeOptionCard(
            mode: ThemeMode.dark,
            currentMode: currentMode,
            title: 'Gelap',
            description: 'Tampilan gelap untuk malam hari',
            thumbnailColors: const [
              Color(0xFF121212),
              Color(0xFF1F1F1F),
            ],
            onTap: () => _selectMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMode(ThemeMode mode) async {
    await ThemeService.instance.setThemeMode(mode);
    if (mounted) Navigator.pop(context);
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final ThemeMode mode;
  final ThemeMode currentMode;
  final String title;
  final String description;
  final List<Color> thumbnailColors;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.mode,
    required this.currentMode,
    required this.title,
    required this.description,
    required this.thumbnailColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;

    return Card(
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Preview thumbnail
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Column(
                    children: [
                      Container(
                        height: 20,
                        color: thumbnailColors.length > 1
                            ? thumbnailColors[1]
                            : thumbnailColors[0],
                      ),
                      Expanded(
                        child: Container(
                          color: thumbnailColors[0],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Radio indicator
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
