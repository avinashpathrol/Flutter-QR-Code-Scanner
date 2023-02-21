import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class DeviceInfoPage extends StatefulWidget {
  final BluetoothDevice device;

  DeviceInfoPage({required this.device});

  @override
  _DeviceInfoPageState createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  List<BluetoothService> _services = [];
  String _deviceName = '';
  String _deviceID = '';
  String _characteristicValue = '';
  String _espAppVer = '';
  String _hasVersion = '';
  String valueString = '';

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  void _discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    setState(() {
      _services = services;
    });
  }

  // Future<void> _readCharacteristic(
  //     BluetoothCharacteristic characteristic) async {
  //   List<int> value = await characteristic.read();
  //   print('Read value: $value');
  // }

  // Future<void> _readCharacteristic(String uuid) async {
  //   List<BluetoothService> services = await widget.device.discoverServices();
  //   for (BluetoothService service in services) {
  //     List<BluetoothCharacteristic> characteristics = service.characteristics;
  //     for (BluetoothCharacteristic characteristic in characteristics) {
  //       if (characteristic.uuid.toString().toUpperCase() ==
  //           uuid.toUpperCase()) {
  //         List<int> value = await characteristic.read();
  //         setState(() {
  //           _characteristicValue = String.fromCharCodes(value);
  //         });
  //         return;
  //       }
  //     }
  //   }
  //   throw Exception('Characteristic not found');
  // }

  Future<void> _readCharacteristic(String uuid) async {
    List<BluetoothService> services = await widget.device.discoverServices();
    for (BluetoothService service in services) {
      List<BluetoothCharacteristic> characteristics = service.characteristics;
      for (BluetoothCharacteristic characteristic in characteristics) {
        if (characteristic.uuid.toString().toUpperCase() ==
            uuid.toUpperCase()) {
          List<int> value = await characteristic.read();
          setState(() {
            _characteristicValue = String.fromCharCodes(value);
          });
          var json = jsonDecode(_characteristicValue);
          var values = json.values.toList();
          var valueString = values.join(', ');
          print('Values: $valueString');
          return;
        }
      }
    }
    throw Exception('Characteristic not found');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name ?? 'Unknown Device'),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Device Name'),
              subtitle: Text(widget.device.name ?? 'Unknown'),
            ),
            ListTile(
              title: Text('Device ID'),
              subtitle: Text(widget.device.id.toString()),
            ),
            ListTile(
              title: Text('Services :'),
            ),
            Column(
              children: _services
                  .map((s) => Card(
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              title: Text(s.uuid.toString()),
                            ),
                            Column(
                                // children: s.characteristics
                                //     .map((c) => ListTile(
                                //           title: Text(c.uuid.toString()),
                                //           subtitle: Text(
                                //             'Properties: ${c.properties.toString().split('.').last}',
                                //           ),
                                //         ))
                                //     .toList(),
                                ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            ElevatedButton(
              child: Text('Read Characteristic'),
              onPressed: () {
                _readCharacteristic('cf85a57c-5e71-491a-9c4f-2ce109df5c6b');
              },
            ),
            Text(
              _characteristicValue.isNotEmpty
                  ? ' Value: $_characteristicValue'
                  : 'Click the button to read the characteristic',
            ),
            Text(
              _espAppVer != null
                  ? 'ESP App Version: $_espAppVer'
                  : 'No ESP App Version found',
            ),
            Text(
              'Values: $valueString',
            ),
          ],
        ),
      ),
    );
  }
}
