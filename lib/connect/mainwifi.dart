import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:capped_progress_indicator/capped_progress_indicator.dart';

import 'wifitile.dart';

class MainWifi extends StatefulWidget {

  final Function() updateWifi;

  MainWifi({required this.updateWifi});

  @override
  MainWifiState createState() => MainWifiState();
}

class MainWifiState extends State<MainWifi> {

  bool canScan = false;
  bool scanning = false;
  bool restricted = false;
  final accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  Timer? timer;

  Future<void> checkCanScan() async {
    if (await Permission.location.serviceStatus.isDisabled) {
      setState(() {
        restricted = true;
      });
    } else {
      setState(() {
        restricted = false;
      });
    }

    final can = await WiFiScan.instance.canStartScan();
    if (can == CanStartScan.yes) {
      setState(() {
        startScan();
        if (!canScan) {
          getScanResults();
        }
        canScan = true;
      });
    } else {
      setState(() {
        canScan = false;
      });
      subscription?.cancel();
      setState(() => subscription = null);
      }
  }

  @override
  void initState() {
    super.initState();

    initScan();

    timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      checkCanScan();
    });

    // checkCanScan().listen((event) {
    //   if (event) {
    //     setState(() {
    //       canScan = true;
    //     });
    //     startScan();
    //   } else {
    //     setState(() {
    //       canScan = false;
    //     });
    //     subscription?.cancel();
    //     setState(() => subscription = null);
    //   }
    // });
  }

  Future<void> initScan() async {
    final can = await WiFiScan.instance.canStartScan();
    if (can == CanStartScan.yes) {
      getScanResults();
      setState(() {
        canScan = true;
      });
    }
  }

  Future<void> launchIntent() async {
    AndroidIntent intent = const AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }

  Future<void> startScan() async {
    bool _scanning = await WiFiScan.instance.startScan();
    setState(() {
      scanning = _scanning;
    });
  }

  Future<void> getScanResults() async {
    accessPoints.clear();
    accessPoints.addAll(await WiFiScan.instance.getScannedResults());
    setState(
      () {
        accessPoints.removeWhere((element) => element.ssid.isEmpty == true);
        accessPoints.sort((a,b) => b.level.compareTo(a.level));
      }
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    setState(() => subscription = null);
    timer?.cancel();
    super.dispose();
  }

  Widget wifiList() {
    if (accessPoints.isEmpty) {
      return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: CircularCappedProgressIndicator(
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                    )
                  )
                ]
              );
    } else {
      return RawScrollbar(
        mainAxisMargin: 5,
        crossAxisMargin: 5,
        thumbVisibility: true,
        radius: Radius.circular(5),
        child: ScrollConfiguration(
          behavior: MyBehavior(),
          child: ListView.separated(
            padding: EdgeInsets.all(10),
            shrinkWrap: true,
            itemCount: accessPoints.length,
            itemBuilder: (context, i) {
              return WifiTile(wifi: accessPoints[i], updateWifi: widget.updateWifi);
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(),
          ),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Visibility(
          visible: !canScan && !restricted,
          child: Text("Please wait. Currently unable to scan "
                      "for wifi due to Android limiting the amount of scans that can be done. "
                      "Scanning will start as soon as possible."),
        ),
        Visibility(
          visible: restricted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Location has to be turned on for android to allow the app to scan for wifi. Please turn location on."),
              ElevatedButton(onPressed: launchIntent, child: Text("Enable Location"))
          ],)
        ),
        Visibility(
          visible: !restricted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 5),
                  ],
                  borderRadius: BorderRadius.all(Radius.circular(5))
                ),
                height: 200,
                child: wifiList()
          ),
          ElevatedButton(onPressed: getScanResults, child: Icon(Icons.refresh)),
          ]),
        ),
      ],
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}