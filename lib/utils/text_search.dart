const String _withMarks =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const String _withoutMarks =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Lower-cases [s] and strips Vietnamese diacritics, so "ruong sau nha"
/// matches "Ruộng sau nhà" — many users type without marks.
String foldVietnamese(String s) {
  final String lower = s.toLowerCase();
  final StringBuffer sb = StringBuffer();
  for (final int rune in lower.runes) {
    final String ch = String.fromCharCode(rune);
    final int i = _withMarks.indexOf(ch);
    sb.write(i < 0 ? ch : _withoutMarks[i]);
  }
  return sb.toString();
}

/// True if every whitespace-separated word of [query] appears in [text],
/// ignoring case and diacritics. An empty query matches everything.
bool matchesQuery(String text, String query) {
  final String haystack = foldVietnamese(text);
  return foldVietnamese(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).every(haystack.contains);
}
