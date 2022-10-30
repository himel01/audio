import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:just_audio/just_audio.dart';

import 'main.dart';

class Offline extends StatefulWidget {
  const Offline({Key? key}) : super(key: key);

  @override
  State<Offline> createState() => _OfflineState();
}

class _OfflineState extends State<Offline> {
  ReceivePort _port = ReceivePort();
  final _player = AudioPlayer();
  bool isPlaying = false;
  List<String> list = [];
  List<DownloadTask> songList = [];
  var i = 0.5;

  var s = 1.0;

  @override
  void initState() {
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    task();
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  // Future<void> _init() async {
  //   final session = await AudioSession.instance;
  //   await session.configure(const AudioSessionConfiguration.speech());
  //   _player.playbackEventStream.listen((event) {},
  //       onError: (Object e, StackTrace stackTrace) {
  //         print('A stream error occurred: $e');
  //       });
  //   try {
  //     await _player.setAudioSource(AudioSource.uri(
  //         Uri.parse("https://www.harlancoben.com/audio/CaughtSample.mp3")));
  //   } catch (e) {
  //     print("Error loading audio source: $e");
  //   }
  // }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  changeIcon() {
    if (_player.playing) {
      setState(() {
        isPlaying = true;
      });
    } else {
      setState(() {
        isPlaying = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offline Player"),
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            songList.isNotEmpty
                ? Container(
                    height: 30.0,
                    margin: EdgeInsets.only(left: 10.0, right: 10.0),
                    width: double.infinity,
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        //var parts = songList[index].split("/");
                        return InkWell(
                          child: Container(
                            child: Text("  ${songList[index].filename!}  "),
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            alignment: Alignment.center,
                          ),
                          onTap: () async {
                            print(songList[index].savedDir);

                            if (_player.playing) {
                              _player.stop();
                              await _player.setAudioSource(AudioSource.uri(
                                  Uri.file(
                                      songList[index].savedDir +
                                          "/" +
                                          songList[index].filename!,
                                      windows: false)));
                              _player.play();
                              changeIcon();
                            } else {
                              await _player.setAudioSource(AudioSource.uri(
                                  Uri.file(
                                      songList[index].savedDir +
                                          "/" +
                                          songList[index].filename!,
                                      windows: false)));
                              _player.play();
                              changeIcon();
                            }
                          },
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: songList.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          width: 60.0,
                        );
                      },
                    ),
                  )
                : Text("Download songs from browser to play songs offline."),
            SizedBox(
              height: 100.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    //_player.play();
                    await _player.seekToPrevious();
                  },
                  child: Icon(Icons.skip_previous),
                  style: ElevatedButton.styleFrom(
                      shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )),
                ),
                OutlinedButton(
                  onPressed: () async {
                    var t = await _player.position.inSeconds;
                    await _player.seek(Duration(seconds: t - 10));
                  },
                  child: Icon(Icons.arrow_back_ios_sharp),
                  style: OutlinedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(24),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_player.playing) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                    changeIcon();
                  },
                  child: isPlaying
                      ? Icon(Icons.pause)
                      : Icon(Icons.play_arrow_outlined),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(24),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    var t = await _player.position.inSeconds;
                    await _player.seek(Duration(seconds: t + 10));
                  },
                  child: Icon(Icons.arrow_forward_ios),
                  style: OutlinedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(24),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    //_player.play();
                    await _player.seekToNext();
                  },
                  child: Icon(Icons.skip_next),
                  style: ElevatedButton.styleFrom(
                      shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    //await player.pause();                           // Pause but remain ready to play
                    //await player.seek(Duration(second: 10));        // Jump to the 10 second position
                    //await player.setSpeed(2.0);

                    // Half as loud
                    await _player.setVolume(i = i - 0.1); // Half as loud
                    //await player.stop();
                  },
                  child: Icon(Icons.remove),
                  style: OutlinedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(24),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await _player.setVolume(i = i + 0.1);
                  },
                  child: Icon(Icons.add),
                  style: OutlinedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(24),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await _player.setSpeed(s = s + 0.2);
                  },
                  child: Text("Speed+"),
                  style: OutlinedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(24),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await _player.setSpeed(s = s - 0.2);
                  },
                  child: Text("Speed-"),
                  style: OutlinedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future task() async {
    List<DownloadTask>? getTasks = await FlutterDownloader.loadTasks();
    if (getTasks != null) {
      print("task length ${getTasks.length}");
      getTasks.forEach((task) {
        print(task.status);
        print(task.filename);
        if (task.status.toString().contains("3")) {
          setState(() {
            songList.add(task);
          });
        }
      });
    }
  }
}
