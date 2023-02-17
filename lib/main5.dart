import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
  String? advertisementDataJson;
  var serviceData;
  String? passkey;
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

  void startScan(String _mac) {
    setState(() {
      isScanning = true;
    });

    scanSubscription = flutterBlue
        .scan(
          timeout: Duration(seconds: 5),
        )
        .where((scanResult) =>
            scanResult.device.id.toString().toUpperCase() == _mac.toUpperCase())
        .listen((scanResult) {
      setState(() {
        scanResults[scanResult.device.id] = scanResult;
        flutterBlue.scan(timeout: Duration(seconds: 5)).listen((scanResult) {
          setState(() {
            scanResults[scanResult.device.id] = scanResult;
            // Extract advertising data
            var advData = scanResult.advertisementData;
            // var advData = scanResults[selectedDevice!.id]?.advertisementData;
            serviceData =
                scanResults[selectedDevice!.id]?.advertisementData?.serviceData;
            if (advData != null) {
              print(
                  '---------------------------------Advertising data-------------------------: $advData');
            }
          });
        }, onDone: stopScan);
      });
    }, onDone: stopScan);
  }

//  00006a89-0000-1000-8000-00805f9b34fb:[177,70]

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
            SizedBox(height: 20),
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
            ),
            SizedBox(height: 20),
            Text(
              'Passkey: $passkey',
              style: TextStyle(fontSize: 20),
            ),
            if (selectedDevice != null &&
                scanResults.containsKey(selectedDevice!.id)) ...[
              SizedBox(height: 20),
              Text(
                'Advertisment Data:',
                style: TextStyle(fontSize: 20),
              ),
              Text(
                '${scanResults[selectedDevice!.id]?.advertisementData}',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'Service Data:',
                style: TextStyle(fontSize: 20),
              ),
              Text(
                '${scanResults[selectedDevice!.id]?.advertisementData?.serviceData}',
                style: TextStyle(fontSize: 20),
              ),
              Text(
                '${serviceData}',
                style: TextStyle(fontSize: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // static String getNiceHexArray(List<int> bytes) {
  //   return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
  //       .toUpperCase();
  // }

  // String? getPasskeyFromServiceData(
  //     Map<String, List<int>>? data, TargetPlatform android) {
  //   if (data!.isEmpty) {
  //     return null;
  //   }
  //   List<String> res = [];
  //   data?.forEach((id, bytes) {
  //     res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
  //   });
  //   var rand = getSercureRandom(res.join(', '));
  //   var passkey = getSercurePassKey(rand);
  //   var passkeyStr = passkey.toString();
  //   if (passkeyStr.length < 6) {
  //     int shortNum = 6 - passkeyStr.length;
  //     for (var i = 0; i < shortNum; i++) {
  //       passkeyStr = '0' + passkeyStr.toString();
  //     }
  //   }
  //   return passkeyStr.toString();
  // }

  // static int getSercureRandom(String? serviceData) {
  //   int random = 0;
  //   if (serviceData != null) {
  //     var serviceDataArray = serviceData.split(':');
  //     var idArray = serviceDataArray[0].split('-');
  //     var idFirst = idArray[0];
  //     // var idHex = platform == TargetPlatform.android
  //     // ? idFirst.substring(4, 8)
  //     // : idFirst;
  //     var childArray = serviceDataArray[1].split(',');
  //     var childFirst = childArray[0].substring(2, 4);
  //     var childSecond = childArray[1].substring(1, 3);
  //     var hex = childSecond + childFirst;
  //     // equivalent to Uint32 in c
  //     print(int.parse(childSecond.toLowerCase(), radix: 16));
  //     print(int.parse(childFirst.toLowerCase(), radix: 16));
  //     print(int.parse(childFirst.toLowerCase(), radix: 16));
  //     print(hex.toLowerCase());
  //     random = int.parse(hex.toLowerCase(), radix: 16);
  //     random = random.toUnsigned(32);
  //     print(random);
  //   }

  //   return random;
  // }

  // static int getSercurePassKey(int rand) {
  //   String secure = '1R!ngT0Rul3Them@l!'; // equivalent to char in c
  //   int secLen = secure.length;
  //   int randIdx = 0;
  //   Uint8List pk = Uint8List(4);
  //   pk[0] = (rand >> 24) & 0xff;
  //   pk[1] = (rand >> 8) & 0xff;
  //   pk[2] = (rand >> 16) & 0xff;
  //   pk[3] = rand & 0xff;
  //   for (int i = 0; i < secLen; i++) {
  //     pk[randIdx] ^= secure.codeUnitAt(i);
  //     if (++randIdx >= 4) randIdx = 0;
  //   }
  //   int passKey = (pk[1] << 24) | (pk[3] << 16) | (pk[0] << 8) | pk[2];
  //   passKey %= 1000000;
  //   return passKey;
  // }
}
