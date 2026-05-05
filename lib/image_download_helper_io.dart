import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<String?> downloadNetworkImageImpl(
  String imageUrl, {
  String? fileName,
}) async {
  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
    throw Exception('Failed to download image.');
  }

  Directory? directory;
  try {
    directory = await getDownloadsDirectory();
  } catch (_) {
    directory = null;
  }

  directory ??= await getApplicationDocumentsDirectory();

  final resolvedFileName = _resolveFileName(imageUrl, fileName);
  final safeFileName = resolvedFileName.replaceAll(RegExp(r'[<>:"\\/\|\?\*]'), '_');

  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final file = File('${directory.path}${Platform.pathSeparator}$safeFileName');
  await file.writeAsBytes(response.bodyBytes, flush: true);
  return file.path;
}

String _resolveFileName(String imageUrl, String? fileName) {
  if (fileName != null && fileName.trim().isNotEmpty) {
    return fileName.trim();
  }

  final uri = Uri.parse(imageUrl);
  final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  final cleaned = lastSegment.trim().isNotEmpty ? lastSegment.trim() : 'post_image.jpg';

  return '${DateTime.now().millisecondsSinceEpoch}_$cleaned';
}
