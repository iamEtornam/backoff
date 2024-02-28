import 'dart:math';

import 'package:backoff/backoff.dart';

Future<void> main() async {
  // Create an instance of ExponentialBackoff with custom parameters
  final backoff = ExponentialBackoff(
    initialInterval: Duration(milliseconds: 500),
    randomizationFactor: 0.5,
    multiplier: 2.0,
    maxInterval: Duration(seconds: 10),
    maxElapsedTime: Duration(minutes: 5),
  );

  // Define an asynchronous operation that might fail and needs retrying
  Future<void> asyncOperation() async {
    print('Attempting the operation...');
    if (Random().nextBool()) {
      throw Exception('Simulated failure');
    } else {
      print('Operation succeeded!');
    }
  }

  // Use the retry function to perform the operation with exponential backoff
  try {
    await retry(asyncOperation, backoff, waitCallback: (error, duration) {
      print('Operation failed: $error. Retrying in $duration...');
    });
    print('Operation completed successfully!');
  } catch (error) {
    print('Operation failed after retries: $error');
  }
}
