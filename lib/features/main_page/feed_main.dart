import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/core/l10n/app_localizations.dart';
import 'package:my_app/core/cubit/news_cubit.dart';
import 'package:my_app/core/models/news_region.dart';
import 'package:my_app/core/models/news_category.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    final newsCubit = context.read<NewsCubit>();
    final l10n = AppLocalizations.of(context);

    try {
      await newsCubit.fetchLatestNews();

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.locale.languageCode == 'ru' ? 'Успешно' : 'Success',
                ),
              ],
            ),
            content: Text(
              l10n.locale.languageCode == 'ru'
                  ? 'Новости успешно загружены!'
                  : 'News loaded successfully!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.locale.languageCode == 'ru' ? 'Ошибка' : 'Error',
                ),
              ],
            ),
            content: Text(
              l10n.locale.languageCode == 'ru'
                  ? 'Ошибка загрузки новостей: ${e.toString()}'
                  : 'Error loading news: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF131320),
                        const Color(0xFF1E1E2E),
                        const Color(0xFF131320),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF5F7FF),
                        Colors.white,
                      ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      l10n.locale.languageCode == 'ru' ? 'Новости' : 'News',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.locale.languageCode == 'ru'
                          ? 'Оставайтесь в курсе событий'
                          : 'Stay up to date with events',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Region Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(77),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: NewsRegion.values.map((region) {
                          final isSelected = state.currentRegion == region;
                          return GestureDetector(
                            onTap: () => context.read<NewsCubit>().setRegion(region),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.secondary,
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                region.toDisplayString(l10n.locale.languageCode),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: NewsCategory.values.map((category) {
                          final isSelected = state.currentCategory == category;
                          return FilterChip(
                            label: Text(
                              category.toDisplayString(l10n.locale.languageCode),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                context.read<NewsCubit>().setCategory(category);
                              }
                            },
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: theme.colorScheme.primary,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withAlpha(77),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: isSelected ? 4 : 0,
                            shadowColor: theme.colorScheme.primary.withAlpha(102),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Animated Button
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: state.isLoading ? 1.0 : _scaleAnimation.value,
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: state.isLoading ? null : _fetchNews,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withAlpha(102),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(110),
                              onTap: state.isLoading ? null : _fetchNews,
                              child: Center(
                                child: state.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.newspaper_rounded,
                                              color: Colors.white,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              l10n.viewLatestNews,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1.3,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
