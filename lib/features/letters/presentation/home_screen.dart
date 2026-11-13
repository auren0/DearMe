import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extension.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/letter.dart';
import '../../../core/models/letter_status.dart';
import '../../../shared/widgets/app_background.dart';
import 'widgets/brand_mark.dart';
import '../../../shared/widgets/content_width.dart';
import 'widgets/empty_letters_state.dart';
import 'widgets/envelope_art.dart';
import 'widgets/letter_card.dart';
import 'widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lettersAsync = ref.watch(lettersControllerProvider);
    final clock = ref.watch(clockProvider);
    final now = ref.watch(tickingNowProvider).value ?? clock();
    final stats = ref.watch(letterStatisticsProvider);
    final storageAvailable = ref.watch(storageAvailableProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: lettersAsync.when(
            loading: () => const _HomeLoading(),
            error: (error, stackTrace) => _HomeError(
              onRetry: () =>
                  ref.read(lettersControllerProvider.notifier).refresh(),
            ),
            data: (letters) {
              final ready = <Letter>[];
              final sealed = <Letter>[];
              final opened = <Letter>[];
              final drafts = <Letter>[];
              for (final letter in letters) {
                switch (letter.statusAt(now)) {
                  case LetterStatus.ready:
                    ready.add(letter);
                  case LetterStatus.sealed:
                    sealed.add(letter);
                  case LetterStatus.opened:
                    opened.add(letter);
                  case LetterStatus.draft:
                    drafts.add(letter);
                }
              }
              ready.sort((a, b) => a.openAt!.compareTo(b.openAt!));
              sealed.sort((a, b) => a.openAt!.compareTo(b.openAt!));
              opened.sort((a, b) => b.openedAt!.compareTo(a.openedAt!));
              drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(lettersControllerProvider.notifier).refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: ContentWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 14),
                            _HomeHeader(
                              onSettings: () => context.push('/settings'),
                            ),
                            if (!storageAvailable) ...<Widget>[
                              const SizedBox(height: 14),
                              _StorageWarning(),
                            ],
                            const SizedBox(height: 24),
                            _HeroSection(
                              now: now,
                              waiting: stats.sealed + stats.ready,
                              total: stats.total,
                              onCreate: () => context.push('/editor'),
                            ),
                            const SizedBox(height: 20),
                            _StatsRow(stats: stats),
                            const SizedBox(height: 34),
                          ],
                        ),
                      ),
                    ),
                    if (letters.isEmpty)
                      SliverToBoxAdapter(
                        child: ContentWidth(
                          child: EmptyLettersState(
                            onCreate: () => context.push('/editor'),
                          ),
                        ),
                      )
                    else ...<Widget>[
                      if (ready.isNotEmpty)
                        ..._section(
                          context,
                          title: context.l10n.homeReadySection,
                          icon: FluentIcons.line.open,
                          count: ready.length,
                          letters: ready,
                          now: now,
                          accent: Theme.of(context).colorScheme.primary,
                        ),
                      if (sealed.isNotEmpty)
                        ..._section(
                          context,
                          title: context.l10n.homeSealedSection,
                          icon: FluentIcons.line.lock_closed,
                          count: sealed.length,
                          letters: sealed,
                          now: now,
                        ),
                      if (drafts.isNotEmpty)
                        ..._section(
                          context,
                          title: context.l10n.homeDraftsSection,
                          icon: FluentIcons.line.edit,
                          count: drafts.length,
                          letters: drafts,
                          now: now,
                        ),
                      if (opened.isNotEmpty)
                        ..._section(
                          context,
                          title: context.l10n.homeOpenedSection,
                          icon: FluentIcons.line.mail_read,
                          count: opened.length,
                          letters: opened,
                          now: now,
                        ),
                    ],
                    SliverToBoxAdapter(
                      child: ContentWidth(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 36, bottom: 38),
                          child: Center(
                            child: Text(
                              context.l10n.homeFooterQuote,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int count,
    required List<Letter> letters,
    required DateTime now,
    Color? accent,
  }) {
    return <Widget>[
      SliverToBoxAdapter(
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SectionHeader(
              title: title,
              icon: icon,
              count: count,
              accentColor: accent,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: _LetterWrap(
              letters: letters,
              now: now,
              onTap: (letter) {
                if (letter.isDraft) {
                  context.push('/editor/${letter.id}');
                } else {
                  context.push('/letter/${letter.id}');
                }
              },
            ),
          ),
        ),
      ),
    ];
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Row(
          children: <Widget>[
            BrandMark(compact: compact, showTagline: !compact),
            const Spacer(),
            IconButton(
              onPressed: onSettings,
              tooltip: l10n.a11yOpenSettings,
              icon: Icon(FluentIcons.line.settings),
            ),
          ],
        );
      },
    );
  }
}

class _StorageWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            FluentIcons.line.warning,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.storageUnavailableBanner,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.now,
    required this.waiting,
    required this.total,
    required this.onCreate,
  });

  final DateTime now;
  final int waiting;
  final int total;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = theme.extension<DearMePalette>()!;
    final localNow = now.toLocal();
    final greeting = switch (localNow.hour) {
      < 5 => l10n.homeGreetingNight,
      < 12 => l10n.homeGreetingMorning,
      < 18 => l10n.homeGreetingAfternoon,
      _ => l10n.homeGreetingEvening,
    };
    final summary = total == 0
        ? l10n.homeSubtitleEmpty
        : waiting == 0
        ? l10n.homeSummaryAllRead
        : l10n.homeSummary(waiting);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$greeting. ${l10n.homeHello}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          summary,
          style: theme.textTheme.displaySmall?.copyWith(
            height: 1.12,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onCreate,
          icon: Icon(FluentIcons.line.add),
          label: Text(l10n.homeNewLetter),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.heroStart,
            Color.alphaBlend(
              theme.colorScheme.primary.withValues(alpha: 0.04),
              palette.heroEnd,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                text,
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: EnvelopeArt(
                    width: 220,
                    semanticLabel: l10n.appTagline,
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(flex: 6, child: text),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: EnvelopeArt(width: 260, semanticLabel: l10n.appTagline),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final LetterStatistics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 3 : 1;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: width,
              child: _StatTile(
                icon: FluentIcons.line.lock_closed,
                label: l10n.statSealed,
                value: stats.sealed,
              ),
            ),
            SizedBox(
              width: width,
              child: _StatTile(
                icon: FluentIcons.line.open,
                label: l10n.statReady,
                value: stats.ready,
                highlighted: stats.ready > 0,
              ),
            ),
            SizedBox(
              width: width,
              child: _StatTile(
                icon: FluentIcons.line.mail_read,
                label: l10n.statOpened,
                value: stats.opened,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<DearMePalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : palette.cardBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: highlighted
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: highlighted
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              color: highlighted
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterWrap extends StatelessWidget {
  const _LetterWrap({
    required this.letters,
    required this.now,
    required this.onTap,
  });

  final List<Letter> letters;
  final DateTime now;
  final ValueChanged<Letter> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 580
            ? 2
            : 1;
        const spacing = 16.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final letter in letters)
              SizedBox(
                width: width,
                child: LetterCard(
                  letter: letter,
                  now: now,
                  onTap: () => onTap(letter),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.loading,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: ContentWidth(
        maxWidth: 520,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  FluentIcons.line.warning,
                  size: 34,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.loadErrorTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.offlineOrPermission,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
