import 'dart:math';

import 'package:backoff/backoff.dart';

Future<void> main() async {
  final backoff = ExponentialBackOff(); // Use default parameters

  ///** You can customize the parameters during instantiation:
  ///ExponentialBackOff customBackOff = ExponentialBackOff(
  ///   initialIntervalMillis: 1000,
  ///   randomizationFactor: 0.2,
  ///   multiplier: 2.0,
  ///   maxIntervalMillis: 60000,
  ///   maxElapsedTimeMillis: 180000,
  /// ); */
  ///
  ///

  // Define an asynchronous operation that might fail and needs retrying
  Future<void> asyncOperation() async {
    print('Attempting the operation...');
    if (Random().nextBool()) {
      throw Exception('Simulated failure');
    } else {
      print('Operation succeeded!');
    }
  }

  int backOffMillis = backoff.nextBackOffMillis();

  if (backOffMillis == BackOff.STOP) {
    // Do not retry operation
  } else {
    // Sleep for backOffMillis milliseconds and retry operation
    await Future.delayed(Duration(milliseconds: backOffMillis));
    // Retry operation here
    await asyncOperation();
  }

  print("Initial Interval: ${backoff.getInitialIntervalMillis()} milliseconds");
  print("Randomization Factor: ${backoff.getRandomizationFactor()}");
  print("Current Interval: ${backoff.getCurrentIntervalMillis()} milliseconds");
  print("Multiplier: ${backoff.getMultiplier()}");
  print("Max Interval: ${backoff.getMaxIntervalMillis()} milliseconds");
  print("Max Elapsed Time: ${backoff.getMaxElapsedTimeMillis()} milliseconds");
}
