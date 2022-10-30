import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_stream/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Browser extends StatefulWidget with WidgetsBindingObserver {
  final String url;

  const Browser({Key? key, required this.url}) : super(key: key);

  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser> {
  ReceivePort _port = ReceivePort();
  String location = "";

  var loadingPercentage = 0;

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  showAlertDialog(BuildContext context, String url) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("Download for Offline Player"),
      onPressed: () {
        downLoad(url);
        Navigator.pop(context);
      },
    );
    Widget noButton = TextButton(
      child: Text("No"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget saveButton = TextButton(
      child: Text("Save for Online Player"),
      onPressed: () {
        GlobalValues().addToList(url);
        GlobalValues().printLength();
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Download"),
      content: Text(
          "This site contains downloadable mp3 file. Do you want to download?"),
      actions: [okButton, saveButton, noButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
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

  Future<void> downLoad(String url) async {
    getPermission().then((value) async {
      var granted = await Permission.storage.status;
      if (granted.isGranted) {
        Directory? root = await getExternalStorageDirectory();
        String? directoryPath = root?.path;
        String path = "";
        if (directoryPath != null) {
          path = '$directoryPath/audio_player';
        }
        location = path;
        final savedDir = Directory(path);
        //String name = url.split("/")[4];
        await savedDir.create(recursive: true).then((value) async {
          final taskId = await FlutterDownloader.enqueue(
              url: url,
              headers: {},
              savedDir: path,
              showNotification: true,
              openFileFromNotification: true,
              //saveInPublicStorage: true,
          );
          print("task id is $taskId");
        });
      }
    });
    print("inside download");
  }

  @override
  void initState() {
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
    getPermission();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    super.initState();
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  getPermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied || status.isRestricted) {
      Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      alignment: Alignment.center,
      children: [
        WebView(
          initialUrl: widget.url,
          javascriptMode: JavascriptMode.unrestricted,
          allowsInlineMediaPlayback: true,
          onPageStarted: (value) {
            print("started");
            setState(() {
              loadingPercentage = 0;
            });
            print(value);
            if (value.contains(".mp3")) {
              showAlertDialog(context, value);
              //downLoad(value);
            }
          },
          onPageFinished: (s) {
            print("finished");
            setState(() {
              loadingPercentage = 100;
            });
          },
          onProgress: (i) {
            setState(() {
              loadingPercentage = i;
            });
          },
        ),
        if (loadingPercentage < 100)
          CircularProgressIndicator(
            value: loadingPercentage / 100.0,
            color: Colors.blue,
            backgroundColor: Colors.orange,
          ),
      ],
    );
  }
}
