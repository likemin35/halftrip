import 'browser_file_download_stub.dart'
    if (dart.library.html) 'browser_file_download_web.dart' as impl;

Future<void> downloadFileBytes(
  List<int> bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) {
  return impl.downloadFileBytes(bytes, fileName, mimeType: mimeType);
}
