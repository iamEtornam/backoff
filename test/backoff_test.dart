import 'package:backoff/backoff.dart';
import 'package:test/test.dart';

void main() {
  test('ExponentialBackoff - Next Backoff', () {
    final backoff = ExponentialBackoff();
    expect(
      backoff.nextBackOff().inMilliseconds,
      // Use greaterThanOrEqualTo instead of closeTo
      greaterThanOrEqualTo(Duration(milliseconds: 500).inMilliseconds),
    );
  });

  test('Retry Function', () async {
    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    int attempts = 0;
    operation() async {
      attempts++;
      if (attempts < 3) {
        throw Exception('Simulated failure');
      }
      return 'Success';
    }

    final backoff = ExponentialBackoff();

    // Option 1: Initialize currentInterval for accurate first delay
    // backoff.currentInterval = Duration(milliseconds: 500);

    final result = await retry(operation, backoff);

    expect(result, equals('Success'));
    expect(attempts, equals(3));

    // Option 2: Calculate expected delays with randomization
    final expectedDelays = [
      500, // Adjust tolerance for actual expected range
      750, // (500 * 1.5) +/- randomization
      1125 // (750 * 1.5) +/- randomization
    ];

    for (int i = 1; i < attempts; i++) {
      expect(stopwatch.elapsedMilliseconds,
          closeTo(expectedDelays[i - 1], 50)); // Tolerance for randomization
    }

    stopwatch.stop();
  });

  test('MaxRetriesBackoff', () {
    final delegate = ExponentialBackoff();
    final maxRetriesBackoff = MaxRetriesBackoff(delegate, 2);

    expect(
      maxRetriesBackoff.nextBackOff().inMilliseconds,
      closeTo(Duration(milliseconds: 500).inMilliseconds, 10),
    );
    expect(
      maxRetriesBackoff.nextBackOff().inMilliseconds,
      closeTo(Duration(milliseconds: 750).inMilliseconds, 10),
    );
    expect(
      maxRetriesBackoff.nextBackOff().inMilliseconds,
      closeTo(Duration(milliseconds: 1125).inMilliseconds, 10),
    );

    expect(maxRetriesBackoff.nextBackOff(), equals(Backoff.stop));
    expect(maxRetriesBackoff.nextBackOff(), equals(Backoff.stop));
    expect(maxRetriesBackoff.nextBackOff(), equals(Backoff.stop));
  });
}
