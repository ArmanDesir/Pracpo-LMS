
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubeUtils {

  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    try {
      url = url.trim();

      // Check if URL looks like a domain without a video ID (e.g., "youtube.com", "www.youtube.com")
      // These should not be processed
      if (RegExp(r'^https?://(www\.)?(youtube\.com|youtu\.be)/?$').hasMatch(url.toLowerCase())) {
        return null;
      }

      // Check if it's just a domain without protocol (should not happen but guard against it)
      if (RegExp(r'^(www\.)?(youtube\.com|youtu\.be)/?$').hasMatch(url.toLowerCase())) {
        return null;
      }

      if (url.contains('youtu.be/')) {
        final parts = url.split('youtu.be/');
        if (parts.length > 1) {
          final videoIdPart = parts[1].split('?').first.split('&').first.split('/').first.trim();
          if (videoIdPart.isNotEmpty && _isValidVideoId(videoIdPart)) {
            return videoIdPart;
          }
        }
      }

      if (url.contains('watch?v=')) {
        try {
        final uri = Uri.parse(url);
          final videoId = uri.queryParameters['v']?.trim();
          if (videoId != null && videoId.isNotEmpty && _isValidVideoId(videoId)) {
            return videoId;
          }
        } catch (_) {
          // If URI parsing fails, try manual extraction
          final match = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(url);
          if (match != null && match.groupCount >= 1) {
            final videoId = match.group(1);
            if (videoId != null && _isValidVideoId(videoId)) {
              return videoId;
            }
          }
        }
      }

      if (url.contains('/embed/')) {
        final parts = url.split('/embed/');
        if (parts.length > 1) {
          final videoId = parts[1].split('?').first.split('&').first.trim();
          if (videoId.isNotEmpty && _isValidVideoId(videoId)) {
            return videoId;
          }
        }
      }

      if (url.contains('/shorts/')) {
        final parts = url.split('/shorts/');
        if (parts.length > 1) {
          final videoId = parts[1].split('?').first.split('&').first.trim();
          if (videoId.isNotEmpty && _isValidVideoId(videoId)) {
            return videoId;
        }
      }
      }

      // Try YoutubePlayer.convertUrlToId as last resort, but validate the result
      try {
        final videoId = YoutubePlayer.convertUrlToId(url);
        if (videoId != null && videoId.isNotEmpty && _isValidVideoId(videoId)) {
          return videoId;
        }
      } catch (_) {}

      // Check if the entire URL is just a valid video ID
      if (url.length == 11 && _isValidVideoId(url)) {
        return url;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validates if a string is a valid YouTube video ID format
  /// YouTube video IDs are exactly 11 characters and contain only alphanumeric, hyphens, and underscores
  static bool _isValidVideoId(String videoId) {
    if (videoId.isEmpty || videoId.length != 11) {
      return false;
    }
    
    // YouTube video IDs are 11 characters: alphanumeric, hyphens, underscores
    // They should not contain dots (like "youtube.com") or other invalid characters
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (!validPattern.hasMatch(videoId)) {
      return false;
    }
    
    // Additional check: should not be a domain name
    if (videoId.contains('.') || videoId.contains('/') || videoId.contains(':')) {
      return false;
    }
    
    return true;
  }

  static String? normalizeUrl(String url) {
    final videoId = extractVideoId(url);
    if (videoId == null) return null;
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}

