class LoginRequest {
  const LoginRequest({required this.phoneNumber, required this.password});

  final String phoneNumber;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'phone': phoneNumber, 'password': password};
  }

  Map<String, dynamic> toAlternateJson() {
    return <String, dynamic>{'phone': phoneNumber, 'password': password};
  }
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.password,
  });

  final String fullName;
  final String phoneNumber;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': fullName,
      'phone': phoneNumber,
      'password': password,
    };
  }

  Map<String, dynamic> toAlternateJson() {
    return toJson();
  }
}
