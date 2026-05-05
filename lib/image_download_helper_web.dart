import 'dart:html' as html;

Future<String?> downloadNetworkImageImpl(
  String imageUrl, {
  String? fileName,
}) async {
  final anchor = html.AnchorElement(href: imageUrl)
    ..setAttribute('download', fileName ?? 'post_image')
    ..target = '_blank';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  return 'web_download_started';
}
