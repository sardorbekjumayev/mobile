import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../l10n/strings.dart';
import 'primitives.dart';

/// Loads [load] once, renders [builder], and offers pull-to-refresh and a retry
/// on failure.
///
/// Every data screen in the app has the same three states, and repeating a
/// `FutureBuilder` with hand-rolled error handling on each of them is how two
/// screens end up disagreeing about what a network failure looks like.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.onRefresh,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() refresh) builder;

  /// Extra work to run alongside a pull-to-refresh (invalidating a sibling
  /// controller, say).
  final Future<void> Function()? onRefresh;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> refresh() async {
    await widget.onRefresh?.call();
    final next = widget.load();
    // The pull can still be in flight after the screen was popped — e.g. a
    // slow network reply landing after the user has already navigated away.
    // `setState` on a disposed State throws, and that throw is what actually
    // surfaces as "refreshda xatolik" rather than anything about the request
    // itself.
    if (!mounted) return;
    setState(() => _future = next);
    // Swallowed here so the refresh indicator always retracts; the
    // FutureBuilder below is the one place that renders the failure.
    try {
      await next;
    } catch (_) {
      // Rendered by the builder from the snapshot, not thrown at the gesture.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return ErrorView(
            message: error is ApiException ? error.message : s.somethingWentWrong,
            retryLabel: s.retry,
            onRetry: refresh,
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: widget.builder(context, snapshot.data as T, refresh),
        );
      },
    );
  }
}
