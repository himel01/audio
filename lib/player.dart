import 'package:audio_stream/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';

class Player extends StatefulWidget {
  const Player({Key? key}) : super(key: key);

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final _player = AudioPlayer();
  bool isPlaying = false;
  List<String> list = [];

  // final playlist = ConcatenatingAudioSource(
  //   // Start loading next item just before reaching it
  //     useLazyPreparation: true,
  //     // Customise the shuffle algorithm
  //     shuffleOrder: DefaultShuffleOrder(),
  //     // Specify the playlist items
  //     children: [
  // AudioSource.uri(Uri.parse('https://example.com/track1.mp3')
  //
  // )
  //
  // ,
  //
  // AudioSource.uri();
  //
  // AudioSource.uri
  //
  // (
  //
  // Uri.parse
  //
  // (
  //
  // '
  //
  // https://example.com/track2.mp3
  //
  // '
  //
  // )
  //
  // )
  //
  // ,
  //
  // AudioSource.uri
  //
  // (
  //
  // Uri.parse
  //
  // (
  //
  // '
  //
  // https://example.com/track3.mp3
  //
  // '
  //
  // )
  //
  // )
  //
  // ,
  //
  // ]
  //
  // ,
  //
  // );

  var i = 0.5;

  var s = 1.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
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
            list.isNotEmpty
                ? Container(
                    height: 30.0,
                    width: double.infinity,
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        var parts = list[index].split("/");
                        return InkWell(
                          child: Container(
                            child: Text(" ${parts[4]} "),
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            alignment: Alignment.center,
                          ),
                          onTap: () async {
                            changeIcon();
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

class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  const ControlButtons(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Opens volume slider dialog
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () {
            // showSliderDialog(
            //   context: context,
            //   title: "Adjust volume",
            //   divisions: 10,
            //   min: 0.0,
            //   max: 1.0,
            //   value: player.volume,
            //   stream: player.volumeStream,
            //   onChanged: player.setVolume,
            // );
          },
        ),

        /// This StreamBuilder rebuilds whenever the player state changes, which
        /// includes the playing/paused state and also the
        /// loading/buffering/ready state. Depending on the state we show the
        /// appropriate button or loading indicator.
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),
        // Opens speed slider dialog
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) => IconButton(
            icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              // showSliderDialog(
              //   context: context,
              //   title: "Adjust speed",
              //   divisions: 10,
              //   min: 0.5,
              //   max: 1.5,
              //   value: player.speed,
              //   stream: player.speedStream,
              //   onChanged: player.setSpeed,
              // );
            },
          ),
        ),
      ],
    );
  }
}
