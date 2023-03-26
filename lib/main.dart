import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';


List<CameraDescription>? cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
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
          child: Column(
            children: [
              SizedBox(
                height: 50,
              ),
              Container(
                width: 600,
                height: 800,
                margin: EdgeInsets.only(bottom: 50),
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
                  child: Text("사진을 찍으세요!!", style: TextStyle(fontSize: 60, fontWeight: FontWeight.w700), )
              ),
              if (imagePath != "")
                Container(
                    width: 75,
                    height: 100,
                    child: Image.file(
                      File(imagePath),
                    ))
            ],
          ),
        ),
      ),
    );
  }
}
