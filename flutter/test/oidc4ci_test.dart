import 'package:flutter_test/flutter_test.dart';
import 'package:oidc4ci/oidc4ci.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getVersion', () async {
    expect(await OIDC4CI.getVersion(), isInstanceOf<String>());
  });
}
