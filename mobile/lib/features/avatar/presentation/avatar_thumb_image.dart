import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Robust thumbnail widget for avatar option grids.
///
/// - Shows a lightweight progress indicator while loading.
/// - Shows an error state with "Tap to retry".
/// - Retry adds a cache-busting `t=<timestamp>` query param (thumbs only).
class AvatarThumbImage extends StatefulWidget {
  const AvatarThumbImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth = 96,
  });

  final Uri url;
  final BoxFit fit;
  final int cacheWidth;

  @override
  State<AvatarThumbImage> createState() => _AvatarThumbImageState();
}

class _AvatarThumbImageState extends State<AvatarThumbImage> {
  static int _failureCount = 0;

  // Automatic retry state.
  int _attempt = 0;
  int? _retryStamp;
  bool _retryScheduled = false;

  static const List<Duration> _backoff = <Duration>[
    Duration(milliseconds: 300),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1500),
  ];

  Uri get _effectiveUrl {
    if (_retryStamp == null) return widget.url;
    final qp = Map<String, String>.from(widget.url.queryParameters);
    qp['t'] = _retryStamp.toString();
    return widget.url.replace(queryParameters: qp);
  }

  void _manualRetry() {
    setState(() {
      _attempt = 0;
      _retryScheduled = false;
      _retryStamp = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _scheduleAutoRetry() {
    if (_attempt >= _backoff.length) return;
    if (_retryScheduled) return;

    _retryScheduled = true;
    final delay = _backoff[_attempt];

    Future.delayed(delay, () {
      if (!mounted) return;
      setState(() {
        _attempt += 1;
        _retryStamp = DateTime.now().millisecondsSinceEpoch;
        _retryScheduled = false;
      });
    });
  }

  @override
  void didUpdateWidget(covariant AvatarThumbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the base URL changes, reset retry state.
    if (oldWidget.url.toString() != widget.url.toString()) {
      _attempt = 0;
      _retryStamp = null;
      _retryScheduled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _effectiveUrl;

    return CachedNetworkImage(
      imageUrl: url.toString(),
      // Disk + memory caching (via flutter_cache_manager).
      memCacheWidth: widget.cacheWidth,
      placeholder: (context, _) {
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      imageBuilder: (context, imageProvider) {
        return Image(
          image: imageProvider,
          fit: widget.fit,
          filterQuality: FilterQuality.low,
        );
      },
      errorWidget: (context, _, error) {
        _failureCount += 1;
        debugPrint(
          '[AvatarThumbImage] load failed #$_failureCount attempt=$_attempt url=$url error=$error',
        );

        // Auto-retry with exponential-ish backoff.
        if (_attempt < _backoff.length) {
          _scheduleAutoRetry();
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Retrying… (${_attempt + 1}/${_backoff.length})',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        }

        // After max retries, show manual retry affordance.
        return InkWell(
          onTap: _manualRetry,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to retry',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
