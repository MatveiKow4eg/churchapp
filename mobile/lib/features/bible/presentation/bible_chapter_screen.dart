import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bible_providers.dart';
import '../bible_progress_providers.dart';
import '../models/verse.dart';
import '../bible_reader_settings_providers.dart';
import '../bible_reader_settings_storage.dart';
import 'bible_reader_settings_sheet.dart';

class BibleChapterScreen extends ConsumerStatefulWidget {
  const BibleChapterScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    this.initialChapter = 1,
    this.maxChapters,
    this.highlightVerse,
    this.highlightToVerse,
    this.highlightQuery,
  });

  final String bookId;
  final String bookName;
  final int initialChapter;
  final int? maxChapters;

  /// First verse to highlight (inclusive).
  final int? highlightVerse;

  /// End verse to highlight (inclusive). If null, highlights only [highlightVerse].
  final int? highlightToVerse;

  final String? highlightQuery;

  @override
  ConsumerState<BibleChapterScreen> createState() => _BibleChapterScreenState();
}

class _NavArrowButton extends StatelessWidget {
  const _NavArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? cs.primary.withValues(alpha: 0.95)
            : cs.surfaceContainerHighest,
        shape: const StadiumBorder(),
        elevation: enabled ? 4 : 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 64,
            height: 56,
            child: Icon(
              icon,
              color: enabled ? cs.onPrimary : cs.onSurfaceVariant,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _BibleChapterScreenState extends ConsumerState<BibleChapterScreen> {
  late int _chapterNumber;
  String? _lastSavedKey;

  Future<dynamic>? _chapterFuture;

  /// Multi-select verses for copying.
  final Set<int> _selectedVerseNumbers = <int>{};

  final ScrollController _scrollController = ScrollController();

  bool _showNavArrows = true;
  double _lastScrollOffset = 0;

  // Temporary highlight state for verse from search
  // bool _highlightActive = false;
  // Timer? _highlightTimer;

  /// Used for reliable auto-scroll to a highlighted verse.
  final Map<int, GlobalKey> _verseKeys = <int, GlobalKey>{};

  /// Ensure we do auto-scroll only once per chapter render.
  String? _lastAutoScrolledKey;

  String _formatVerseCopy(Verse v) {
    return '${widget.bookName} $_chapterNumber:${v.number} (SYN)\n${v.text}';
  }

  String _formatMultiVerseCopy(List<Verse> verses) {
    final sorted = [...verses]..sort((a, b) => a.number.compareTo(b.number));
    final header = '${widget.bookName} $_chapterNumber (SYN)';
    final body = sorted.map((v) => '${v.number}. ${v.text}').join('\n');
    return '$header\n$body';
  }

  @override
  void initState() {
    super.initState();
    _chapterNumber = widget.initialChapter;

    _lastScrollOffset = 0;
    _scrollController.addListener(_handleScroll);

    _applyInitialHighlightSelection();
  }

  void _handleScroll() {
    final offset = _scrollController.position.pixels;
    final delta = offset - _lastScrollOffset;

    _lastScrollOffset = offset;

    // Ignore tiny jitter.
    if (delta.abs() < 6) return;

    if (delta > 0) {
      // Scrolling down => hide.
      if (_showNavArrows) {
        setState(() {
          _showNavArrows = false;
        });
      }
    } else {
      // Scrolling up => show.
      if (!_showNavArrows) {
        setState(() {
          _showNavArrows = true;
        });
      }
    }
  }

  void _applyInitialHighlightSelection() {
    // Only preselect verses for the initial highlight range.
    _selectedVerseNumbers.clear();

    final start = widget.highlightVerse;
    if (start == null || start <= 0) return;

    final endRaw = widget.highlightToVerse;
    final end = (endRaw == null || endRaw <= 0) ? start : endRaw;

    final lo = start < end ? start : end;
    final hi = start < end ? end : start;

    for (var i = lo; i <= hi; i++) {
      _selectedVerseNumbers.add(i);
    }
  }

  @override
  void dispose() {
    // _highlightTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canPrev => _chapterNumber > 1;

  bool get _canNext {
    final max = widget.maxChapters;
    if (max == null) return true;
    return _chapterNumber < max;
  }

  void _goPrev() {
    if (!_canPrev) return;
    setState(() {
      _chapterNumber--;
      _chapterFuture = null;
      // Range highlight is intended for the initial open only.
      _selectedVerseNumbers.clear();
    });
  }

  void _goNext() {
    if (!_canNext) return;
    setState(() {
      _chapterNumber++;
      _chapterFuture = null;
      // Range highlight is intended for the initial open only.
      _selectedVerseNumbers.clear();
    });
  }

  
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(bibleRepositoryProvider);
    final settingsAsync = ref.watch(bibleReaderSettingsProvider);
    final settings = settingsAsync.value ?? BibleReaderSettings.defaults;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/bible');
            }
          },
        ),
        title: Text('${widget.bookName} $_chapterNumber'),
        actions: [
          IconButton(
            tooltip: 'Настройки чтения',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const BibleReaderSettingsSheet(),
              );
            },
          ),
          IconButton(
            tooltip: 'Скопир��вать выбранное',
            icon: const Icon(Icons.copy),
            onPressed: _selectedVerseNumbers.isEmpty
                ? null
                : () async {
                    final chapter = await repo.getRusSynChapter(
                      widget.bookId,
                      _chapterNumber,
                    );

                    final selectedVerses = chapter.verses
                        .where((v) => _selectedVerseNumbers.contains(v.number))
                        .toList();
                    if (selectedVerses.isEmpty) return;

                    await Clipboard.setData(
                      ClipboardData(text: _formatMultiVerseCopy(selectedVerses)),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Скопировано: ${selectedVerses.length} ${selectedVerses.length == 1 ? 'стих' : 'стих(и)'}',
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: FutureBuilder(
        // Keep the Future stable across rebuilds (e.g. verse selection),
        // otherwise FutureBuilder may restart and scroll position may jump.
        future: _chapterFuture ??= repo.getRusSynChapter(widget.bookId, _chapterNumber),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          final chapter = snapshot.data;
          if (chapter == null) {
            return const Center(child: Text('Нет данных')); // should not happen
          }

          // Save progress once per chapter (avoid doing it on every rebuild).
          final currentKey = '${widget.bookId}:$_chapterNumber';
          if (_lastSavedKey != currentKey) {
            _lastSavedKey = currentKey;
            Future.microtask(() async {
              try {
                await ref.read(bibleProgressStorageProvider).saveLastPosition(
                      bookId: widget.bookId,
                      chapter: _chapterNumber,
                      bookName: widget.bookName,
                    );
                // Refresh continue-reading block.
                ref.invalidate(lastBiblePositionProvider);
              } catch (_) {
                // Ignore storage errors.
              }
            });
          }

          if (chapter.verses.isEmpty) {
            debugPrint('TODO chapter parser: verses empty for ${widget.bookId} $_chapterNumber');
            final pretty = const JsonEncoder.withIndent('  ').convert(chapter.rawJson);
            final truncated = pretty.length > 2000 ? pretty.substring(0, 2000) : pretty;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Не удалось распарсить стихи для этой главы',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('Показать сырой JSON'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SelectableText(truncated),
                    ),
                  ],
                ),
              ],
            );
          }

          // Auto-scroll to highlighted verse (from search) once per chapter load.
          final hv = widget.highlightVerse;
          if (hv != null && hv > 0) {
            final autoKey = '${widget.bookId}:$_chapterNumber:$hv';
            if (_lastAutoScrolledKey != autoKey) {
              _lastAutoScrolledKey = autoKey;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                final ctx = _verseKeys[hv]?.currentContext;
                if (ctx == null) return;

                Scrollable.ensureVisible(
                  ctx,
                  alignment: 0.25,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                );
              });
            }
          }

          return Stack(
            children: [
              ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                itemCount: chapter.verses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
              final v = chapter.verses[index];
              final isSelected = _selectedVerseNumbers.contains(v.number);

              final hvStartRaw = widget.highlightVerse;
              final hvEndRaw = widget.highlightToVerse ?? widget.highlightVerse;

              // Apply highlight only on the initial chapter that was opened.
              final highlightActive =
                  _chapterNumber == widget.initialChapter && hvStartRaw != null;

              int? lo;
              int? hi;
              if (highlightActive && hvStartRaw != null && hvEndRaw != null) {
                final a = hvStartRaw;
                final b = hvEndRaw;
                lo = a < b ? a : b;
                hi = a < b ? b : a;
              }

              final isHighlighted =
                  lo != null && hi != null && v.number >= lo && v.number <= hi;

              final key = (isHighlighted && v.number == (widget.highlightVerse ?? 0))
                  ? (_verseKeys[v.number] ??= GlobalKey())
                  : null;

              final content = Padding(
                padding: EdgeInsets.symmetric(horizontal: settings.horizontalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (settings.showVerseNumbers)
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${v.number}',
                          textAlign: TextAlign.right,
                          style: DefaultTextStyle.of(context).style.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: settings.lineHeight,
                              ),
                        ),
                      ),
                    if (settings.showVerseNumbers) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        v.text,
                        style: DefaultTextStyle.of(context).style.copyWith(
                              fontSize: settings.fontSize,
                              height: settings.lineHeight,
                            ),
                      ),
                    ),
                  ],
                ),
              );

              final decorated = (isSelected || isHighlighted)
                  ? Container(
                      key: key,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.10)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: (isHighlighted && v.number == widget.highlightVerse)
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: content,
                    )
                  : content;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (_selectedVerseNumbers.contains(v.number)) {
                      _selectedVerseNumbers.remove(v.number);
                    } else {
                      _selectedVerseNumbers.add(v.number);
                    }
                  });
                },
                onLongPress: () {
                  // Long press also toggles selection (no auto-copy).
                  setState(() {
                    if (_selectedVerseNumbers.contains(v.number)) {
                      _selectedVerseNumbers.remove(v.number);
                    } else {
                      _selectedVerseNumbers.add(v.number);
                    }
                  });
                },
                child: decorated,
              );
            },
          ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  minimum: const EdgeInsets.only(bottom: 8),
                  child: AnimatedSlide(
                    offset: _showNavArrows ? Offset.zero : const Offset(0, 0.35),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: _showNavArrows ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _NavArrowButton(
                              icon: Icons.chevron_left,
                              tooltip: 'Предыдущая глава',
                              onPressed: _canPrev ? _goPrev : null,
                            ),
                            _NavArrowButton(
                              icon: Icons.chevron_right,
                              tooltip: 'Следующая глава',
                              onPressed: _canNext ? _goNext : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
