import 'package:flutter_blue/flutter_blue.dart';

class BluetoothDeviceNotFound implements BluetoothDevice {
  @override
  String get name => "Device not found";

  @override
  // TODO: implement canSendWriteWithoutResponse
  Future<bool> get canSendWriteWithoutResponse => throw UnimplementedError();

  @override
  Future<void> connect({Duration? timeout, bool autoConnect = true}) {
    // TODO: implement connect
    throw UnimplementedError();
  }

  @override
  Future disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future<List<BluetoothService>> discoverServices() {
    // TODO: implement discoverServices
    throw UnimplementedError();
  }

  @override
  // TODO: implement isDiscoveringServices
  Stream<bool> get isDiscoveringServices => throw UnimplementedError();

  @override
  // TODO: implement mtu
  Stream<int> get mtu => throw UnimplementedError();

  @override
  Future<void> requestMtu(int desiredMtu) {
    // TODO: implement requestMtu
    throw UnimplementedError();
  }

  @override
  // TODO: implement services
  Stream<List<BluetoothService>> get services => throw UnimplementedError();

  @override
  // TODO: implement state
  Stream<BluetoothDeviceState> get state => throw UnimplementedError();

  @override
  // TODO: implement type
  BluetoothDeviceType get type => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
