import 'dart:math'
    as math; // Import the math library for random number generation

class ExponentialBackOff {
 // Define default values for constructor parameters
  static const int DEFAULT_INITIAL_INTERVAL_MILLIS = 500;
  static const double DEFAULT_RANDOMIZATION_FACTOR = 0.5;
  static const double DEFAULT_MULTIPLIER = 1.5;
  static const int DEFAULT_MAX_INTERVAL_MILLIS = 60000;
  static const int DEFAULT_MAX_ELAPSED_TIME_MILLIS = 900000;

  final int initialIntervalMillis;
  final double randomizationFactor;
  final double multiplier;
  final int maxIntervalMillis;
  final int maxElapsedTimeMillis;
  final math.Random random =
      math.Random(); // Use random object from math library

  late int currentIntervalMillis;
  int startTimeNanos = DateTime.now()
      .microsecondsSinceEpoch; // Use microseconds for better precision

  ExponentialBackOff({
    this.initialIntervalMillis = DEFAULT_INITIAL_INTERVAL_MILLIS,
    this.randomizationFactor = DEFAULT_RANDOMIZATION_FACTOR,
    this.multiplier = DEFAULT_MULTIPLIER,
    this.maxIntervalMillis = DEFAULT_MAX_INTERVAL_MILLIS,
    this.maxElapsedTimeMillis = DEFAULT_MAX_ELAPSED_TIME_MILLIS,
  }) {
    currentIntervalMillis = initialIntervalMillis;
    if (initialIntervalMillis <= 0) {
      throw ArgumentError('initialIntervalMillis must be greater than 0');
    }
    if (randomizationFactor < 0 || randomizationFactor >= 1) {
      throw ArgumentError(
          'randomizationFactor must be between 0 (inclusive) and 1 (exclusive)');
    }
    if (multiplier < 1) {
      throw ArgumentError('multiplier must be greater than or equal to 1');
    }
    if (maxIntervalMillis < initialIntervalMillis) {
      throw ArgumentError(
          'maxIntervalMillis must be greater than or equal to initialIntervalMillis');
    }
    if (maxElapsedTimeMillis <= 0) {
      throw ArgumentError('maxElapsedTimeMillis must be greater than 0');
    }
  }

  void reset() {
    currentIntervalMillis = initialIntervalMillis;
    startTimeNanos = DateTime.now().microsecondsSinceEpoch;
  }

  int nextBackOffMillis() {
    if (getElapsedTimeMillis() > maxElapsedTimeMillis) {
      return BackOff.STOP; // Use the constant value from BackOff interface
    }

    int randomizedInterval =
        getRandomValueFromInterval(randomizationFactor, currentIntervalMillis);
    incrementCurrentInterval();
    return randomizedInterval;
  }

  int getRandomValueFromInterval(
      double randomizationFactor, int currentInterval) {
    double delta = randomizationFactor * currentInterval;
    double minInterval = currentInterval - delta;
    double maxInterval = currentInterval + delta;
    // Use double.ceil() to ensure the value is always rounded up
    return (minInterval + random.nextDouble() * (maxInterval - minInterval + 1))
        .ceil()
        .toInt();
  }

  int getInitialIntervalMillis() => initialIntervalMillis;
  double getRandomizationFactor() => randomizationFactor;
  int getCurrentIntervalMillis() => currentIntervalMillis;
  double getMultiplier() => multiplier;
  int getMaxIntervalMillis() => maxIntervalMillis;
  int getMaxElapsedTimeMillis() => maxElapsedTimeMillis;

  int getElapsedTimeMillis() {
    return (DateTime.now().microsecondsSinceEpoch - startTimeNanos) ~/ 1000;
  }

  void incrementCurrentInterval() {
    if (currentIntervalMillis >= maxIntervalMillis / multiplier) {
      currentIntervalMillis = maxIntervalMillis;
    } else {
      currentIntervalMillis =
          (currentIntervalMillis * multiplier).ceil().toInt();
    }
  }
}

abstract class BackOff {
  static const int STOP = -1;

  void reset();

  /// Gets the number of milliseconds to wait before retrying the operation or [STOP] to
  /// indicate that no retries should be made.
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
  int nextBackOffMillis();

  /// Fixed back-off policy whose back-off time is always zero, meaning that the operation is retried
  /// immediately without waiting.
  static final BackOff ZERO_BACKOFF = _ZeroBackOff();

  /// Fixed back-off policy that always returns [STOP] for [nextBackOffMillis()],
  /// meaning that the operation should not be retried.
  static final BackOff STOP_BACKOFF = _StopBackOff();
}

class _ZeroBackOff implements BackOff {
  @override
  void reset() {}

  @override
  int nextBackOffMillis() {
    return 0;
  }
}

class _StopBackOff implements BackOff {
  @override
  void reset() {}

  @override
  int nextBackOffMillis() {
    return BackOff.STOP;
  }
}
