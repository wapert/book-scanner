/// A single scanned page: the photo (Firebase Storage URL or legacy local
/// path) plus the OCR-extracted, user-editable text.
class PageItem {
  String photoUrl;
  String text;

  PageItem({required this.photoUrl, this.text = ''});

  bool get isRemote => photoUrl.startsWith('http');
  bool get hasText => text.trim().isNotEmpty;

  factory PageItem.fromJson(Map<String, dynamic> j) => PageItem(
        photoUrl: (j['photoUrl'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'photoUrl': photoUrl,
        'text': text,
      };
}
