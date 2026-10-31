import 'package:flutter_test/flutter_test.dart';
import 'package:groundnut_disease_app/utils/text_search.dart';

void main() {
  test('folding strips Vietnamese marks and case', () {
    expect(foldVietnamese('Ruộng Sau Nhà'), 'ruong sau nha');
    expect(foldVietnamese('ĐỐM LÁ'), 'dom la');
    expect(foldVietnamese('Bệnh gỉ sắt'), 'benh gi sat');
  });

  test('query matches without marks, word order free', () {
    expect(matchesQuery('Ruộng sau nhà, luống 3', 'ruong luong 3'), isTrue);
    expect(matchesQuery('Ruộng sau nhà, luống 3', 'nhà ruộng'), isTrue);
    expect(matchesQuery('Ruộng sau nhà', 'ruong truoc'), isFalse);
  });

  test('empty query matches everything', () {
    expect(matchesQuery('bất kỳ', ''), isTrue);
    expect(matchesQuery('bất kỳ', '   '), isTrue);
  });
}
