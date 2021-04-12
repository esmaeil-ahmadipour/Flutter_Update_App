import 'dart:async';
import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rounded_progress_bar/flutter_rounded_progress_bar.dart';
import 'package:flutter_rounded_progress_bar/rounded_progress_bar_style.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class InstallAppPage extends StatefulWidget {
  final String appLink;

  InstallAppPage({@required this.appLink});

  @override
  _InstallAppPageState createState() => _InstallAppPageState();
}

class _InstallAppPageState extends State<InstallAppPage> {
  String _openResult = 'Unknown';
  PermissionStatus statusPermission;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String resultOpenFile = '';

  @override
  void initState() {
    super.initState();
    filename =
    '${widget.appLink.substring(widget.appLink.lastIndexOf("/") + 1, widget.appLink.length)}'; // file name that you desire to keep

    _setPermission();
  }
  bool downloading = false;
  bool startDownloading = false;
  bool finishDownloading = false;
  String progress = '0';
  bool isDownloaded = false;
  String path = '';
  String filename;

  // downloading logic is handled by this method
  Future<void> downloadFile(uri, fileName) async {
    if (mounted) {
      setState(() {
        downloading = true;
      });
    }

    String savePath = await getFilePath(fileName);
    Dio dio = Dio();
    dio.download(
      uri,
      savePath,
      onReceiveProgress: (rcv, total) {
        if (mounted) {
          setState(() {
            progress = ((rcv / total) * 100).toStringAsFixed(0);
          });
        }
        if (progress == '100') {
          if (mounted) {
            setState(() {
              isDownloaded = true;
            });
          }
        } else if (double.parse(progress) < 100) {}
      },
      deleteOnError: true,
    ).then((_) {
      if (mounted) {
        setState(() {
          if (progress == '100') {
            isDownloaded = true;
          }
          downloading = false;
        });
      }
    });
  }

  //gets the applicationDirectory and path for the to-be downloaded file
  // which will be used to save the file to that path in the downloadFile method
  Future<String> getFilePath(uniqueFileName) async {
    String dir = await ExtStorage.getExternalStorageDirectory();
    path = '$dir/$uniqueFileName';
    return path;
  }

