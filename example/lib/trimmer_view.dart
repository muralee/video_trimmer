import 'dart:io';

import 'package:example/preview.dart';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView(this.file, {Key? key}) : super(key: key);
  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  @override
  void initState() {
    super.initState();

    _loadVideo();
  }

  void _loadVideo() async {
    debugPrint('---TrimVideo: Source Video Size in bytes: ' +
        widget.file.lengthSync().toString());
    await _trimmer.loadVideo(videoFile: widget.file);
    if(_trimmer.videoPlayerController != null) {
      debugPrint('---TrimVideo: video duration: ' +
          _trimmer.videoPlayerController!.value.duration.inSeconds.toString());
    }
  }

  _saveVideo() {
    setState(() {
      _progressVisibility = true;
    });

    //String ffmpegCommand = ' -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -c:a copy ';
    String ffmpegCommand = ' -c:v libx264 -crf 24 -pix_fmt yuv420p -c:a copy ';
    //String ffmpegCommand = ' -c:v libx265 -crf 28 -pix_fmt yuv420p -c:a copy ';
    //String ffmpegCommand = ' -c:v libx264 -pix_fmt yuv420p -c:a copy ';
    //String ffmpegCommand = ' -c:v copy -pix_fmt yuv420p -c:a copy ';
    FileFormat outputFormat = FileFormat.mp4;
    String customVideoFormat= outputFormat.toString();

    _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,

      // advanced start
      ffmpegCommand: ffmpegCommand,
      customVideoFormat: customVideoFormat,
      outputFormat: outputFormat,
      // advanced end

      onSave: (outputPath) {
        setState(() {
          _progressVisibility = false;
        });
        debugPrint('OUTPUT PATH: $outputPath');

        if (null != outputPath) {
          File _file = File(outputPath);
          debugPrint('---TrimVideo: out video size in bytes: ' +
              _file.lengthSync().toString());
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Preview(outputPath),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Video Trimmer"),
        ),
        body: Builder(
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Visibility(
                    visible: _progressVisibility,
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _progressVisibility ? null : () => _saveVideo(),
                    child: const Text("SAVE"),
                  ),
                  Expanded(
                    child: VideoViewer(trimmer: _trimmer),
                  ),
                  Center(
                    child: TrimEditor(
                      trimmer: _trimmer,
                      viewerHeight: 50.0,
                      viewerWidth: MediaQuery.of(context).size.width,
                      maxVideoLength: const Duration(seconds: 10),
                      onChangeStart: (value) {
                        _startValue = value;
                      },
                      onChangeEnd: (value) {
                        _endValue = value;
                      },
                      onChangePlaybackState: (value) {
                        setState(() {
                          _isPlaying = value;
                        });
                      },
                    ),
                  ),
                  TextButton(
                    child: _isPlaying
                        ? const Icon(
                            Icons.pause,
                            size: 80.0,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.play_arrow,
                            size: 80.0,
                            color: Colors.white,
                          ),
                    onPressed: () async {
                      bool playbackState = await _trimmer.videPlaybackControl(
                        startValue: _startValue,
                        endValue: _endValue,
                      );
                      setState(() {
                        _isPlaying = playbackState;
                      });
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
