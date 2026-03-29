import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/youtube_utils.dart';

class YouTubeCacheService {
  static final YouTubeCacheService _instance = YouTubeCacheService._internal();
  factory YouTubeCacheService() => _instance;
  YouTubeCacheService._internal();

  static final CacheManager _cacheManager = CacheManager(
    Config(
      'youtubeVideos',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 50,
    ),
  );

  Future<bool> isCached(String youtubeUrl) async {
    try {
      final videoId = YouTubeUtils.extractVideoId(youtubeUrl);
      if (videoId == null || videoId.isEmpty) return false;

      final cachedFile = await _cacheManager.getFileFromCache('$videoId.mp4');
      return cachedFile != null && cachedFile.file.existsSync();
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCachedVideoPath(String youtubeUrl) async {
    try {
      final videoId = YouTubeUtils.extractVideoId(youtubeUrl);
      if (videoId == null || videoId.isEmpty) return null;

      final cachedFile = await _cacheManager.getFileFromCache('$videoId.mp4');
      if (cachedFile != null && cachedFile.file.existsSync()) {
        return cachedFile.file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> cacheVideo(String youtubeUrl, String videoFilePath) async {
    try {
      final videoId = YouTubeUtils.extractVideoId(youtubeUrl);
      if (videoId == null || videoId.isEmpty) return null;

      final file = File(videoFilePath);
      if (!file.existsSync()) return null;

      final cachedFile = await _cacheManager.putFile(
        '$videoId.mp4',
        file.readAsBytesSync(),
        fileExtension: 'mp4',
      );

      return cachedFile.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getOrDownloadVideo(String youtubeUrl) async {

    return null;
  }

  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final videoCacheDir = Directory('${cacheDir.path}/youtubeVideos');

      if (!videoCacheDir.existsSync()) return 0;

      int totalSize = 0;
      await for (var entity in videoCacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
