import 'package:flutter_test/flutter_test.dart';
import 'package:gryph_market/services/auth_service.dart';

void main() {
  test('only accepts University of Guelph email addresses', () {
    expect(AuthService.isUofGuelphEmail('student@uoguelph.ca'), isTrue);
    expect(AuthService.isUofGuelphEmail('student@gmail.com'), isFalse);
    expect(AuthService.isUofGuelphEmail('fake@uoguelph.ca.example.com'), isFalse);
  });

  test('enforces the password policy', () {
    expect(AuthService.passwordError('Weak123'), isNotNull);
    expect(AuthService.passwordError('StrongPass1!'), isNull);
  });
}
