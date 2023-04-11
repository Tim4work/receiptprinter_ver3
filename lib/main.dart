import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:oktoast/oktoast.dart';
import 'package:camera/camera.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Bluetooth demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Bluetooth demo'),
      ),
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
  PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras![1],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    printerManager.scanResults.listen((devices) async {
      // print('UI: Devices found ${devices.length}');
      setState(() {
        _devices = devices;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _startScanDevices() {
    setState(() {
      _devices = [];
    });
    printerManager.startScan(const Duration(seconds: 4));
  }

  void _stopScanDevices() {
    printerManager.stopScan();
  }

  Future<List<int>> demoReceipt(
      PaperSize paper, CapabilityProfile profile) async {
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];

    // Print image
    final ByteData data = await rootBundle.load('assets/logo.png');
    final Uint8List imageBytes = data.buffer.asUint8List();
    final Image? image = decodeImage(imageBytes);
    bytes += ticket.image(image!);

    // Print QR Code from image
    // try {
    //   const String qrData = 'example.com';
    //   const double qrSize = 200;
    //   final uiImg = await QrPainter(
    //     data: qrData,
    //     version: QrVersions.auto,
    //     gapless: false,
    //   ).toImageData(qrSize);
    //   final dir = await getTemporaryDirectory();
    //   final pathName = '${dir.path}/qr_tmp.png';
    //   final qrFile = File(pathName);
    //   final imgFile = await qrFile.writeAsBytes(uiImg.buffer.asUint8List());
    //   final img = decodeImage(imgFile.readAsBytesSync());

    //   bytes += ticket.image(img);
    // } catch (e) {
    //   print(e);
    // }

    ticket.feed(2);
    ticket.cut();
    return bytes;
  }

  Future<List<int>> testTicket(
      PaperSize paper, CapabilityProfile profile) async {
    final Generator generator = Generator(paper, profile);
    List<int> bytes = [];

    bytes += generator.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    // bytes += generator.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
    //     styles: PosStyles(codeTable: PosCodeTable.westEur));
    // bytes += generator.text('Special 2: blåbærgrød',
    //     styles: PosStyles(codeTable: PosCodeTable.westEur));

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes +=
        generator.text('Reverse text', styles: const PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: const PosStyles(underline: true), linesAfter: 1);
    bytes += generator.text('Align left',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: const PosStyles(align: PosAlign.right), linesAfter: 1);

    bytes += generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    bytes += generator.text('Text size 200%',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    // Print image
    final ByteData data = await rootBundle.load('assets/logo.png');
    final Uint8List buf = data.buffer.asUint8List();
    final Image image = decodeImage(buf)!;
    bytes += generator.image(image);
    // Print image using alternative commands
    // bytes += generator.imageRaster(image);
    // bytes += generator.imageRaster(image, imageFn: PosImageFn.graphics);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    // bytes += generator.text(
    //   'hello ! 中文字 # world @ éphémère &',
    //   styles: PosStyles(codeTable: PosCodeTable.westEur),
    //   containsChinese: true,
    // );

    bytes += generator.feed(2);

    bytes += generator.cut();
    return bytes;
  }

  void _testPrint(PrinterBluetooth printer) async {
    printerManager.selectPrinter(printer);

    // TODO Don't forget to choose printer's paper
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();

    // TEST PRINT
    // final PosPrintResult res =
    // await printerManager.printTicket(await testTicket(paper));

    // DEMO RECEIPT
    final PosPrintResult res =
        await printerManager.printTicket((await demoReceipt(paper, profile)));

    showToast(res.msg);
  }

  _buildListDevices() {
    return ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () => printerManager.selectPrinter(_devices[index]),
            child: Column(
              children: <Widget>[
                Container(
                  height: 60,
                  padding: const EdgeInsets.only(left: 10),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.print),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(_devices[index].name ?? ''),
                            Text(_devices[index].address!),
                            Text(
                              'Click to print a test receipt',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(),
              ],
            ),
          );
        });
  }

  _buildCameraView() {
    if (!controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: 1 / controller!.value.aspectRatio,
      child: CameraPreview(controller!),
    );
  }

  void printWithDevice(Image image) async {
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
    final ByteData data = await rootBundle.load('assets/logo.png');
    final Uint8List imageBytes = data.buffer.asUint8List();
    final Image? image2 = decodeImage(imageBytes);
    bytes += ticket.image(image);

    ticket.feed(2);
    ticket.cut();

    // DEMO RECEIPT
    final PosPrintResult res = await printerManager.printTicket(bytes);

    showToast(res.msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
          child: Center(
              child: Column(
        children: [
          Expanded(child: _buildCameraView()),
          Expanded(child: _buildListDevices()),
          ElevatedButton(
              onPressed: () async {
                try {
                  final xFile = await controller!.takePicture();
                  final bytes = await File(xFile.path).readAsBytes();
                  final Image image = decodeImage(bytes)!;
                  printWithDevice(image);
                } catch (e) {
                  print(e);
                }
              },
              child: const Text(
                "사진을 찍으세요!!",
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.w700),
              )),
        ],
      ))),
      floatingActionButton: StreamBuilder<bool>(
        stream: printerManager.isScanningStream,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              onPressed: _stopScanDevices,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
              onPressed: _startScanDevices,
              child: const Icon(Icons.search),
            );
          }
        },
      ),
    );
  }
}
