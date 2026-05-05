Future<void> downloadFileBytes(
  List<int> bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) async {
  throw UnsupportedError('Browser file download is only available on web.');
}
