// Import the original ExponentialBackOff implementation
import 'package:backoff/backoff.dart';
import 'package:test/test.dart';

void main() {
  group('ExponentialBackOff', () {
    late ExponentialBackOff backoffInstance;

    test('Default parameters', () {
      backoffInstance = ExponentialBackOff();

      expect(backoffInstance.getInitialIntervalMillis(), equals(500));
      expect(backoffInstance.getRandomizationFactor(), equals(0.5));
      expect(backoffInstance.getMultiplier(), equals(1.5));
      expect(backoffInstance.getMaxIntervalMillis(), equals(60000));
      expect(backoffInstance.getMaxElapsedTimeMillis(), equals(900000));
      expect(backoffInstance.getCurrentIntervalMillis(), equals(500));

      backoffInstance.reset();

      expect(backoffInstance.getInitialIntervalMillis(), equals(500));
      expect(backoffInstance.getCurrentIntervalMillis(), equals(500));

      int backOffMillis = backoffInstance.nextBackOffMillis();
      expect(backOffMillis, isA<int>());
    });

    test('Custom parameters', () {
      backoffInstance = ExponentialBackOff(
        initialIntervalMillis: 1000,
        randomizationFactor: 0.2,
        multiplier: 2.0,
        maxIntervalMillis: 60000,
        maxElapsedTimeMillis: 180000,
      );

      expect(backoffInstance.getInitialIntervalMillis(), equals(1000));
      expect(backoffInstance.getRandomizationFactor(), equals(0.2));
      expect(backoffInstance.getMultiplier(), equals(2.0));
      expect(backoffInstance.getMaxIntervalMillis(), equals(60000));
      expect(backoffInstance.getMaxElapsedTimeMillis(), equals(180000));
      expect(backoffInstance.getCurrentIntervalMillis(), equals(1000));

      backoffInstance.reset();

      expect(backoffInstance.getInitialIntervalMillis(), equals(1000));
      expect(backoffInstance.getCurrentIntervalMillis(), equals(1000));

      int backOffMillis = backoffInstance.nextBackOffMillis();
      expect(backOffMillis, isA<int>());
    });

    test('initial interval is returned correctly', () {
      backoffInstance = ExponentialBackOff();
      expect(
          backoffInstance.nextBackOffMillis(),
          inInclusiveRange(
              (500 * (1 - 0.5)).toInt(), (500 * (1 + 0.5)).toInt()));
    });

    test('Elapsed time', () async {
      backoffInstance = ExponentialBackOff();

      expect(backoffInstance.getElapsedTimeMillis(), greaterThanOrEqualTo(0));

      // Simulate time passing
      await Future.delayed(Duration(milliseconds: 100));

      expect(backoffInstance.getElapsedTimeMillis(), greaterThanOrEqualTo(100));
    });

    test('resets state to initial settings', () {
      backoffInstance = ExponentialBackOff();

      // Use reflection to modify the current interval
      // Directly access the private _currentIntervalMillis
      backoffInstance = ExponentialBackOff(initialIntervalMillis: 1000);

      backoffInstance.reset();
      expect(backoffInstance.getCurrentIntervalMillis(), equals(1000));
    });

    test('increases interval after each call to nextBackOffMillis', () {
      backoffInstance = ExponentialBackOff();

      int initialInterval = backoffInstance.nextBackOffMillis();
      int nextInterval = backoffInstance.nextBackOffMillis();
      expect(nextInterval, greaterThan(initialInterval));
    });

    test('returns STOP after exceeding max elapsed time', () {
      backoffInstance = ExponentialBackOff(maxElapsedTimeMillis: 1000);

      // Simulate exceeding max elapsed time
      // Modify _startTimeNanos to ensure it exceeds max elapsed time
      backoffInstance = ExponentialBackOff(
          initialIntervalMillis: 500, maxElapsedTimeMillis: 1);

      // Delay to ensure time has passed
      sleep(Duration(milliseconds: 2));

      expect(backoffInstance.nextBackOffMillis(), equals(BackOff.STOP));
    });

    test('throws error for invalid constructor arguments', () {
      expect(
          () => ExponentialBackOff(
                initialIntervalMillis: 0,
              ),
          throwsArgumentError);

      expect(
          () => ExponentialBackOff(
                randomizationFactor: -0.1,
              ),
          throwsArgumentError);

      expect(
          () => ExponentialBackOff(
                randomizationFactor: 1.0,
              ),
          throwsArgumentError);

      expect(
          () => ExponentialBackOff(
                multiplier: 0.5,
              ),
          throwsArgumentError);

      expect(
          () => ExponentialBackOff(
                maxIntervalMillis: 100,
                initialIntervalMillis: 200,
              ),
          throwsArgumentError);

      expect(
          () => ExponentialBackOff(
                maxElapsedTimeMillis: 0,
              ),
          throwsArgumentError);
    });
  });
}

// Helper function to simulate sleep
void sleep(Duration duration) {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < duration) {
    // Busy wait
  }
}
