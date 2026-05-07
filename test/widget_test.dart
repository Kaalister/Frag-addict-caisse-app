import 'package:frags_addicts_caisse/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money formats French euro display', () {
    expect(money(12.5), '12,50 €');
  });
}
