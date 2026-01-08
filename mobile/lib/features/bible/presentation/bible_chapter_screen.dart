import 'dart:convert';

import 'package:flutter/material.dart';
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
    this.highlightQuery,
  });

  final String bookId;
  final String bookName;
  final int initialChapter;
  final int? maxChapters;
  final int? highlightVerse;
  final String? highlightQuery;

  @override
  ConsumerState<BibleChapterScreen> createState() => _BibleChapterScreenState();
}

class _BibleChapterScreenState extends ConsumerState<BibleChapterScreen> {
  late int _chapterNumber;
  String? _lastSavedKey;

  /// Multi-select verses for copying.
  final Set<int> _selectedVerseNumbers = <int>{};

  final ScrollController _scrollController = ScrollController();

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

    // If opened from search result, enable temporary highlight
    final v = widget.highlightVerse;
    if (v != null && v > 0) {
      _selectedVerseNumbers.add(v);
    }
  }

  @override
  void dispose() {
    // _highlightTimer?.cancel();
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
    setState(() => _chapterNumber--);
  }

  void _goNext() {
    if (!_canNext) return;
    setState(() => _chapterNumber++);
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
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _canPrev ? _goPrev : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Пред.'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _canNext ? _goNext : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('След.'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder(
        future: repo.getRusSynChapter(widget.bookId, _chapterNumber),
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

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chapter.verses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final v = chapter.verses[index];
              final isSelected = _selectedVerseNumbers.contains(v.number);

              final isHighlighted = widget.highlightVerse != null &&
                  widget.highlightVerse == v.number;

              final key = isHighlighted
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
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: isHighlighted
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
          );
        },
      ),
    );
  }
}
