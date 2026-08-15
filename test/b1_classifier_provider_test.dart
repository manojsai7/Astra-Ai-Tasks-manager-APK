import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astra/providers/b1_classifier_provider.dart';

void main() {
  test(
    'B1 provider can be constructed and read in ProviderContainer',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(b1EventClassifierProvider);
      expect(client, isNotNull);
    },
  );
}
