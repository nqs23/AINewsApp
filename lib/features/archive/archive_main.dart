import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/core/l10n/app_localizations.dart';
import 'package:my_app/core/cubit/news_cubit.dart';
import 'package:my_app/core/models/news_item.dart';
import 'package:my_app/core/models/news_region.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  DateTime _getDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = _getDateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = _getDateOnly(date);

    if (dateOnly == today) {
      return l10n.today;
    } else if (dateOnly == yesterday) {
      return l10n.yesterday;
    } else {
      return DateFormat('dd MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        final cubit = context.read<NewsCubit>();
        final sortedDates = cubit
            .getSortedDates()
            .where((date) => cubit.hasNewsForRegion(date, state.currentRegion))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.newsArchive,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF131320),
                        const Color(0xFF1E1E2E).withAlpha(128),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF5F7FF),
                      ],
              ),
            ),
            child: Column(
              children: [
                // Region Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
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
                ),
                // Main content
                Expanded(
                  child: sortedDates.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withAlpha(51),
                                    theme.colorScheme.secondary.withAlpha(51),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.archive_outlined,
                                size: 80,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.noNewsYet,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                l10n.locale.languageCode == 'ru'
                                    ? 'Нажмите кнопку на главном экране\nчтобы загрузить новости'
                                    : 'Press the button on the main screen\nto load news',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(153),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final newsItems = cubit.getNewsForDate(date);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _formatDate(date, l10n),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withAlpha(51),
                                        ),
                                      ),
                                      child: Text(
                                        '${newsItems.length} ${l10n.locale.languageCode == 'ru' ? 'новостей' : 'news'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...newsItems.map((newsItem) => _NewsCard(
                                    newsItem: newsItem,
                                    theme: theme,
                                  )),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem newsItem;
  final ThemeData theme;

  const _NewsCard({
    required this.newsItem,
    required this.theme,
  });

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);

      // Try different modes in order
      bool launched = false;

      // Try external application first
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      // If that fails, try platform default
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      // If that fails too, try in-app browser
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }

      // If still not launched, show error
      if (!launched && context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Unable to open'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This may not work on simulator.\nTry on a real device.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(dialogContext).colorScheme.outline.withAlpha(128),
                    ),
                  ),
                  child: SelectableText(
                    url,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    // Show a brief confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Link copied to clipboard'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Link'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error: ${e.toString()}'),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withAlpha(26),
            theme.colorScheme.secondary.withAlpha(13),
          ],
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: theme.cardTheme.color?.withAlpha(230) ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.primary.withAlpha(26),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: newsItem.url != null ? () => _openUrl(context, newsItem.url!) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.article_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newsItem.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        newsItem.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(179),
                          height: 1.4,
                        ),
                      ),
                      if (newsItem.source != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.source_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  newsItem.source!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (newsItem.url != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.open_in_new_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
