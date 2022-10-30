import 'package:audio_stream/main.dart';
import 'package:audio_stream/offLine_player.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class Player extends StatefulWidget {
  const Player({Key? key}) : super(key: key);

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final _player = AudioPlayer();
  ConcatenatingAudioSource? playlist;
  bool isPlaying = false;
  List<String> list = [];


  var i = 0.5;

  var s = 1.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    //_init();
    getList();
    // await player.pause();                           // Pause but remain ready to play
    // await player.seek(Duration(second: 10));        // Jump to the 10 second position
    // await player.setSpeed(2.0);                     // Twice as fast
    // await player.setVolume(0.5);                    // Half as loud
    // await player.stop();
  }

  void getList() {
    setState(() {
      list = GlobalValues().getList();
    });
    print(list.length);
    if(list.isNotEmpty){
      createPlaylist();
    }
  }

  Future<void> createPlaylist() async {
    print("inside create playlist");
    playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: [],
    );

    list.forEach((element) {
      playlist!.add(AudioSource.uri(Uri.parse(element)));
    });

    await _player.setAudioSource(playlist!, initialIndex: 0, initialPosition: Duration.zero);
    _player.play();
    changeIcon();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    try {
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse("https://www.harlancoben.com/audio/CaughtSample.mp3"),
        tag: MediaItem(
          // Specify a unique ID for each media item:
          id: '1',
          // Metadata to display in the notification:
          album: "Album name",
          title: "Song name",
          artUri: Uri.parse('https://example.com/albumart.jpg'),
        ),
      ));
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

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

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
              (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Online Player"),
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            list.isNotEmpty
                ? Container(
                    height: 30.0,
                    width: double.infinity,
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        var parts = list[index].split("/");
                        return InkWell(
                          child: Container(
                            child: Text("  ${parts[4]}  "),
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            alignment: Alignment.center,
                          ),
                          onTap: () async {

                            if (_player.playing) {
                              _player.stop();
                              await _player.setAudioSource(AudioSource.uri(
                                Uri.parse(list[index]),
                                tag: MediaItem(
                                  // Specify a unique ID for each media item:
                                  id: '1',
                                  // Metadata to display in the notification:
                                  album: "Album name",
                                  title: "Song name",
                                  artUri: Uri.parse(
                                      'https://example.com/albumart.jpg'),
                                ),
                              ));
                              _player.play();
                            } else {
                              await _player.setAudioSource(AudioSource.uri(
                                Uri.parse(list[index]),
                                tag: MediaItem(
                                  // Specify a unique ID for each media item:
                                  id: '1',
                                  // Metadata to display in the notification:
                                  album: "Album name",
                                  title: "Song name",
                                  artUri: Uri.parse(
                                      'https://example.com/albumart.jpg'),
                                ),
                              ));
                              _player.play();
                            }
                            changeIcon();
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
                : Text("Add songs url from browser to play songs online."),
            SizedBox(height: 100.0,),
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                return Container(

                  margin: EdgeInsets.only(left: 15.0, right: 15.0),
                  child: ProgressBar(
                    progress: positionData?.position ?? Duration.zero,
                    buffered: positionData?.bufferedPosition ?? Duration.zero,
                    total: positionData?.duration ?? Duration.zero,
                    onSeek: (duration) {
                      _player.seek(duration);
                      print('User selected a new time: $duration');
                    },
                  ),
                );
              },
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
                    changeIcon();
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
            //ControlButtons(_player),
          ],
        ),
      ),
    );
  }
}


