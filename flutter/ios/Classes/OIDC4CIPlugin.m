#import "OIDC4CIPlugin.h"

#import "oidc4ci.h"

@implementation mDLPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
}
+ (void)dummyMethodToEnforceFunctionsDontGetOptmized {
  // Here we MUST call all functions from oidc4ci.h so that they don't get
  // optimized and removed from release builds.
  oidc4ci_get_version();
  oidc4ci_error_code();
  oidc4ci_error_message();
  oidc4ci_free_string(NULL);

  oidc4ci_generate_token_request(NULL);
  oidc4ci_generate_credential_request(NULL, NULL, NULL, NULL, NULL, NULL);
}
@end
