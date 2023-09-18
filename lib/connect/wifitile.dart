import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wifitileinfo.dart';

class WifiTile extends StatefulWidget {
  final WiFiAccessPoint wifi;
  final Function() updateWifi;
  WifiTile({required this.wifi, required this.updateWifi});

  @override
  WifiTileState createState() => WifiTileState();
}


class WifiTileState extends State<WifiTile> {

  IconData? signal;
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> saveCredentials(wifiPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mainWifi', "${widget.wifi.ssid}|${wifiPassword}");
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.wifi.level) {
      case <= -90:
        signal = Icons.signal_wifi_0_bar;
        break;
      case > -90 && <= -80:
        signal = Icons.network_wifi_1_bar;
        break;
      case > -80 && <= -70:
        signal = Icons.network_wifi_2_bar;
        break;
      case > -70 && <= -67:
        signal = Icons.network_wifi_3_bar;
        break;
      case > -67:
        signal = Icons.signal_wifi_4_bar;
        break;
    }

    if (widget.wifi.frequency < 5000) {
      return GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                widget.wifi.ssid,
                textAlign: TextAlign.center,
              ),
              content:
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Freq: ${widget.wifi.frequency}MHz"),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text("Level: ${widget.wifi.level}"),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Password',
                      ),
                      controller: textController,
                    ),
                  ]
                ),
              actions: [
                FilledButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      saveCredentials(textController.text);
                      widget.updateWifi();
                      return Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    'Save'
                  ))
              ],
              actionsAlignment: MainAxisAlignment.center,
            );
          }
        ),
        child: WifiTileInfo(wifi: widget.wifi, signalIcon: signal, enabled: true)
      );
    } else {
      return WifiTileInfo(wifi: widget.wifi, signalIcon: signal, enabled: false);
    }
  }
}