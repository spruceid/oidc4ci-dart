library oidc4ci;

import "dart:convert";
import "ffi.dart";

export "ffi.dart" show OIDC4CIException;

class OIDC4CI {
  static Future<String?> getVersion() async {
    return OIDC4CIFFI.getVersion();
  }

  static Future<String?> generateTokenRequest(Map<String, dynamic> params) async {
    final paramsStr = jsonEncode(params);
    final tokenRequest = OIDC4CIFFI.generateTokenRequest(paramsStr);
    return tokenRequest;
  }

  static Future<String?> generateCredentialRequest(
    String type,
    String format,
    String issuer,
    String audience,
    String jwk,
    String alg,
  ) async {
    final credentialRequest = OIDC4CIFFI.generateCredentialRequest(
      type,
      format,
      issuer,
      audience,
      jwk,
      alg,
    );
    return credentialRequest;
  }
}
