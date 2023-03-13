import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> scanResults = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    print('Starting scan');
    flutterBlue.scan(timeout: Duration(seconds: 5)).listen((scanResult) {
      print('Scan result: ${scanResult.device.name} ${scanResult.device.id}');
      setState(() {
        scanResults.add(scanResult);
      });
    }, onDone: () {
      print('Scan complete');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Scanner'),
      ),
      body: ListView.builder(
        itemCount: scanResults.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(scanResults[index].device.name),
            subtitle: Text(scanResults[index].device.id.toString()),
          );
        },
      ),
    );
  }
}
