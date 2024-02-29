import 'package:backoff/backoff.dart' as backoff;
import 'package:test/test.dart';

void main() {
  group('ExponentialBackOff', () {
    late backoff.ExponentialBackOff backoffInstance;
    test('Default parameters', () {
      backoffInstance = backoff.ExponentialBackOff();

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
      backoffInstance = backoff.ExponentialBackOff(
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
      backoffInstance = backoff.ExponentialBackOff();
      expect(backoffInstance.nextBackOffMillis(),
          backoff.ExponentialBackOff.DEFAULT_INITIAL_INTERVAL_MILLIS);
    });

    test('Elapsed time', () {
      backoffInstance = backoff.ExponentialBackOff();

      expect(backoffInstance.getElapsedTimeMillis(), greaterThanOrEqualTo(0));

      // Simulate time passing
      Future.delayed(Duration(milliseconds: 100));

      expect(backoffInstance.getElapsedTimeMillis(), greaterThanOrEqualTo(100));
    });

    test('resets state to initial settings', () {
      backoffInstance = backoff.ExponentialBackOff();

      backoffInstance.currentIntervalMillis = 1000;
      backoffInstance.reset();
      expect(backoffInstance.currentIntervalMillis,
          backoff.ExponentialBackOff.DEFAULT_INITIAL_INTERVAL_MILLIS);
    });

    test('increases interval after each call to nextBackOffMillis', () {
      backoffInstance = backoff.ExponentialBackOff();

      int initialInterval = backoffInstance.nextBackOffMillis();
      int nextInterval = backoffInstance.nextBackOffMillis();
      expect(nextInterval, greaterThan(initialInterval));
    });

    test('returns STOP after exceeding max elapsed time', () {
      backoffInstance = backoff.ExponentialBackOff();

      // Mock elapsed time to be greater than max allowed time
      backoffInstance.startTimeNanos = DateTime.now().microsecondsSinceEpoch -
          (backoff.ExponentialBackOff.DEFAULT_MAX_ELAPSED_TIME_MILLIS + 1) *
              1000;
      expect(backoffInstance.nextBackOffMillis(), backoff.BackOff.STOP);
    });

    test('throws error for invalid constructor arguments', () {
      backoffInstance = backoff.ExponentialBackOff();

      expect(
          () => backoff.ExponentialBackOff(
                initialIntervalMillis: 0,
              ),
          throwsArgumentError);

      expect(
          () => backoff.ExponentialBackOff(
                randomizationFactor: -0.1,
              ),
          throwsArgumentError);

      expect(
          () => backoff.ExponentialBackOff(
                multiplier: 0.5,
              ),
          throwsArgumentError);

      expect(
          () => backoff.ExponentialBackOff(
                maxIntervalMillis: 100,
                initialIntervalMillis: 200,
              ),
          throwsArgumentError);

      expect(
          () => backoff.ExponentialBackOff(
                maxElapsedTimeMillis: 0,
              ),
          throwsArgumentError);
    });
  });
}
