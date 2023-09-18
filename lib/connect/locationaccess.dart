import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationAccess extends StatefulWidget {

  final Function() updateLocation;

  LocationAccess({required this.updateLocation});

  @override
  LocationAccessState createState() => LocationAccessState();
}

class LocationAccessState extends State<LocationAccess> {

  bool locationGranted = false;

  @override
  void initState() {
    super.initState();

    checkLocationGranted();
  }

  Future<void> checkLocationGranted() async {
    bool granted = await Permission.location.isGranted;
    if (granted == true){
      setState(() {
        locationGranted = true;
        widget.updateLocation();
        //completed();
      });
    }
  }

  Future<void> requestLocation() async {
    await Permission.location.request();
    checkLocationGranted();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 50, bottom: 10),
          child: Text(
          'To handle wifi connections Android requires us to ask for Location access.',
          textAlign: TextAlign.left,)),
        ElevatedButton(
          onPressed: locationGranted ? null : requestLocation,
          child: const Text('Grant Location Access')),
        Visibility(
          visible: locationGranted,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Icon(Icons.check)
          ))
      ],
    );
  }
}