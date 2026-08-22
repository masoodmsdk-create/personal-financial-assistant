abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code});
}

class CalculationException extends AppException {
  const CalculationException(super.message, {super.code});
}
