import 'dart:async';
import 'dart:convert';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter BLE Example'),
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
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubscription;
  Map<DeviceIdentifier, ScanResult> scanResults = new Map();
  bool isScanning = false;
  BluetoothDevice? device;
  bool isConnected = false;
  BluetoothDevice? selectedDevice;
  final GlobalKey _qrKey = GlobalKey();
  QRViewController? _controller;
  Barcode? _result;
  String? _mac;

  @override
  void dispose() {
    _controller?.dispose();
    flutterBlue.stopScan();
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

  // void startScan() {
  //   setState(() {
  //     isScanning = true;
  //   });

  //   scanSubscription = flutterBlue.scan().listen((scanResult) {
  //     setState(() {
  //       scanResults[scanResult.device.id] = scanResult;
  //     });
  //   }, onDone: stopScan);
  // }

  void startScan(String _mac) {
    setState(() {
      isScanning = true;
    });

    scanSubscription = flutterBlue
        .scan(
          timeout: Duration(seconds: 5),
        )
        .where((scanResult) => scanResult.device.id.toString() == _mac)
        .listen((scanResult) {
      setState(() {
        scanResults[scanResult.device.id] = scanResult;
      });
    }, onDone: stopScan);
  }

  void stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
    setState(() {
      isScanning = false;
    });
  }

  void connect(BluetoothDevice d) async {
    device = d;
    device?.connect();
    setState(() {
      isConnected = true;
    });
  }

  void disconnect() {
    device?.disconnect();
    setState(() {
      isConnected = false;
    });
  }

  void extractPairKey() async {
    try {
      await device!.requestMtu(23);
      print('MTU Requested');
    } catch (e) {
      print('Error Requesting MTU: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
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
            Container(
              child: ElevatedButton(
                child: Text('Start Scan'),
                onPressed: isScanning ? null : () => startScan(_mac!),
              ),
            ),
            Container(
              child: ElevatedButton(
                child: Text('Stop Scan'),
                onPressed: isScanning ? stopScan : null,
              ),
            ),
            Container(
              child: ElevatedButton(
                child: Text('Connect'),
                onPressed: isConnected || selectedDevice == null
                    ? null
                    : () => connect(selectedDevice!),
              ),
            ),
            Container(
              child: ElevatedButton(
                child: Text('Disconnect'),
                onPressed: isConnected ? disconnect : null,
              ),
            ),
            Container(
              child: ElevatedButton(
                child: Text('Extract Pair Key'),
                onPressed: isConnected ? extractPairKey : null,
              ),
            ),
            Expanded(
              child: ListView(
                children: scanResults.values
                    .map((r) => ListTile(
                          title: Text(r.device.name),
                          subtitle: Text(r.device.id.toString()),
                          onTap: () =>
                              setState(() => selectedDevice = r.device),
                        ))
                    .toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  // @override
  // void dispose() {
  //   flutterBlue.stopScan();
  //   super.dispose();
  // }
}
