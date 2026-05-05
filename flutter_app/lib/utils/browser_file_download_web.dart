import 'dart:html' as html;

Future<void> downloadFileBytes(
  List<int> bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) async {
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
