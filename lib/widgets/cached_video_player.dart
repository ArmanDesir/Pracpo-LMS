import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:pracpro/services/youtube_cache_service.dart';
import 'package:pracpro/utils/youtube_utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CachedVideoPlayer extends StatefulWidget {
  final String youtubeUrl;
  final bool autoPlay;
  final bool showControls;

  const CachedVideoPlayer({
    super.key,
    required this.youtubeUrl,
    this.autoPlay = false,
    this.showControls = true,
  });

  @override
  State<CachedVideoPlayer> createState() => _CachedVideoPlayerState();
}

class _CachedVideoPlayerState extends State<CachedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  bool _isCached = false;
  bool _useYoutubePlayer = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      final cacheService = YouTubeCacheService();

      final cachedPath = await cacheService.getCachedVideoPath(widget.youtubeUrl);

      if (cachedPath != null && File(cachedPath).existsSync()) {

        try {
          _videoController = VideoPlayerController.file(File(cachedPath));
          await _videoController!.initialize();

          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: widget.autoPlay,
            looping: false,
            aspectRatio: _videoController!.value.aspectRatio,
            showControls: widget.showControls,
            materialProgressColors: ChewieProgressColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
              backgroundColor: Colors.grey,
              bufferedColor: Colors.lightGreen,
            ),
            placeholder: Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );

          await WakelockPlus.enable();

          _isCached = true;
          setState(() {
            _isLoading = false;
            _useYoutubePlayer = false;
          });
          return;
        } catch (e) {
          // Failed to load cached video - continue silently
        }
      }

      final videoId = YouTubeUtils.extractVideoId(widget.youtubeUrl);
      if (videoId == null || videoId.isEmpty) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Invalid YouTube URL: ${widget.youtubeUrl}';
        });
        return;
      }

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          mute: false,
          hideControls: !widget.showControls,
          controlsVisibleAtStart: widget.showControls,
          enableCaption: true,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
        ),
      );

      _youtubeController!.addListener(() {
        // Listener for YouTube player state changes
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isLoading = false;
        _useYoutubePlayer = true;
        _isCached = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _chewieController?.dispose();
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_isError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage ?? 'Video unavailable',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = widget.youtubeUrl;
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              _useYoutubePlayer
                  ? Stack(
                      children: [
                        YoutubePlayerBuilder(
                          onExitFullScreen: () {

                          },
                          player: YoutubePlayer(
                            controller: _youtubeController!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.red,
                            progressColors: const ProgressBarColors(
                              playedColor: Colors.red,
                              handleColor: Colors.redAccent,
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.black26,
                            ),
                            onReady: () {

                              if (widget.autoPlay) {
                                _youtubeController!.play();
                              }
                            },
                            onEnded: (metadata) {
                            },
                          ),
                          builder: (context, player) {
                            return player;
                          },
                        ),

                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  final url = widget.youtubeUrl;
                                  final normalizedUrl = YouTubeUtils.normalizeUrl(url) ?? url;
                                  if (await canLaunchUrl(Uri.parse(normalizedUrl))) {
                                    await launchUrl(
                                      Uri.parse(normalizedUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Could not open video in browser'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.open_in_browser, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Open in Browser',
                                        style: TextStyle(fontSize: 11, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Chewie(controller: _chewieController!),
              if (_isCached)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Cached',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
