import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'control/control.dart';
import 'connect/connect.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const appTitle = 'Wifi App';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: appTitle,
      home: MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String ip = "";

  int _selectedIndex = 1;
  bool reconnect = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    checkIP();
  }

  Future<void> checkIP() async {
    final prefs = await SharedPreferences.getInstance();
    String? mac = prefs.getString("IP");
    if (mac != null && mac.isNotEmpty) {
      _onItemTapped(0);
    } else {
      _onItemTapped(1);
    }
  }

  void switchToControl() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void askForReconnect() {
    _onItemTapped(1);
    setState(() {
      reconnect = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      Control(ip: ip, askForReconnect: askForReconnect),
      Connect(ip: ip, switchToControl: switchToControl, reconnect: reconnect),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _widgetOptions[_selectedIndex],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Control'),
              selected: _selectedIndex == 0,
              onTap: () {
                // Update the state of the app
                _onItemTapped(0);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Connect'),
              selected: _selectedIndex == 1,
              onTap: () {
                // Update the state of the app
                _onItemTapped(1);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// class Control extends StatefulWidget {
//   @override
//   ControlState createState() => ControlState();
// }

// class ControlState extends State<Control> {
//   @override
//   Widget build(BuildContext context) {
//     return Text('control',
//     textAlign: TextAlign.center,);
//   }
// }



// class Connect extends StatefulWidget {
//   @override
//   ConnectState createState() => ConnectState();
// }

// class ConnectState extends State<Connect> {

//   int _selectedIndex = 0;
//   PageController _pageController = PageController();
//   bool locationGranted = false;
//   bool wifiSelected = false;

//   @override
//   void initState() {
//     super.initState();
//     checkProgress();
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   Future<void> checkProgress() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (prefs.getString("mainWifi") != null) {
//       setState(() {
//         wifiSelected = true;
//       });
//       _onItemTapped(1);
//       return;
//     }

//     final locationCheck = await Permission.location.isGranted;
//     if (locationCheck) {
//       setState(() {
//         locationGranted = true;
//       });
//       _onItemTapped(0);
//     }
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//       _pageController.animateToPage(
//         index,
//         duration: Duration(milliseconds: 300), curve: Curves.easeOut
//       );
//     });
//   }

//   void nextPage() {
//     Future.delayed(Duration(milliseconds: 700), () {
//       setState(() {
//       _selectedIndex = _selectedIndex+1;
//       _pageController.animateToPage(
//         _selectedIndex,
//         duration: Duration(milliseconds: 700), curve: Curves.easeOut
//       );
//     });
//     });
//   }

//   void updateLocation() {
//     if (!locationGranted) {
//       setState(() {
//         locationGranted = true;
//       });
//       nextPage();
//     }
//   }

//   void updateWifi() {
//     if (!wifiSelected) {
//       setState(() {
//         wifiSelected = true;
//       });
//       nextPage();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SizedBox.expand(
//         child: PageView(
//           controller: _pageController,
//           onPageChanged: (index) {
//             setState(() => _selectedIndex = index);
//           },
//           children: [
//             LocationAccess(updateLocation: updateLocation),
//             MainWifi(updateWifi: updateWifi),
//             ESP()
//           ],
//         )
//       ),
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: _onItemTapped,
//         destinations: [
//           NavigationDestination(icon: locationGranted ? Icon(Icons.where_to_vote) : Icon(Icons.location_on), label: "Location"),
//           NavigationDestination(icon: wifiSelected ? Icon(Icons.wifi) : Icon(Icons.wifi_find), label: "Wifi"),
//           NavigationDestination(icon: Icon(Icons.router), label: "ESP32")
//         ],
//       ),
//     );
//   }
// }


// class LocationAccess extends StatefulWidget {

//   final Function() updateLocation;

//   LocationAccess({required this.updateLocation});

//   @override
//   LocationAccessState createState() => LocationAccessState();
// }

// class LocationAccessState extends State<LocationAccess> {

//   bool locationGranted = false;

//   @override
//   void initState() {
//     super.initState();

//     checkLocationGranted();
//   }

//   Future<void> checkLocationGranted() async {
//     bool granted = await Permission.location.isGranted;
//     if (granted == true){
//       setState(() {
//         locationGranted = true;
//         widget.updateLocation();
//         //completed();
//       });
//     }
//   }

//   Future<void> requestLocation() async {
//     await Permission.location.request();
//     checkLocationGranted();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         const Padding(
//           padding: EdgeInsets.only(top: 50, bottom: 10),
//           child: Text(
//           'To handle wifi connections Android requires us to ask for Location access.',
//           textAlign: TextAlign.left,)),
//         ElevatedButton(
//           onPressed: locationGranted ? null : requestLocation,
//           child: const Text('Grant Location Access')),
//         Visibility(
//           visible: locationGranted,
//           child: Align(
//             alignment: Alignment.bottomCenter,
//             child: Icon(Icons.check)
//           ))
//       ],
//     );
//   }
// }


// class MainWifi extends StatefulWidget {

//   final Function() updateWifi;

//   MainWifi({required this.updateWifi});

//   @override
//   MainWifiState createState() => MainWifiState();
// }

// class MainWifiState extends State<MainWifi> {

//   bool canScan = false;
//   bool scanning = false;
//   bool restricted = false;
//   final accessPoints = <WiFiAccessPoint>[];
//   StreamSubscription<List<WiFiAccessPoint>>? subscription;

//   @override
//   void initState() {
//     super.initState();

//     initScan();

//     checkCanScan().listen((event) {
//       if (event) {
//         setState(() {
//           canScan = true;
//         });
//         startScan();
//       } else {
//         setState(() {
//           canScan = false;
//         });
//         subscription?.cancel();
//       }
//     });
//   }

//   Future<void> initScan() async {
//     final can = await WiFiScan.instance.canStartScan();
//     if (can == CanStartScan.yes) {
//       getScanResults();
//       setState(() {
//         canScan = true;
//       });
//     }
//   }

//   Stream<bool> checkCanScan() async* {
//     while (true) {
//       if (await Permission.location.serviceStatus.isDisabled) {
//         setState(() {
//           restricted = true;
//         });
//       } else {
//         setState(() {
//           restricted = false;
//         });
//       }

//       final can = await WiFiScan.instance.canStartScan();
//       if (can == CanStartScan.yes) {
//         yield true;
//       } else {
//         yield false;
//       }
//     }
//   }

//   Future<void> launchIntent() async {
//     AndroidIntent intent = AndroidIntent(
//       action: 'android.settings.LOCATION_SOURCE_SETTINGS',
//     );
//     await intent.launch();
//   }

//   Future<void> startScan() async {
//     bool _scanning = await WiFiScan.instance.startScan();
//     setState(() {
//       scanning = _scanning;
//     });
//   }

//   Future<void> getScanResults() async {
//     accessPoints.clear();
//     accessPoints.addAll(await WiFiScan.instance.getScannedResults());
//     setState(
//       () {
//         accessPoints.removeWhere((element) => element.ssid.isEmpty == true);
//         accessPoints.sort((a,b) => b.level.compareTo(a.level));
//       }
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     subscription?.cancel();
//     setState(() => subscription = null);
//   }

//   Widget wifiList() {
//     if (accessPoints.isEmpty) {
//       return Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(5),
//                     ),
//                     child: CircularCappedProgressIndicator(
//                       strokeWidth: 5,
//                       strokeCap: StrokeCap.round,
//                     )
//                   )
//                 ]
//               );
//     } else {
//       return RawScrollbar(
//         mainAxisMargin: 5,
//         crossAxisMargin: 5,
//         thumbVisibility: true,
//         radius: Radius.circular(5),
//         child: ScrollConfiguration(
//           behavior: MyBehavior(),
//           child: ListView.separated(
//             padding: EdgeInsets.all(10),
//             shrinkWrap: true,
//             itemCount: accessPoints.length,
//             itemBuilder: (context, i) {
//               return WifiTile(wifi: accessPoints[i], updateWifi: widget.updateWifi);
//             },
//             separatorBuilder: (BuildContext context, int index) => const Divider(),
//           ),
//         )
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Visibility(
//           visible: !canScan && !restricted,
//           child: Text("Please wait. Currently unable to scan "
//                       "for wifi due to Android limiting the amount of scans that can be done. "
//                       "Scanning will start as soon as possible."),
//         ),
//         Visibility(
//           visible: restricted,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text("Location has to be turned on for android to allow the app to scan for wifi. Please turn location on."),
//               ElevatedButton(onPressed: launchIntent, child: Text("Enable Location"))
//           ],)
//         ),
//         Visibility(
//           visible: !restricted,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Container(
//                 decoration: const BoxDecoration(
//                   color: Color.fromRGBO(255, 255, 255, 1),
//                   boxShadow: [
//                     BoxShadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 5),
//                   ],
//                   borderRadius: BorderRadius.all(Radius.circular(5))
//                 ),
//                 height: 200,
//                 child: wifiList()
//           ),
//           ElevatedButton(onPressed: getScanResults, child: Icon(Icons.refresh)),
//           ]),
//         ),
//       ],
//     );
//   }
// }

// class WifiTile extends StatefulWidget {
//   final WiFiAccessPoint wifi;
//   final Function() updateWifi;
//   WifiTile({required this.wifi, required this.updateWifi});

//   @override
//   WifiTileState createState() => WifiTileState();
// }


// class WifiTileState extends State<WifiTile> {

//   IconData? signal;
//   final textController = TextEditingController();

//   @override
//   void dispose() {
//     textController.dispose();
//     super.dispose();
//   }

//   Future<void> saveCredentials(wifiPassword) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('mainWifi', "${widget.wifi.ssid}|${wifiPassword}");
//   }

//   @override
//   Widget build(BuildContext context) {
//     switch (widget.wifi.level) {
//       case <= -90:
//         signal = Icons.signal_wifi_0_bar;
//         break;
//       case > -90 && <= -80:
//         signal = Icons.network_wifi_1_bar;
//         break;
//       case > -80 && <= -70:
//         signal = Icons.network_wifi_2_bar;
//         break;
//       case > -70 && <= -67:
//         signal = Icons.network_wifi_3_bar;
//         break;
//       case > -67 && <= -30:
//         signal = Icons.signal_wifi_4_bar;
//         break;
//     }

//     if (widget.wifi.frequency < 5000) {
//       return GestureDetector(
//         onTap: () => showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: Text(
//                 widget.wifi.ssid,
//                 textAlign: TextAlign.center,
//               ),
//               content:
//                 Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("Freq: ${widget.wifi.frequency}MHz"),
//                     Padding(
//                       padding: EdgeInsets.only(bottom: 5),
//                       child: Text("Level: ${widget.wifi.level}"),
//                     ),
//                     TextField(
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(),
//                         hintText: 'Password',
//                       ),
//                       controller: textController,
//                     ),
//                   ]
//                 ),
//               actions: [
//                 FilledButton(
//                   onPressed: () {
//                     if (textController.text.isNotEmpty) {
//                       saveCredentials(textController.text);
//                       widget.updateWifi();
//                       return Navigator.of(context).pop();
//                     }
//                   },
//                   child: Text(
//                     'Save'
//                   ))
//               ],
//               actionsAlignment: MainAxisAlignment.center,
//             );
//           }
//         ),
//         child: WifiTileInfo(wifi: widget.wifi, signalIcon: signal, enabled: true)
//       );
//     } else {
//       return WifiTileInfo(wifi: widget.wifi, signalIcon: signal, enabled: false);
//     }
//   }
// }

// class WifiTileInfo extends StatefulWidget {

//   final WiFiAccessPoint wifi;
//   final IconData? signalIcon;
//   final bool enabled;
//   WifiTileInfo({required this.wifi, required this.signalIcon, required this.enabled});

//   @override
//   WifiTileInfoState createState() => WifiTileInfoState();
// }

// class WifiTileInfoState extends State<WifiTileInfo> {

//   Widget? wifiIcon;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.wifi.capabilities.contains("WPA") || widget.wifi.capabilities.contains("WEP")) {
//       wifiIcon = Stack(
//         alignment: Alignment(1.1, 0.8),
//         children: [
//           Icon(
//             widget.signalIcon,
//             color: widget.enabled ? Colors.grey : const Color.fromARGB(255, 210, 210, 210)
//           ),
//           Icon(
//             Icons.lock,
//             color: widget.enabled ? Colors.grey : const Color.fromARGB(255, 210, 210, 210),
//             size: 8
//           )
//         ],
//       );
//     } else {
//       wifiIcon = Icon(
//                     widget.signalIcon,
//                     color: widget.enabled ? Colors.grey : const Color.fromARGB(255, 210, 210, 210)
//                   );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(left: 10),
//       child: Row(
//         //minVerticalPadding: 1,
//         //leading: Icon(signal),
//         //title: Text(wifi.ssid),
//         children: [
//           Padding(
//             padding: EdgeInsets.only(right: 10),
//             child: wifiIcon
//           ),
//           Padding(
//             padding: EdgeInsets.only(right: 10),
//             child: Text(
//               "${widget.wifi.frequency~/100/10}GHz",
//               style: widget.enabled ? TextStyle(color: Colors.black) : TextStyle(color: Colors.grey),
//             )
//           ),
//           Text(
//             widget.wifi.ssid,
//             style: widget.enabled ? TextStyle(color: Colors.black) : TextStyle(color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
// }


// class MyBehavior extends ScrollBehavior {
//   @override
//   Widget buildOverscrollIndicator(
//       BuildContext context, Widget child, ScrollableDetails details) {
//     return child;
//   }
// }


// class ESP extends StatefulWidget {
//   @override
//   ESPState createState() => ESPState();
// }

// class ESPState extends State<ESP> {
//   @override
//   Widget build(BuildContext context) {
//     return Text('esp');
//   }
// }


    // return GestureDetector(
    //   onTap: () => showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         title: Text(
    //           widget.wifi.ssid,
    //           textAlign: TextAlign.center,
    //         ),
    //         content:
    //           Column(
    //             mainAxisSize: MainAxisSize.min,
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               Text("Freq: ${widget.wifi.frequency}MHz"),
    //               Padding(
    //                 padding: EdgeInsets.only(bottom: 5),
    //                 child: Text("Level: ${widget.wifi.level}"),
    //               ),
    //               TextField(
    //                 decoration: InputDecoration(
    //                   border: OutlineInputBorder(),
    //                   hintText: 'Password',
    //                 ),
    //                 controller: textController,
    //             ),]
    //           ),
    //         actions: [
    //           FilledButton(
    //             onPressed: () => Navigator.of(context).pop(),
    //             child: Text(
    //               'Save'
    //             ))
    //         ],
    //         actionsAlignment: MainAxisAlignment.center,
    //       );
    //     }
    //   ),
    //   child: Padding(
    //     padding: EdgeInsets.only(left: 10),
    //     child: Row(
    //       //minVerticalPadding: 1,
    //       //leading: Icon(signal),
    //       //title: Text(wifi.ssid),
    //       children: [
    //         Padding(
    //           padding: EdgeInsets.only(right: 10),
    //           child: Icon(
    //             signal,
    //             color: Colors.grey
    //           )
    //         ),
    //         Padding(
    //           padding: EdgeInsets.only(right: 10),
    //           child: Text(
    //             "${widget.wifi.frequency~/100/10}GHz"
    //           )
    //         ),
    //         Text(widget.wifi.ssid),
    //       ],
    //     ),
    //   ),
    // );


// bool locationGranted = false;

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     locationIsGranted();
//   }


// CHECK WIFI

// Future<void> locationIsGranted() async {
//   bool granted = await Permission.location.isGranted;
//   setState(() {
//     locationGranted = granted;
//   });
// }


// GET WIFI

// const Text(
//         "Android doesn't allow access to stored wifi passwords. "
//         "To connect the ESP32 to the internet we'll need to get "
//         "the wifi name and password. Please select the wifi from "
//         "the list, and enter the password when prompted.",
//         textAlign: TextAlign.left,
//       )


// WIFI ACCESS PERMISSION

// @override
// Widget build(BuildContext context) {
//   return Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const Text(
//               'To handle wifi connections Android requires us to ask for Location access.',
//               textAlign: TextAlign.left,),
//             ElevatedButton(
//               onPressed: grantLocationAccess,
//               child: const Text('Grant Location Access'))
//           ],
//         );
// }

// Future<void> grantLocationAccess() async {
//   await Permission.location.request();
//   bool granted = await Permission.location.isGranted;
//   if (granted) {

//   }
// }
