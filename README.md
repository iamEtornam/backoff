
# Exponential Backoff [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/iamEtornam/backoff/graphs/commit-activity)

This is a Dart port of the exponential backoff algorithm from [Google's HTTP Client Library for Java][google-http-java-client].

[Exponential backoff][exponential backoff wiki] is an algorithm that uses feedback to multiplicatively decrease the rate of some process, in order to gradually find an acceptable rate. The retries exponentially increase and stop increasing when a certain threshold is met.

## Features

- Exponentially backoff operations
- Retries

## Getting started

Add the package to your codebase
```bash
dart pub add backoff
```

## Usage

### 1. Import the code

```dart
import 'package:backoff/backoff.dart';

```

### 2. Create an instance of ExponentialBackOff

```dart
ExponentialBackOff backOff = ExponentialBackOff();
```

You can customize the parameters during instantiation:
```dart
  final backoff = ExponentialBackOff(
    initialIntervalMillis: 100,
    randomizationFactor: 0.5,
    multiplier: 2.0,
    maxIntervalMillis: 10000,
    maxElapsedTimeMillis: 60000
  );
```

### 3. Use the backoff strategy in your retry logic

```dart
int backOffMillis = backOff.nextBackOffMillis();

if (backOffMillis == BackOff.STOP) {
  // Do not retry operation
} else {
  // Sleep for backOffMillis milliseconds and retry operation
  await Future.delayed(Duration(milliseconds: backOffMillis));
  // Retry operation here
}
```

### 4. Reset the backoff
If you want to reset the backoff to its initial state, you can use the reset method:

```dart
backOff.reset();
```

### 5. Additional Information
Available Properties
You can retrieve the values of various properties:

```dart
print("Initial Interval: ${backOff.getInitialIntervalMillis()} milliseconds");
print("Randomization Factor: ${backOff.getRandomizationFactor()}");
print("Current Interval: ${backOff.getCurrentIntervalMillis()} milliseconds");
print("Multiplier: ${backOff.getMultiplier()}");
print("Max Interval: ${backOff.getMaxIntervalMillis()} milliseconds");
print("Max Elapsed Time: ${backOff.getMaxElapsedTimeMillis()} milliseconds");
```
Elapsed Time
If you want to know the elapsed time since the backoff started:
```dart
int elapsedMillis = backOff.getElapsedTimeMillis();
print("Elapsed Time: $elapsedMillis milliseconds");
```

### Constants
The BackOff class provides two constants for special cases:

- `BackOff.ZERO_BACKOFF`: A fixed backoff policy with zero wait time.
- `BackOff.STOP_BACKOFF`: A fixed backoff policy that always returns `BackOff.STOP`, indicating that the operation should not be retried.
- 
These can be used when you have specific requirements for immediate retries or no retries.


## Contributing

- I would like to keep this library as small as possible.
- Please don't send a PR without opening an issue and discussing it first.
- If proposed change is not a common use case, I will probably not accept it.

[google-http-java-client]: https://github.com/google/google-http-java-client/blob/da1aa993e90285ec18579f1553339b00e19b3ab5/google-http-client/src/main/java/com/google/api/client/util/ExponentialBackOff.java
[exponential backoff wiki]: http://en.wikipedia.org/wiki/Exponential_backoff