  @override
  Widget build(BuildContext context) {
    if (isDownloaded) {
      if (mounted) {
        setState(() {
          finishDownloading = true;
          _callTime();
        });
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomSheet: startDownloading
          ? ButtonTheme(
        minWidth: MediaQuery.of(context).size.width,
        height: AppBar().preferredSize.height,
        child: Container(
          height: 1,
        ),
      )
          : ButtonTheme(
        minWidth: MediaQuery.of(context).size.width,
        height: AppBar().preferredSize.height,
        child: RaisedButton(
          onPressed: startDownloading
              ? null
              : () async {
            if (mounted) {
              setState(() {
                startDownloading = true;
              });
            }
            _checkPermission();
          },
          child: Text(
            'دانلود و نصب نسخه جدید',
            style: TextStyle(
              color: Theme.of(context)
                  .errorColor
                  .computeLuminance() >=
                  0.5
                  ? Colors.black
                  : Colors.white,
            ),
          ),
          color: Theme.of(context).errorColor,
        ),
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                startDownloading
                    ? RoundedProgressBar(
                  childCenter: double.parse(progress) < 1
                      ? (statusPermission.isPermanentlyDenied)
                      ? Text(
                    "مجوز نصب را رد کرده‌اید!",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: Theme.of(context)
                            .primaryTextTheme
                            .caption
                            .fontSize *
                            1.12),
                  )
                      : Text("")
                      : Text(
                    double.parse(progress) == 100
                        ? "دانلود فایل به اتمام رسید."
                        : "$progress%",
                    style: TextStyle(
                        color: double.parse(progress) >= 49
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: double.parse(progress) == 100
                            ? Theme.of(context)
                            .primaryTextTheme
                            .caption
                            .fontSize *
                            1.12
                            : Theme.of(context)
                            .primaryTextTheme
                            .title
                            .fontSize),
                  ),
                  reverse: true,
                  style: RoundedProgressBarStyle(
                      backgroundProgress: Colors.green[100],
                      colorProgress: Colors.green[400],
                      borderWidth: 0,
                      widthShadow: 0),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  borderRadius: BorderRadius.circular(8),
                  percent: double.parse(progress),
                )
                    : Container(),
                isDownloaded
                    ? resultOpenFile ==
                    'Permission denied: android.permission.REQUEST_INSTALL_PACKAGES'
                    ? Text(
                  'فایل دانلود شده است .\n'
                      'برای ادامه مجوز نصب را تایید کنید',
                  textAlign: TextAlign.center,
                )
                    : resultOpenFile != 'done' && resultOpenFile != ''
                    ? Text(
                  'فایل دانلود شده است .\n'
                      'راهنما را دنبال و نصب را کامل کنید',
                  textAlign: TextAlign.center,
                )
                    : Text(
                  'آخرین نسخه دانلود شد .\n'
                      'از طریق دکمه زیر , آن را باز کنید.',
                  textAlign: TextAlign.center,
                )
                    : startDownloading
                    ? statusPermission.isPermanentlyDenied
                    ? Text(
                  'مجوز را دستی تایید یا اینکه\n'
                      'اپ را حذف و مجدد نصب کنید.\n',
                  textAlign: TextAlign.center,
                )
                    : Text(
                  'فایل APK در حال دانلود است\n'
                      'پس از دانلود , آن را نصب کنید.\n',
                  textAlign: TextAlign.center,
                )
                    : Text(
                  'برای دانلود و نصب نسخه جدید\n'
                      'از دکمه پایین صفحه اقدام کنید.',
                  textAlign: TextAlign.center,
                ),
                Visibility(
                    visible: isDownloaded ? true : false,
                    child: RaisedButton(
                      color: resultOpenFile != 'done' &&
                          resultOpenFile != '' &&
                          resultOpenFile !=
                              'Permission denied: android.permission.REQUEST_INSTALL_PACKAGES'
                          ? Colors.deepOrange[700]
                          : resultOpenFile ==
                          'Permission denied: android.permission.REQUEST_INSTALL_PACKAGES'
                          ? Colors.red[900]
                          : Theme.of(context)
                          .errorColor,
                      elevation: 3.0,
                      splashColor: Colors.black38,
                      onPressed: () {
                        resultOpenFile != 'done' &&
                            resultOpenFile != '' &&
                            resultOpenFile !=
                                'Permission denied: android.permission.REQUEST_INSTALL_PACKAGES'
                            ? getPageContent("app-install-android")
                            : _openFile();
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side: BorderSide(color: Colors.white)),
                      child: Text(
                        resultOpenFile != 'done' &&
                            resultOpenFile != '' &&
                            resultOpenFile !=
                                'Permission denied: android.permission.REQUEST_INSTALL_PACKAGES'
                            ? 'راهنمای نصب'
                            : resultOpenFile ==
                            'Permission denied: android.permission.REQUEST_INSTALL_PACKAGES'
                            ? 'تایید مجوز و نصب فایل'
                            : 'نصب فایل دانلود شده',
                        style: TextStyle(color: Colors.white),
                      ),
                    )),
              ],
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: MediaQuery.of(context).padding.top,
          child: new Container(
            color: const Color(0xfff5f5f5),
            child: new Stack(
              children: <Widget>[
                new Container(
                  width: AppBar().preferredSize.height / 4,
                  height: AppBar().preferredSize.height / 4,
                ),
                InkWell(
                  child: Icon(
                    Icons.error,
                    size: AppBar().preferredSize.height * 1.12,
                    color: Colors.deepOrange,
                    textDirection: TextDirection.ltr,
                  ),
                  onTap: () {
                    getPageContent("app-install-android");
                  },
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  getPageContent(String _pageName) async {
    // Map<String, dynamic> _map = {};
    // try {
    //   _showWaitingPage(true);
    //   final _response = await ApiService.create().apiGetPageContent(_pageName);
    //   if (_response.statusCode == 200) {
    //     _map = json.decode(utf8.decode(_response.bodyBytes));
    //     PageModel _model = PageModel.fromJson(_map);
    //     await _showWaitingPage(false);
    //     await Navigator.of(context)
    //         .push(new MaterialPageRoute(builder: (BuildContext context) {
    //       return Directionality(
    //         textDirection: TextDirection.rtl,
    //         child: InstallHelp(
    //           filename: filename,
    //           downloadUrl: widget.appModel.androidFile,
    //           appNotes: widget.appModel.notes,
    //           pageModel: _model,
    //         ),
    //       );
    //     }));
    //   }
    // } catch (e) {}
  }

  _callTime() async {
    Timer.periodic(new Duration(milliseconds: 1000), (time) async {
      if (!finishDownloading) {
        _openFile();
        finishDownloading = true;
      }
      time.cancel();
    });
  }

  void _openFile() async {
    final result = await OpenFile.open(path);
    if (mounted) {
      setState(() {
        _openResult = "type=${result.type}  message=${result.message}";
        resultOpenFile = '${result.message}';
      });
    }
  }

  _setPermission() async {
    statusPermission = await Permission.storage.status;
  }

  _checkPermission() async {
    if (statusPermission.isGranted) {
      downloadFile(widget.appLink, filename);
    } else if (!statusPermission.isPermanentlyDenied) {
      await Permission.storage.request();
      await _setPermission();
      await _checkPermission();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
