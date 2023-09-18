import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';


class Control extends StatefulWidget {

  String ip;
  final Function() askForReconnect;

  Control({required this.ip, required this.askForReconnect});

  @override
  ControlState createState() => ControlState();
}

class ControlState extends State<Control> {

  double _value = 0;
  String _ip = "";
  bool disconnected = false;

  @override
  initState() {
    super.initState();

    connectionCheckTimer();
  }

  Future<void> connectionCheckTimer() async {
    final client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final prefs = await SharedPreferences.getInstance();

    int checkCounter = 0;
    Timer? checkTimer;

    client.listen((event) {
      Datagram? dg = client.receive();
      if (dg != null) {
        if (dg.data[0] == 1) {
          checkCounter = 0;
          setState(() {
            disconnected = false;
          });
          //checkTimer?.cancel();
        }
      }
    });
    

    
    checkTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      String ip = prefs.getString("IP").toString();
      List<int> packet = List.filled(200, 0);
      packet[0] = 5;
      checkCounter++;
      client.send(packet, InternetAddress(ip), 8080);

      if (checkCounter >= 3) {
        setState(() {
          disconnected = true;
        });
        //checkTimer?.cancel();
      }
    });

  }

  Future<void> setLEDState(double value) async {
    setState(() {
      _value = value;
    });
    final client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final prefs = await SharedPreferences.getInstance();
    String ip = prefs.getString("IP").toString();
    setState(() {
      _ip = ip;
    });
    List<int> packet = List.filled(200, 0);

    packet[0] = 4;
    packet[1] = value.toInt();

    //client.listen((event) { });
    
    client.send(packet, InternetAddress(ip), 8080);
    
    client.close();
  }

  void mediumFunc(value) {
    setLEDState(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Slider(
        value: _value,
        //secondaryTrackValue: rememberedValue,
        min: 0,
        max: 255,
        onChanged: mediumFunc,
      ),
      Text("ip: "+_ip),
      Visibility(
        visible: disconnected,
        child: Text("The ESP is not responding. Make sure it's on. If it is, try reconnecting to it.")
      ),
      Visibility(
        visible: disconnected,
        child: ElevatedButton(
          onPressed: widget.askForReconnect,
          child: Text("Reconnnect")
        )
      ),
    ]);
      /*SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 100,
          pointers: [
            RangePointer(
              enableDragging: true,
              value: _value,
              onValueChanging: (value) {
                setLEDState(value.value);
              },)
          ],),
      ],
    );*/
  }
}