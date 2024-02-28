import 'dart:async';
import 'dart:math';

// Abstract Backoff interface for flexibility
abstract class Backoff {
  Duration nextBackOff();
  void reset();

  // Optional stop value for consistency
  static const stop = Duration.zero;
}

// ExponentialBackoff implementation with configurable options
class ExponentialBackoff implements Backoff {
  final Duration initialInterval;
  final double randomizationFactor;
  final double multiplier;
  final Duration maxInterval;
  final Duration maxElapsedTime;

  late Duration currentInterval;
  late DateTime startTime;

  ExponentialBackoff({
    this.initialInterval = const Duration(milliseconds: 500),
    this.randomizationFactor = 0.5,
    this.multiplier = 1.5,
    this.maxInterval = const Duration(seconds: 60),
    this.maxElapsedTime = const Duration(minutes: 15),
  }) {
    reset();
  }

  @override
  Duration nextBackOff() {
    final elapsed = getElapsedTime();
    final calculatedInterval = getRandomizedInterval();
    incrementCurrentInterval();

    if (maxElapsedTime != Duration.zero &&
        elapsed + calculatedInterval > maxElapsedTime) {
      return Backoff.stop;
    }
    return calculatedInterval;
  }

  @override
  void reset() {
    currentInterval = initialInterval;
    startTime = DateTime.now();
  }

  // Calculates elapsed time since creation
  Duration getElapsedTime() => DateTime.now().difference(startTime);

  // Increases current interval with capping for efficiency
  void incrementCurrentInterval() {
    final nextInterval = currentInterval * multiplier;
    currentInterval =
        nextInterval.compareTo(maxInterval) <= 0 ? nextInterval : maxInterval;
  }

  // Generates a random interval within the specified range
  Duration getRandomizedInterval() {
    if (randomizationFactor == 0) {
      return currentInterval;
    }

    final delta = currentInterval * randomizationFactor;
    final minInterval = currentInterval - delta;
    final maxInterval = currentInterval + delta;
    final random = Random().nextDouble();

    // Ensure inclusive range with accurate distribution
    return minInterval +
        Duration(
            milliseconds:
                (random * (maxInterval - minInterval).inMilliseconds).round());
  }
}

// Retry function with optional wait callback
Future<T> retry<T>(
  FutureOr<T> Function() operation,
  Backoff backoff, {
  void Function(Object error, Duration duration)? waitCallback,
}) async {
  try {
    for (;;) {
      final result = await operation();
      return result;
    }
  } catch (error) {
    if (waitCallback != null) {
      waitCallback(error, backoff.nextBackOff());
    }
    await Future.delayed(backoff.nextBackOff());
    rethrow;
  }
}

// Retry with data function (suitable for operations returning data)
Future<T> retryWithData<T>(
  FutureOr<T> Function() operation,
  Backoff backoff, {
  void Function(Object error, Duration duration)? waitCallback,
}) async {
  try {
    for (;;) {
      final result = await operation();
      return result;
    }
  } catch (error) {
    if (waitCallback != null) {
      waitCallback(error, backoff.nextBackOff());
    }
    await Future.delayed(backoff.nextBackOff());
    rethrow;
  }
}

// MaxRetriesBackoff limits retries with stop signal (optional)
class MaxRetriesBackoff implements Backoff {
  final Backoff _delegate;
  final int _maxTries;
  int _currentTries = 0;

  MaxRetriesBackoff(this._delegate, this._maxTries);

  @override
  Duration nextBackOff() {
    if (_maxTries == 0) {
      return Backoff.stop;
    }

    if (_currentTries >= _maxTries) {
      return Backoff.stop;
    }

    _currentTries++;
    return _delegate.nextBackOff();
  }

  @override
  void reset() {
    _currentTries = 0;
    _delegate.reset();
  }
}
