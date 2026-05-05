import 'image_download_helper_stub.dart'
    if (dart.library.io) 'image_download_helper_io.dart'
    if (dart.library.html) 'image_download_helper_web.dart';

Future<String?> downloadNetworkImage(
  String imageUrl, {
  String? fileName,
}) {
  return downloadNetworkImageImpl(imageUrl, fileName: fileName);
}
