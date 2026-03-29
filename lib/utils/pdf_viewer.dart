import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.fileUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isLoading = true;
  String? _localPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final fileName = widget.fileUrl.split('/').last.split('?').first;
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (!await file.exists()) {
        await dio.download(widget.fileUrl, filePath);
      }

      setState(() {
        _localPath = filePath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_localPath == null) return;
    try {
      final src = File(_localPath!);
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = widget.fileUrl.split('/').last.split('?').first;
      final destPath = '${docsDir.path}/$fileName';

      await src.copy(destPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to: $destPath'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              Share.shareXFiles(
                [XFile(destPath)],
                text: widget.title,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDownload = !_isLoading && _errorMessage == null && _localPath != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            tooltip: 'Download',
            onPressed: canDownload ? _downloadPdf : null,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _preparePdf,
              ),
            ],
          ),
        ),
      )
          : PDFView(
        filePath: _localPath!,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageSnap: true,
        onError: (error) => setState(() => _errorMessage = error.toString()),
      ),
    );
  }
}
