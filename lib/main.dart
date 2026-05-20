import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.camera.request();
  await Permission.bluetooth.request();
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();

  cameras = await availableCameras();

  runApp(const EngineerAI());
}

class EngineerAI extends StatelessWidget {
  const EngineerAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late CameraController controller;

  final textRecognizer = TextRecognizer();

  String detectedText = "No text scanned";

  List<String> devices = [];

  Database? database;

  bool initialized = false;

  @override
  void initState() {
    super.initState();

    startSystem();
  }

  Future<void> startSystem() async {

    await initCamera();

    await initDatabase();

    scanBluetooth();

    initialized = true;

    setState(() {});
  }

  Future<void> initCamera() async {

    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
    );

    await controller.initialize();
  }

  Future<void> initDatabase() async {

    Directory dir = await getApplicationDocumentsDirectory();

    String path = join(dir.path, "engineer_ai.db");

    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {

        await db.execute('''
        CREATE TABLE memory(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT
        )
        ''');
      },
    );
  }

  Future<void> scanBluetooth() async {

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 4),
    );

    FlutterBluePlus.scanResults.listen((results) {

      List<String> found = [];

      for (ScanResult r in results) {

        if (r.device.platformName.isNotEmpty) {
          found.add(r.device.platformName);
        }
      }

      setState(() {
        devices = found;
      });
    });
  }

  Future<void> scanScreen() async {

    final image = await controller.takePicture();

    final inputImage =
        InputImage.fromFile(File(image.path));

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    detectedText = recognizedText.text;

    await database?.insert(
      "memory",
      {
        "text": detectedText,
      },
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if (!initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Engineer AI"),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            SizedBox(
              height: 300,
              child: CameraPreview(controller),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: scanScreen,
              child: const Text(
                "Scan Laptop Screen",
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "OCR Result",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(detectedText),
            ),

            const Divider(),

            const Text(
              "ESP32 Bluetooth Devices",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            for (String device in devices)
              ListTile(
                title: Text(device),
              ),

            const Divider(),

            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Workflow Memory Active",
                style: TextStyle(fontSize: 18),
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Offline AI Architecture Initialized",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    textRecognizer.close();
    super.dispose();
  }
}
