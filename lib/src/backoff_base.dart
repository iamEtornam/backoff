import 'dart:math' as math;

/// Provides an exponential backoff strategy with configurable parameters
/// for implementing retry mechanisms with controlled randomization.
class ExponentialBackOff {
  // Default configuration constants
  static const int _kDefaultInitialIntervalMillis = 500;
  static const double _kDefaultRandomizationFactor = 0.5;
  static const double _kDefaultMultiplier = 1.5;
  static const int _kDefaultMaxIntervalMillis = 60000;
  static const int _kDefaultMaxElapsedTimeMillis = 900000;

  /// Initial interval between retry attempts
  final int initialIntervalMillis;

  /// Factor used to add randomness to the interval
  final double randomizationFactor;

  /// Multiplier to increase interval between attempts
  final double multiplier;

  /// Maximum allowed interval between retry attempts
  final int maxIntervalMillis;

  /// Maximum total time allowed for retry attempts
  final int maxElapsedTimeMillis;

  /// Random number generator for interval randomization
  final math.Random _random = math.Random();

  /// Current interval between retry attempts
  late int _currentIntervalMillis;

  /// Timestamp of when the backoff strategy was started or reset
  int _startTimeNanos = DateTime.now().microsecondsSinceEpoch;

  /// Number of retry attempts made
  int _retryCount = 0;

  /// Constructs an ExponentialBackOff with configurable parameters
  ///
  /// Throws [ArgumentError] for invalid input parameters
  ExponentialBackOff({
    int? initialIntervalMillis,
    double? randomizationFactor,
    double? multiplier,
    int? maxIntervalMillis,
    int? maxElapsedTimeMillis,
  })  : initialIntervalMillis =
            initialIntervalMillis ?? _kDefaultInitialIntervalMillis,
        randomizationFactor =
            randomizationFactor ?? _kDefaultRandomizationFactor,
        multiplier = multiplier ?? _kDefaultMultiplier,
        maxIntervalMillis = maxIntervalMillis ?? _kDefaultMaxIntervalMillis,
        maxElapsedTimeMillis =
            maxElapsedTimeMillis ?? _kDefaultMaxElapsedTimeMillis {
    _validateParameters();
    _currentIntervalMillis = this.initialIntervalMillis;
  }

  /// Validates the input parameters
  void _validateParameters() {
    if (initialIntervalMillis <= 0) {
      throw ArgumentError(
          'Initial interval must be a positive number of milliseconds');
    }
    if (randomizationFactor < 0 || randomizationFactor >= 1) {
      throw ArgumentError(
          'Randomization factor must be between 0 (inclusive) and 1 (exclusive)');
    }
    if (multiplier < 1) {
      throw ArgumentError('Multiplier must be greater than or equal to 1');
    }
    if (maxIntervalMillis < initialIntervalMillis) {
      throw ArgumentError(
          'Maximum interval must be greater than or equal to initial interval');
    }
    if (maxElapsedTimeMillis <= 0) {
      throw ArgumentError(
          'Maximum elapsed time must be a positive number of milliseconds');
    }
  }

  /// Resets the backoff strategy to its initial state
  void reset() {
    _currentIntervalMillis = initialIntervalMillis;
    _startTimeNanos = DateTime.now().microsecondsSinceEpoch;
    _retryCount = 0;
  }

  /// Calculates the next backoff interval
  ///
  /// Returns the number of milliseconds to wait before the next retry,
  /// or [BackOff.STOP] if maximum retry time has been exceeded
  ///
  /// Example usage:
  ///
  /// ```dart
  /// long backOffMillis = backoff.nextBackOffMillis();
  /// if (backOffMillis == Backoff.STOP) {
  ///   // do not retry operation
  /// } else {
  ///   // sleep for backOffMillis milliseconds and retry operation
  /// }
  /// ```
  int nextBackOffMillis() {
    // Check if maximum elapsed time has been reached
    if (getElapsedTimeMillis() > maxElapsedTimeMillis) {
      return BackOff.STOP;
    }

    // Calculate randomized interval
    int randomizedInterval = _getRandomizedInterval();

    // Increment retry tracking
    _retryCount++;

    // Prepare for next attempt by updating current interval
    _incrementCurrentInterval();

    return randomizedInterval;
  }

  /// Generates a randomized interval with controlled jitter
  int _getRandomizedInterval() {
    // Optimized randomization approach
    final delta = (_currentIntervalMillis * randomizationFactor).toInt();
    return _currentIntervalMillis + _random.nextInt(2 * delta + 1) - delta;
  }

  /// Increments the current interval, respecting the maximum interval
  void _incrementCurrentInterval() {
    if (_currentIntervalMillis >= maxIntervalMillis / multiplier) {
      _currentIntervalMillis = maxIntervalMillis;
    } else {
      _currentIntervalMillis =
          (_currentIntervalMillis * multiplier).ceil().toInt();
    }
  }

  /// Calculates the elapsed time since the backoff strategy started
  int getElapsedTimeMillis() {
    return (DateTime.now().microsecondsSinceEpoch - _startTimeNanos) ~/ 1000;
  }

  /// Retrieves the current retry count
  int getRetryCount() => _retryCount;

  // Getter methods for configuration parameters
  int getCurrentIntervalMillis() => _currentIntervalMillis;
  int getInitialIntervalMillis() => initialIntervalMillis;
  double getRandomizationFactor() => randomizationFactor;
  double getMultiplier() => multiplier;
  int getMaxIntervalMillis() => maxIntervalMillis;
  int getMaxElapsedTimeMillis() => maxElapsedTimeMillis;
}

/// Abstract interface for backoff strategies
abstract class BackOff {
  /// Constant indicating no more retry attempts should be made
  static const int STOP = -1;

  /// Resets the backoff strategy to its initial state
  void reset();

  /// Calculates the next backoff interval
  ///
  /// Returns the number of milliseconds to wait before the next retry,
  /// or [STOP] to indicate no more retry attempts
  int nextBackOffMillis();

  /// A backoff strategy with zero wait time between retries
  static final BackOff zeroBackoff = _ZeroBackOff();

  /// A backoff strategy that immediately stops retry attempts
  static final BackOff stopBackoff = _StopBackOff();
}

/// Implementation of a zero-wait backoff strategy
class _ZeroBackOff implements BackOff {
  @override
  void reset() {}

  @override
  int nextBackOffMillis() => 0;
}

/// Implementation of a stop backoff strategy
class _StopBackOff implements BackOff {
  @override
  void reset() {}

  @override
  int nextBackOffMillis() => BackOff.STOP;
}
