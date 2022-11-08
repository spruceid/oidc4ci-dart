import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

final DynamicLibrary lib = Platform.isAndroid || Platform.isLinux
    ? DynamicLibrary.open('liboidc4ci.so')
    : Platform.isMacOS
        ? DynamicLibrary.open('liboidc4ci.dylib')
        : DynamicLibrary.process();

final get_version =
    lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
        'oidc4ci_get_version');

final get_error_message =
    lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
        'oidc4ci_error_message');

final get_error_code =
    lib.lookupFunction<Int32 Function(), int Function()>('oidc4ci_error_code');

final free_string = lib.lookupFunction<Void Function(Pointer<Utf8>),
    void Function(Pointer<Utf8>)>('oidc4ci_free_string');

final generate_token_request = lib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('oidc4ci_generate_token_request');

final generate_credential_request = lib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>,
        Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>,
        Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>('oidc4ci_generate_credential_request');

class OIDC4CIException implements Exception {
  int code;
  String message;

  OIDC4CIException(this.code, this.message);

  @override
  String toString() {
    return 'OIDC4CIException ($code): $message';
  }
}

OIDC4CIException lastError() {
  final code = get_error_code();
  final message_utf8 = get_error_message();
  final message_string = message_utf8.address == nullptr.address
      ? 'Unable to get error message'
      : message_utf8.toDartString();

  return OIDC4CIException(code, message_string);
}

class OIDC4CIFFI {
  static String getVersion() {
    return get_version().toDartString();
  }

  static String generateTokenRequest(String params) {
    final result = generate_token_request(params.toNativeUtf8());
    if (result.address == nullptr.address) throw lastError();
    final resultStr = result.toDartString();
    free_string(result);
    return resultStr;
  }

  static String generateCredentialRequest(
    String type,
    String format,
    String issuer,
    String audience,
    String jwk,
    String alg,
  ) {
    final result = generate_credential_request(
      type.toNativeUtf8(),
      format.toNativeUtf8(),
      issuer.toNativeUtf8(),
      audience.toNativeUtf8(),
      jwk.toNativeUtf8(),
      alg.toNativeUtf8(),
    );
    if (result.address == nullptr.address) throw lastError();
    final resultStr = result.toDartString();
    free_string(result);
    return resultStr;
  }
}
