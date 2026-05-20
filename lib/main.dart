import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  bool ready = false;

  String scannedText = "No text scanned";

  final textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();

    initializeCamera();
  }

  Future<void> initializeCamera() async {

    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();

    ready = true;

    setState(() {});
  }

  Future<void> scanText() async {

    try {

      final image = await controller.takePicture();

      final inputImage =
          InputImage.fromFilePath(image.path);

      final recognizedText =
          await textRecognizer.processImage(inputImage);

      scannedText = recognizedText.text;

      setState(() {});

    } catch (e) {

      scannedText = "OCR Error: $e";

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    if (!ready) {

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
              height: 350,
              child: CameraPreview(controller),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: scanText,
              child: const Text(
                "Scan Laptop Screen",
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                scannedText,
                style: const TextStyle(fontSize: 18),
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
