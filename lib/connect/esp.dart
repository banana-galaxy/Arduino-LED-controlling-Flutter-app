import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Stages {Start, ConnectedToESP, GotCreds, ConnectedToWifi, IpRetrievalFailed, Control}

class ESP extends StatefulWidget {

  final Function() switchToControl;
  final Function() reset;
  String ip;
  bool reconnect = false;

  ESP({required this.ip, required this.switchToControl, required this.reset, required this.reconnect});

  @override
  ESPState createState() => ESPState();
}

class ESPState extends State<ESP> {

  Stages stage = Stages.Start;
  String ssid = '';
  String espMac = '';
  bool locationStatus = false;
  Timer? timer;
  bool credsCorrect = false;
  bool timerFlip = false;
  
  @override
  void initState() {
    super.initState();

    if (widget.reconnect) {
      stage = Stages.IpRetrievalFailed;
    }

    getSsid();
    timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      checkLocationStatus();
      getSsid();
    });
  }

  Future<void> getSsid() async {
    final info = NetworkInfo();

    String? name = await info.getWifiName();
    setState(() {
      ssid = name.toString();
      if (ssid.contains("ESP32") && stage == Stages.Start) {
        stage = Stages.ConnectedToESP;
      }
    });
  }

  Future<void> openWifiSettings() async {
    AndroidIntent intent = const AndroidIntent(
      action: 'android.settings.WIFI_SETTINGS',
    );
    await intent.launch();
  }

  Future<void> checkLocationStatus() async {
    if (await Permission.location.serviceStatus.isDisabled) {
      setState(() {
        locationStatus = false;
      });
    } else {
      setState(() {
        locationStatus = true;
      });
    }
  }

  Future<void> openLocationSettings() async {
    AndroidIntent intent = const AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }

  bool gotIP = false;
  int ipCounter = 0;
  String recordedMAc = "";
  String responseMac = "";
  int macCompare = 0;

  Future<void> askForIP() async {
    final prefs = await SharedPreferences.getInstance();
    final client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    client.broadcastEnabled = true;

    const int macLength = 18;
    //List<int> ip = List.filled(ipLength, 0);

    client.listen((event) {
      Datagram? dg = client.receive();
      if (dg != null) {
        /*for (int i = 0; i < ipLength; i++) {
          ip[i] = dg.data[i];
          setState(() {
            ipValue[i] = dg.data[i];
          });
        }*/
        //widget.ip = dg.address.address.toString();

        // String mac = prefs.getString("ESPMac").toString();
        // setState(() {
        //   recordedMAc = mac;
        // });
        // String receivedMac = "";
        // receivedMac = utf8.decode(dg.data);
        // setState(() {
        //   responseMac = receivedMac;
        // });
        // setState(() {
        //   macCompare = mac.compareTo(receivedMac);
        // });
        if (dg.data[0] == 1) {
          prefs.setString("IP", dg.address.address.toString());
          gotIP = true;
        }
      }
      //prefs.setString("IP", utf8.decode(ip));
    });

    List<int> packet = List.filled(200, 0);
    String mac = prefs.getString("ESPMac").toString();
    List<int> intMac = utf8.encode(mac);

    packet[0] = 3;
    for (int i = 0; i < intMac.length; i++) {
      packet[1+i] = intMac[i];
    }

    client.send(packet, InternetAddress("255.255.255.255"), 8080);

  }

  Future<void> getIPAddress() async {
    Timer? ipTimer;
    ipTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (gotIP) {
        setState(() {
          stage = Stages.Control;
        });
        ipTimer?.cancel();
      } else {
        ipCounter++;
        if (ipCounter >= 10) {
          setState(() {
            stage = Stages.IpRetrievalFailed;
          });
          ipTimer?.cancel();
        } else {
          askForIP();
        }
      }
    });
  }

  Future<void> awaitWifi() async {
    Timer? timeoutTimer;
    final prefs = await SharedPreferences.getInstance();
    timeoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      String wifi = prefs.getString('mainWifi') ?? "";
      List<String> wifiParts = wifi.split("|");
      if (ssid.contains(wifiParts[0])) {
        setState(() {
          stage = Stages.ConnectedToWifi;
        });
        getIPAddress();
        timeoutTimer?.cancel();
      }
    });
  }

  bool ackFlip = false;

  Future<void> acknowledge() async {
    setState(() {
      ackFlip = !ackFlip;
    });
    List<int> packet = List.filled(200, 0);
    packet[0] = 2;
    final client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    client.broadcastEnabled = true;
    client.send(packet, InternetAddress("255.255.255.255"), 8080);
    client.close();
  }

  Future<void> startACK() async {
    Timer? imeoutTimer;
    imeoutTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (ssid.contains("ESP32")) {
        acknowledge();
      } else {
        setState(() {
          stage = Stages.GotCreds;
        });
        awaitWifi();
        imeoutTimer?.cancel();
      }
    });
  }

  bool transmissionTimedOut = true;
  bool transmissionDone = false;
  List<int> wifiCreds = List.filled(200, 0);
  String _ssid = "";
  String _psswd = "";
  bool credsMatch = false;

  Future<void> startTransmission() async {
    final client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    client.broadcastEnabled = true;

    final prefs = await SharedPreferences.getInstance();
    String wifi = prefs.getString('mainWifi') ?? "";
    List<String> wifiParts = wifi.split("|");


    client.timeout(
      Duration(seconds: 5),
      onTimeout: (sink) {
        setState(() {
          transmissionTimedOut = true;
        });
      } ,
    ).listen((event) {
      Datagram? dg = client.receive();
      if (dg != null) {
        _ssid = "";
        _psswd = "";
        espMac = '';
        for (int i = 0; i < 30 && dg.data[i] != 0; i++) {
          _ssid = _ssid + utf8.decode([dg.data[i]]);
        }
        for (int i = 30; i < 60 && dg.data[i] != 0; i++) {
          _psswd = _psswd + utf8.decode([dg.data[i]]);
        }
        for (int i = 60; i < 77; i++) {
          espMac = espMac + utf8.decode([dg.data[i]]);
        }

        if (_ssid == wifiParts[0] && _psswd == wifiParts[1]) {
          prefs.setString("ESPMac", espMac);
          startACK();
          setState(() {
            credsMatch = true;
            transmissionDone = true;
            client.close();
          });
        }
      }
    });


    // List<int> udpId = utf8.encode("ESP32");
    // for (int i = 0; i < 5; i++) {
    //   wifiCreds[i] = udpId[i];
    // }

    wifiCreds[0] = 1;

    for (int i = 0; i < wifiParts[0].length; i++) {
      wifiCreds[i+1] = utf8.encode(wifiParts[0][i])[0];
    }
    for (int i = 0; i < 30-wifiParts[0].length; i++) {
      wifiCreds[i+1+wifiParts[0].length] = 0;
    }
    
    for (int i = 0; i < wifiParts[1].length; i++) {
      wifiCreds[i+1+30] = utf8.encode(wifiParts[1][i])[0];
    }
    for (int i = 0; i < 30-wifiParts[1].length; i++) {
      wifiCreds[i+1+30+wifiParts[1].length] = 0;
    }
    
    setState(() {
      
    });


    client.send(wifiCreds, InternetAddress("255.255.255.255"), 8080);
  }

  Future<void> transmitWifiToESP() async {

    Timer? timeoutTimer;
    timeoutTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (transmissionTimedOut) {
        setState(() {
          timerFlip = !timerFlip;
        });
        startTransmission();
        setState(() {
          transmissionTimedOut = false;
        });
      }
      if (transmissionDone) {
        setState(() {
          credsCorrect = true;
        });
        timeoutTimer?.cancel(); 
      }
    });

    // final client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    // client.broadcastEnabled = true;

    // client.listen((event) {
    //   Datagram? dg = client.receive();
    //   if (dg != null) {
    //     String _ssid = "";
    //     String _psswd = "";
    //     for (int i = 0; i < 30 && dg.data[i] != 0; i++) {
    //       _ssid = _ssid + String.fromCharCode(dg.data[i]);
    //     }
    //     for (int i = 30; i < 60 && dg.data[i] != 0; i++) {
    //       _psswd = _psswd + String.fromCharCode(dg.data[i]);
    //     }
        
    //   }
    // });
  }

  void retryIpRetrieval() {
    gotIP = false;
    ipCounter = 0;
    setState(() {
      stage = Stages.ConnectedToWifi;
    });
    getIPAddress();
  }


  @override
  Widget build(BuildContext context) {
    if (!locationStatus) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("Location must be turned on for the app to connect to the ESP32"),
          ElevatedButton(onPressed: openLocationSettings, child: Text("Enable Location")),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("We'll first need to connect to the ESP32 Wifi to tell it the Wifi name and password. "
          "Choose the wifi that starts with 'ESP32_', the password will be last 8 characters of the name."),
          ElevatedButton(onPressed: openWifiSettings, child: Text('Connect')),
          Visibility(
            visible: stage == Stages.ConnectedToESP,
            child: Text("Awesome! Now let's transmit the wifi credentials to the ESP32.")
          ),
          Visibility(
            visible: stage == Stages.ConnectedToESP,
            child: ElevatedButton(
              onPressed: transmitWifiToESP,
              child: Text('Transmit'),
            )
          ),
          Visibility(
            visible: stage == Stages.GotCreds,
            child: Column(
              children: [
                Text("The ESP32 should now be connected to the wifi. Awaiting reconnection to the main wifi. If your phone doesn't automatically reconnect, please connect to the wifi."),
                ElevatedButton(onPressed: openWifiSettings, child: Text('Connect')),
              ]
            )
          ),
          Visibility(
            visible: stage == Stages.Control,
            child: Column(
              children: [
                Text("Everything is setup! Ready to switch to the LED control screen."),
                ElevatedButton(
                  onPressed: widget.switchToControl,
                  child: Text("Switch")),
              ],
            )
          ),
          Visibility(
            visible: stage == Stages.IpRetrievalFailed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Unable to establish a connection with the ESP."),
                Text("Possible causes include:"),
                Text("- The ESP is not properly connected to a power supply. (Make sure it's plugged in to a micro usb cable, and that cable is plugged in to a powered usb port. Then press the try again button.)"),
                Text("- The ESP got the wrong WIFI credentials. (Press the reset connection button.)"),
                Text("- The wifi was unavailable when the ESP was trying to connect. (Plug the ESP out, and plug it back in again. Then press the try again button)")
              ],
            )
          ),
          Visibility(
            visible: stage == Stages.IpRetrievalFailed,
            child: Column(children: [
              ElevatedButton(onPressed: retryIpRetrieval, child: Text("Try Again")),
              ElevatedButton(onPressed: widget.reset, child: Text("Reset Connection"))
            ],)
          ),
          Text(recordedMAc),
          Text(responseMac),
          Text(macCompare.toString()),
          // Text(ipValue.toString()),
          // Text(utf8.decode(ipValue)),
          // Text(wifiCreds.toString()),
          // Text(timerFlip.toString()),
          // Text(transmissionTimedOut.toString()),
          // Text(credsCorrect.toString()),
          // Text(_ssid),
          // Text(_psswd),
        ],
      );
    }
  }
}