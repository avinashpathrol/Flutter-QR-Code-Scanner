import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:logger/logger.dart';

class DeviceInfoPage extends StatefulWidget {
  final BluetoothDevice device;
  final filePath = '/path/to/file/finch2-esp-firmware_v1.0.14.bin';

  DeviceInfoPage({required this.device});

  @override
  _DeviceInfoPageState createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  List<BluetoothService> _services = [];
  List<Widget> _serviceTiles = [];
  String _deviceName = '';
  String _deviceID = '';
  String _characteristicValue = '';
  String jsonStr = '';
  String _espAppVer = '';
  String _hasVersion = '';
  String valueString = '';
  String _fetchedData = '';
  String _firstValue = '';
  late String _fileName;
  late String _versionNumber;

  @override
  void initState() {
    super.initState();
    _discoverServices();
    _getFileName();
    _readCharacteristic();
  }

  void _getFileName() {
    _fileName = widget.filePath.split('/').last;
    RegExp regex = RegExp(r'v([\d.]+)\.bin');
    Match? match = regex.firstMatch(_fileName);

    if (match != null) {
      setState(() {
        _fileName = _fileName;
        _versionNumber = match.group(1)!;
      });
    }
  }

  void _discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    List<ListTile> tiles = [];

    for (BluetoothService service in services) {
      List<BluetoothCharacteristic> characteristics = service.characteristics;
      List<ListTile> charTiles = [];

      for (BluetoothCharacteristic characteristic in characteristics) {
        charTiles.add(
          ListTile(
            title: Text(characteristic.uuid.toString()),
            subtitle: Text(characteristic.properties.toString()),
            onTap: () async {
              if (characteristic.uuid.toString() ==
                  'bf99ace8-16e9-4b40-9c05-acea06a4a29b') {
                await characteristic.setNotifyValue(true);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Notify Enabled"),
                      content: Text(
                          "Notify has been enabled for characteristic with UUID bf99ace8-16e9-4b40-9c05-acea06a4a29b."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await characteristic.write([0x50, 0xfe]);
                            Navigator.pop(context);
                          },
                          child: Text("OK"),
                        ),
                      ],
                    );
                  },
                ).then((value) async {
                  if (value == false) {
                    await characteristic.setNotifyValue(false);
                  }
                });
              } else {
                List<int> value = await characteristic.read();
                setState(() {
                  _characteristicValue = String.fromCharCodes(value);
                });
              }
            },
          ),
        );
      }

      tiles.add(
        ListTile(
          title: Text(service.uuid.toString()),
          subtitle: Column(
            children: charTiles,
          ),
        ),
      );
    }

    setState(() {
      _services = services;
      _serviceTiles = tiles;
    });
  }

  Future<void> _readCharacteristic() async {
    String uuid = 'cf85a57c-5e71-491a-9c4f-2ce109df5c6b';
    // Set MTU to increase the amount of data that can be received
    await widget.device.requestMtu(512);

    List<BluetoothService> services = await widget.device.discoverServices();
    for (BluetoothService service in services) {
      List<BluetoothCharacteristic> characteristics = service.characteristics;
      for (BluetoothCharacteristic characteristic in characteristics) {
        if (characteristic.uuid.toString().toUpperCase() ==
            uuid.toUpperCase()) {
          List<int> value = await characteristic.read();
          setState(() {
            _characteristicValue = String.fromCharCodes(value);
            _fetchedData = _characteristicValue;

            // Parse the JSON and get the value of the first key
            Map<String, dynamic> jsonMap = jsonDecode(_characteristicValue);
            _firstValue = jsonMap.values.first;

            if (_firstValue.compareTo(_versionNumber) < 0) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Update Firmware?'),
                  content: Text(
                      'A new firmware version ($_versionNumber) is available. Do you want to update?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Perform firmware update
                        Navigator.of(context).pop();
                      },
                      child: Text('Update'),
                    ),
                  ],
                ),
              );
            }
          });
          return;
        }
      }
    }
    throw Exception('Characteristic not found');
  }
  // Future<void> _readCharacteristic() async {
  //   String uuid = 'cf85a57c-5e71-491a-9c4f-2ce109df5c6b';
  //   // Set MTU to increase the amount of data that can be received
  //   await widget.device.requestMtu(512);

  //   List<BluetoothService> services = await widget.device.discoverServices();
  //   BluetoothCharacteristic? notifiableCharacteristic;
  //   for (BluetoothService service in services) {
  //     List<BluetoothCharacteristic> characteristics = service.characteristics;
  //     for (BluetoothCharacteristic characteristic in characteristics) {
  //       if (characteristic.uuid.toString().toUpperCase() ==
  //           uuid.toUpperCase()) {
  //         List<int> value = await characteristic.read();
  //         setState(() {
  //           _characteristicValue = String.fromCharCodes(value);
  //           _fetchedData = _characteristicValue;

  //           // Parse the JSON and get the value of the first key
  //           Map<String, dynamic> jsonMap = jsonDecode(_characteristicValue);
  //           _firstValue = jsonMap.values.first;

  //           if (_firstValue.compareTo(_versionNumber) < 0) {
  //             showDialog(
  //               context: context,
  //               builder: (context) => AlertDialog(
  //                 title: Text('Update Firmware?'),
  //                 content: Text(
  //                     'A new firmware version ($_versionNumber) is available. Do you want to update?'),
  //                 actions: [
  //                   TextButton(
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                     },
  //                     child: Text('Cancel'),
  //                   ),
  //                   TextButton(
  //                     onPressed: () {
  //                       // Perform firmware update
  //                       Navigator.of(context).pop();
  //                     },
  //                     child: Text('Update'),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }
  //         });
  //         // Turn on notifications for the characteristic
  //         await characteristic.setNotifyValue(true);
  //         notifiableCharacteristic = characteristic;
  //         break;
  //       } else if (characteristic.properties.notify) {
  //         notifiableCharacteristic ??= characteristic;
  //       }
  //     }
  //   }
  //   if (notifiableCharacteristic != null) {
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('Notifiable Characteristic'),
  //         content: Text(
  //             'The characteristic with UUID ${notifiableCharacteristic!.uuid} is notifiable. Notifications turned on.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Close'),
  //           ),
  //         ],
  //       ),
  //     );
  //   } else {
  //     throw Exception('Characteristic not found');
  //   }
  // }

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
            SizedBox(
              height: 30,
            ),
            Text(
              _characteristicValue.isNotEmpty
                  ? ' Device Information: $_characteristicValue'
                  : 'Click the button to read the characteristic',
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              _firstValue != null
                  ? 'Curretn Firmare Version: $_firstValue'
                  : 'No value found',
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              _fileName != null
                  ? 'New Firemare File Name: $_fileName'
                  : 'No value found',
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              _versionNumber != null
                  ? 'New Firemare File Version Number: $_versionNumber'
                  : 'No value found',
            ),
            ..._serviceTiles,
          ],
        ),
      ),
    );
  }
}
