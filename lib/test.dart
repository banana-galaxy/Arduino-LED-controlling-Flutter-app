import 'dart:io';
import 'dart:convert';

void main() async {

  // var DESTINATION_ADDRESS=InternetAddress("255.255.255.255");

  // RawDatagramSocket.bind(InternetAddress.anyIPv4, 8080).then((RawDatagramSocket udpSocket) {
  //   udpSocket.broadcastEnabled = true;
  //   udpSocket.listen((e) {
  //     Datagram? dg = udpSocket.receive();
  //     if (dg != null) {
  //       print("received ${utf8.decode(dg.data)}\n${dg.address}");
  //     }
  //   });
  //   List<int> data =utf8.encode('TEST');
  //   udpSocket.send(data, DESTINATION_ADDRESS, 8080);
  // });

  final client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

  client.broadcastEnabled = true;

  client.listen((event) {
    Datagram? dg = client.receive();
    if (dg != null) {
      print("received ${utf8.decode(dg.data)}\n${dg.address}");
    }
  });


  List<int> data =utf8.encode('TESTing');
  var DESTINATION_ADDRESS=InternetAddress("255.255.255.255");
  client.send(data, DESTINATION_ADDRESS, 8080);

  await Future.delayed(Duration(seconds: 2));

  client.close();
  
}