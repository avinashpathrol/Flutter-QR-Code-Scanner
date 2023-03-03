// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'NewPage.dart' as page;

class DeviceInfoPage extends StatefulWidget {
  final BluetoothDevice device;
  final filePath = '/path/to/file/finch2-esp-test_v1.0.1.bin';

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
                      title: Text("Notify Response"),
                      content: StreamBuilder<List<int>>(
                        stream: characteristic.value,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<int>> snapshot) {
                          if (snapshot.hasData) {
                            List<int> data = snapshot.data!;
                            if (data.length >= 3 && data[2] == 17) {
                              return Text(
                                  "Received notification with user value ${data.toString()}");
                            } else {
                              return Text("Waiting for notification...");
                            }
                          } else {
                            return Text("Waiting for notification...");
                          }
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("OK"),
                        ),
                      ],
                    );
                  },
                );
                await characteristic.write([0x50, 0xfe]);
                await Future.delayed(Duration(seconds: 1));
                BluetoothCharacteristic char38db = _services
                    .expand((service) => service.characteristics)
                    .firstWhere(
                        (characteristic) =>
                            characteristic.uuid.toString() ==
                            '38db34b0-c66a-4662-b8ad-9a63b5485a9a', orElse: () {
                  throw Exception('Characteristic not found.');
                });

                await char38db.setNotifyValue(true);
                if (char38db != null) {
                  await char38db.setNotifyValue(true);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Notification Enabled"),
                        content: Text(
                            "Notification for ${char38db.uuid.toString()} is now enabled."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
              } else if (characteristic.uuid.toString() ==
                  '38db34b0-c66a-4662-b8ad-9a63b5485a9a') {
                await characteristic.setNotifyValue(true);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Notification Enabled"),
                      content: Text(
                          "Notification for ${characteristic.uuid.toString()} is now enabled."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("OK"),
                        ),
                      ],
                    );
                  },
                );
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

  void LFTDATA() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    BluetoothCharacteristic? characteristic1;

    BluetoothCharacteristic? characteristic2;

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == '38db34b0-c66a-4662-b8ad-9a63b5485a9a') {
          characteristic1 = c;
          await characteristic1.setNotifyValue(true);
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Notify Enabled"),
                content: Text(
                    "Notify has been enabled for characteristic with UUID 38db34b0-c66a-4662-b8ad-9a63b5485a9a."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Cancel"),
                  ),
                ],
              );
            },
          );
        } else if (c.uuid.toString() ==
            'bf99ace8-16e9-4b40-9c05-acea06a4a29b') {
          characteristic2 = c;
        }
      }
    }

    if (characteristic1 == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Characteristic Not Found"),
            content: Text(
                "The characteristic with UUID 38db34b0-c66a-4662-b8ad-9a63b5485a9a was not found on this device."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    // File handling code
    ByteData firmwareFile;
    try {
      firmwareFile =
          await rootBundle.load('images/finch2-esp-firmware_v1.1.3.bin');
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("File Not Found"),
            content: Text(
                "The firmware file was not found in the project directory."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    // Get the bytes from the loaded file
    List<int> bytes = firmwareFile.buffer.asUint8List();

    // Display the filename in the UI
    setState(() {
      _characteristicValue = "Sending file: finch2-esp-test_v1.0.1.binn";
    });

    // Set MTU to increase the amount of data that can be sent
    await widget.device.requestMtu(512);

// Send each packet to the characteristic
    int packetSize = 490;
    int numPackets = (bytes.length / packetSize).ceil();
    int packetIndex = 0;
    int _progress = 0;
    while (packetIndex < numPackets) {
      int start = packetIndex * packetSize;
      int end = (packetIndex == numPackets - 1)
          ? bytes.length
          : (packetIndex + 1) * packetSize;
      List<int> packet = bytes.sublist(start, end);

      await characteristic1.write(packet);

      packetIndex++;

      // Update progress
      setState(() {
        _progress = (packetIndex / numPackets * 100).toInt();
      });
    }

// Send write request to characteristic with UUID 'bf99ace8-16e9-4b40-9c05-acea06a4a29b'
    BluetoothCharacteristic? writeCharacteristic;
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == 'bf99ace8-16e9-4b40-9c05-acea06a4a29b') {
          writeCharacteristic = c;
          await writeCharacteristic.write([0x52, 0xfe]);
        }
      }
    }
    Reboot();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Characteristic Not Found"),
          content: Text(
              "The characteristic with UUID bf99ace8-16e9-4b40-9c05-acea06a4a29b was not found on this device."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void Reboot() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    BluetoothCharacteristic? characteristic1;
    BluetoothCharacteristic? characteristic2;

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == 'bf99ace8-16e9-4b40-9c05-acea06a4a29b') {
          characteristic1 = c;
          await characteristic1.setNotifyValue(true);
          characteristic1.value.listen((value) async {
            if (value.length >= 3 && value[2] == 0) {
              // Send write request with hex code 0x80
              for (BluetoothCharacteristic c in service.characteristics) {
                if (c.uuid.toString() ==
                    '38db34b0-c66a-4662-b8ad-9a63b5485a9a') {
                  characteristic2 = c;
                  await characteristic2?.write([0x80]);
                  break;
                }
              }
            } else if (value.length >= 3 && value[2] == 2) {
              // Send write request with hex code 0x82
              for (BluetoothCharacteristic c in service.characteristics) {
                if (c.uuid.toString() ==
                    '38db34b0-c66a-4662-b8ad-9a63b5485a9a') {
                  characteristic2 = c;
                  await characteristic2?.write([0x82]);
                  break;
                }
              }
            }

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Reboot Response"),
                  content: Text(
                      "Received notification with value ${value.toString()}"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("OK"),
                    ),
                  ],
                );
              },
            );
          });
          await characteristic1.write([0x81, 0xf0]);
          break;
        }
      }
      if (characteristic1 != null && characteristic2 != null) {
        break;
      }
    }

    if (characteristic1 == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Characteristic Not Found"),
            content: Text(
                "The characteristic with UUID bf99ace8-16e9-4b40-9c05-acea06a4a29b was not found on this device."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    if (characteristic2 == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Characteristic Not Found"),
            content: Text(
                "The characteristic with UUID 38db34b0-c66a-4662-b8ad-9a63b5485a9a was not found on this device."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Reboot"),
          content: Text("A reboot command has been sent to the device."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<String> getFilePath() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String filePath =
        '${appDocumentsDirectory.path}/finch2-esp-firmware_v1.0.14.bin';
    return filePath;
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

  void downloadAndSaveFile() async {
    var url =
        'https://drive.google.com/u/0/uc?id=1KFvzbARDQDyrt1ZoaypDiCigdC7GOg41&export=download';
    var response = await http.get(Uri.parse(url));

    // Get the app documents directory
    var appDocumentsDirectory = await getApplicationDocumentsDirectory();

    // Create the file and write the response to it
    var file = File('${appDocumentsDirectory.path}/finch2-esp-test_v1.0.1.bin');
    await file.writeAsBytes(response.bodyBytes);
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
            ElevatedButton(
                onPressed: () {
                  LFTDATA();
                },
                child: Text('Send data'))
          ],
        ),
      ),
    );
  }
}
