import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locationaccess.dart';
import 'mainwifi.dart';
import 'esp.dart';

class Connect extends StatefulWidget {

  final Function() switchToControl;
  String ip;
  bool reconnect;

  Connect({required this.ip, required this.switchToControl, required this.reconnect});

  @override
  ConnectState createState() => ConnectState();
}

class ConnectState extends State<Connect> {

  int _selectedIndex = 0;
  PageController _pageController = PageController();
  bool locationGranted = false;
  bool wifiSelected = false;

  @override
  void initState() {
    super.initState();
    checkProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> checkProgress() async {
    final prefs = await SharedPreferences.getInstance();
    String? wifiCreds = prefs.getString("mainWifi");
    if (wifiCreds != null && wifiCreds.isNotEmpty) {
      setState(() {
        wifiSelected = true;
      });
      _onItemTapped(1);
      return;
    }

    final locationCheck = await Permission.location.isGranted;
    if (locationCheck) {
      setState(() {
        locationGranted = true;
      });
      _onItemTapped(0);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut
      );
    });
  }

  void nextPage() {
    Future.delayed(Duration(milliseconds: 700), () {
      setState(() {
      _selectedIndex = _selectedIndex+1;
      _pageController.animateToPage(
        _selectedIndex,
        duration: Duration(milliseconds: 700), curve: Curves.easeOut
      );
    });
    });
  }

  void updateLocation() {
    if (!locationGranted) {
      setState(() {
        locationGranted = true;
      });
      nextPage();
    }
  }

  void updateWifi() {
    if (!wifiSelected) {
      setState(() {
        wifiSelected = true;
      });
      nextPage();
    }
  }

  Future<void> reset() async {
    setState(() {
      wifiSelected = false;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("mainWifi", "");
    _onItemTapped(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _selectedIndex = index);
          },
          children: [
            LocationAccess(updateLocation: updateLocation),
            MainWifi(updateWifi: updateWifi),
            ESP(ip: widget.ip, switchToControl: widget.switchToControl, reset: reset, reconnect: widget.reconnect),
          ],
        )
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(icon: locationGranted ? Icon(Icons.where_to_vote) : Icon(Icons.location_on), label: "Location"),
          NavigationDestination(icon: wifiSelected ? Icon(Icons.wifi) : Icon(Icons.wifi_find), label: "Wifi"),
          NavigationDestination(icon: Icon(Icons.router), label: "ESP32")
        ],
      ),
    );
  }
}