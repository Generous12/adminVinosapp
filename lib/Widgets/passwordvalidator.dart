class PasswordValidator {
  bool hasMinLength = false;
  bool hasLowercase = false;
  bool hasUppercase = false;
  bool hasNumber = false;

  bool arePasswordsEqual(String password, String repeatPassword) {
    return password == repeatPassword;
  }

  void checkPasswordRequirements(String password) {
    hasMinLength = password.length >= 8;
    hasLowercase = password.contains(RegExp(r'[a-z]'));
    hasUppercase = password.contains(RegExp(r'[A-Z]'));
    hasNumber = password.contains(RegExp(r'[0-9]'));
  }
}
