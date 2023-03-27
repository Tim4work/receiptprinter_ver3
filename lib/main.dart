import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

List<CameraDescription>? cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? controller;
  String imagePath = "";
  final flutterReactiveBle = FlutterReactiveBle();
  FlutterReactiveBle get _ble => flutterReactiveBle;
  final List<DiscoveredDevice> _devices = [];
  bool _scanStarted = false;
  late StreamSubscription<DiscoveredDevice> _scanStream;

  scan() async {
    setState(() {
      _scanStarted = true;
    });
    _devices.clear();
    _scanStream = _ble.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
      final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        _devices[knownDeviceIndex] = device;
      } else {
        _devices.add(device);
        setState(() {});
      }
    });
    _ble.statusStream.listen((event) {
      debugPrint(event.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras![1], ResolutionPreset.medium);
    controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(children: [
            const SizedBox(
              height: 50,
            ),
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(bottom: 50),
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: CameraPreview(controller!),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  try {
                    final image = await controller!.takePicture();
                    setState(() {
                      imagePath = image.path;
                    });
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text(
                  "사진을 찍으세요!!",
                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.w700),
                )),
            if (imagePath != "")
              SizedBox(
                  width: 75,
                  height: 100,
                  child: Image.file(
                    File(imagePath),
                  )),
            if (_devices.isNotEmpty)
              ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < _devices.length; i++)
                    ListTile(title: Text(_devices[i].name))
                ],
              )
          ]),
        ),
      ),
      persistentFooterButtons: [
        ElevatedButton(
            onPressed: () {
              scan();
            },
            child: const Text("스캔"))
      ],
    );
  }
}
