import 'dart:math';

class MockOtpUtility {
  MockOtpUtility._();

  static final Random _random = Random();

  static String generateOtp() {
    return _random.nextInt(1000000).toString().padLeft(6, '0');
  }
}
