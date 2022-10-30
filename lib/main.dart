import 'package:audio_stream/browser.dart';
import 'package:audio_stream/offLine_player.dart';
import 'package:audio_stream/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();



  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Audio Player'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController t =
      TextEditingController(text: "https://www.harlancoben.com/audio-samples");

  showAlertDialog(BuildContext context, String url) {
    Widget onButton = TextButton(
      child: Text("Online"),
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Player()),
        );
      },
    );
    Widget offButton = TextButton(
      child: Text("Offline"),
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Offline()),
        );
      },
    );




    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Which one?"),
      content: Text(""),
      actions: [onButton, offButton],
      elevation: 1.0,
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  getPermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied || status.isRestricted) {
      Permission.storage.request();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(width: 10.0),
                Expanded(
                    child: TextField(
                  controller: t,
                  textAlign: TextAlign.center,
                )),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Browser(url: t.text)),
                      );
                    },
                    child: Text("Browse Web")),
                SizedBox(width: 10.0),
              ],
            ),
            SizedBox(
              height: 50.0,
            ),
            ElevatedButton(
                onPressed: () {
                  showAlertDialog(context, "");
                },
                child: Text("Go to Player")),
          ],
        ),
      ),
    );
  }
}
