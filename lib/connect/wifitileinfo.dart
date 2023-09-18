import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiTileInfo extends StatefulWidget {

  final WiFiAccessPoint wifi;
  final IconData? signalIcon;
  final bool enabled;
  WifiTileInfo({required this.wifi, required this.signalIcon, required this.enabled});

  @override
  WifiTileInfoState createState() => WifiTileInfoState();
}

class WifiTileInfoState extends State<WifiTileInfo> {

  Widget? wifiIcon;

  @override
  void initState() {
    super.initState();
    if (widget.wifi.capabilities.contains("WPA") || widget.wifi.capabilities.contains("WEP")) {
      wifiIcon = Stack(
        alignment: Alignment(1.1, 0.8),
        children: [
          Icon(
            widget.signalIcon,
            color: widget.enabled ? Colors.grey : const Color.fromARGB(255, 210, 210, 210)
          ),
          Icon(
            Icons.lock,
            color: widget.enabled ? Colors.grey : const Color.fromARGB(255, 210, 210, 210),
            size: 8
          )
        ],
      );
    } else {
      wifiIcon = Icon(
                    widget.signalIcon,
                    color: widget.enabled ? Colors.grey : const Color.fromARGB(255, 210, 210, 210)
                  );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10),
      child: Row(
        //minVerticalPadding: 1,
        //leading: Icon(signal),
        //title: Text(wifi.ssid),
        children: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: wifiIcon
          ),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(
              "${widget.wifi.frequency~/100/10}GHz",
              style: widget.enabled ? TextStyle(color: Colors.black) : TextStyle(color: Colors.grey),
            )
          ),
          Text(
            widget.wifi.ssid,
            style: widget.enabled ? TextStyle(color: Colors.black) : TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}