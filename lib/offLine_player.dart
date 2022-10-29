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
  List<String> songList = [];

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
        isPlaying = false;
      });
    } else {
      setState(() {
        isPlaying = true;
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
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            songList.isNotEmpty
                ? Container(
              height: 30.0,
              width: double.infinity,
              child: ListView.separated(
                itemBuilder: (context, index) {
                  //var parts = songList[index].split("/");
                  return InkWell(
                    child: Container(
                      child: Text(" {parts[4]} "),
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20))
                      ),
                      alignment: Alignment.center,
                    ),
                    onTap: () async {
                      changeIcon();
                      if (_player.playing) {
                        _player.stop();
                        await _player.setAudioSource(
                            AudioSource.uri(Uri.directory(songList[index],windows: false)));
                        _player.play();
                      } else {
                        await _player.setAudioSource(
                            AudioSource.uri(Uri.directory(songList[index],windows: false)));
                        _player.play();
                      }
                    },
                  );
                },
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    width: 60.0,
                  );
                },
              ),
            )
                : Text("Download songs from browser to play songs offline."),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    //_player.play();
                  },
                  child: Icon(Icons.skip_previous),
                  style: ElevatedButton.styleFrom(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      )),
                ),
                ElevatedButton(
                  onPressed: () {
                    changeIcon();
                    if (_player.playing) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  },
                  child: isPlaying
                      ? Icon(Icons.pause)
                      : Icon(Icons.play_arrow_outlined),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(24),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    //_player.play();
                  },
                  child: Icon(Icons.skip_next),
                  style: ElevatedButton.styleFrom(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      )),
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
      if(getTasks!=null){
        print("task length ${getTasks.length}");
        getTasks.forEach((_task) {
print(_task.status);
print(_task.filename);
          setState(() {
            songList.add(_task.savedDir);
            
          });


        });
      }
    }

}
