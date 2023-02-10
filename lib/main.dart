import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'BLNF.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter QR Code Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter QR Code Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _qrKey = GlobalKey();
  QRViewController? _controller;
  Barcode? _result;
  String? _mac;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _device;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((barcode) {
      setState(() {
        _result = barcode;
        if (_result != null) {
          Map<String, dynamic> data = json.decode(_result!.code ?? "df");
          _mac = data['mac'];
        }
      });
    });
  }

  void _searchForDevice() async {
    if (_mac == null) {
      return;
    }
    List<BluetoothDevice> devices = await flutterBlue.connectedDevices;
    _device = devices.firstWhere((device) => device.id.toString() == _mac,
        orElse: () => BluetoothDeviceNotFound());
    if (_device != null) {
      print('Device found: ${_device!.name}');
    } else {
      const AlertDialog(semanticLabel: 'Device not found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: QRView(
                key: _qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            if (_result != null) ...[
              SizedBox(height: 20),
              Text(
                'Scanned Data: ${_result!.code}',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              Text(
                'Extracted MAC: $_mac',
                style: TextStyle(fontSize: 20),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Search for Device'),
              onPressed: _searchForDevice,
            )
          ],
        ),
      ),
    );
  }
}
