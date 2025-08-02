import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart'; // WhatsApp share
import 'package:html_unescape/html_unescape.dart'; // HTML decode

void main() {
  runApp(SpeechApp());
}

class SpeechApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malayalam Speech Recognition',
      theme: ThemeData(primarySwatch: Colors.green),
      home: SpeechHomePage(),
    );
  }
}

class SpeechHomePage extends StatefulWidget {
  @override
  _SpeechHomePageState createState() => _SpeechHomePageState();
}

class _SpeechHomePageState extends State<SpeechHomePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _translatedController = TextEditingController();
  bool isListening = false;

  SpeechToText? speechToText;
  StreamController<Uint8List>? audioStream;
  FlutterSoundRecorder? recorder;

  @override
  void initState() {
    super.initState();
    _initGoogleSpeech();
  }

  Future<void> _initGoogleSpeech() async {
    try {
      var micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _updateTextBox('❌ Error: Microphone permission denied.');
        return;
      }

      final serviceAccountJson =
          await rootBundle.loadString('assets/credentials.json');

      final serviceAccount = ServiceAccount.fromString(serviceAccountJson);

      speechToText = SpeechToText.viaServiceAccount(serviceAccount);

      recorder = FlutterSoundRecorder();
      await recorder!.openRecorder();
    } catch (e) {
      _updateTextBox('❌ Initialization Error: $e');
    }
  }

  RecognitionConfig getConfig() => RecognitionConfig(
        encoding: AudioEncoding.LINEAR16,
        sampleRateHertz: 16000,
        languageCode: 'ml-IN',
        model: RecognitionModel.basic,
      );

  void _startListening() async {
    if (speechToText == null || recorder == null) {
      _updateTextBox('❌ Error: Speech service not initialized.');
      return;
    }

    try {
      audioStream = StreamController<Uint8List>();
      setState(() {
        isListening = true;
      });
      _updateTextBox('🎙️ Listening...');

      final responseStream = speechToText!.streamingRecognize(
        StreamingRecognitionConfig(
          config: getConfig(),
          interimResults: true,
        ),
        audioStream!.stream,
      );

      responseStream.listen((data) {
        if (data.results.isNotEmpty) {
          final result = data.results.first;
          if (result.alternatives.isNotEmpty) {
            final transcript = result.alternatives.first.transcript;
            _updateTextBox(transcript.isNotEmpty
                ? transcript
                : '⚠️ No speech detected.');
          }
        } else {
          _updateTextBox('⚠️ No speech detected.');
        }
      }, onError: (error) {
        _updateTextBox('❌ Recognition Error: $error');
      });

      await recorder!.startRecorder(
        toStream: audioStream!.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 16000 * 2,
      );
    } catch (e) {
      _updateTextBox('❌ Error starting recognition: $e');
      setState(() {
        isListening = false;
      });
    }
  }

  void _stopListening() async {
    try {
      await recorder?.stopRecorder();
      await audioStream?.close();
    } catch (e) {
      _updateTextBox('❌ Error stopping recorder: $e');
    }
    setState(() {
      isListening = false;
    });
  }

  void _updateTextBox(String text) {
    setState(() {
      _textController.text = text;
    });
  }

  Future<void> _translateText() async {
    final malayalamText = _textController.text.trim();
    if (malayalamText.isEmpty) {
      _translatedController.text = '⚠️ No Malayalam text to translate.';
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://malayalam-to-english.onrender.com/translate'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'text': malayalamText}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final translated = jsonResponse['translated_text'] ?? 'No translation';
        setState(() {
          _translatedController.text = translated;
        });
      } else {
        _translatedController.text =
            '❌ API Error: ${response.statusCode} ${response.reasonPhrase}';
      }
    } catch (e) {
      _translatedController.text = '❌ Translation Error: $e';
    }
  }

  void _shareToWhatsApp() async {
    final rawText = _translatedController.text.trim();
    if (rawText.isEmpty || rawText.startsWith('⚠️') || rawText.startsWith('❌')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Nothing to share. Please translate first.')),
      );
      return;
    }

    final unescape = HtmlUnescape();
    final decodedText = unescape.convert(rawText); // Decode HTML entities

    try {
      await Share.share(decodedText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error sharing to WhatsApp: $e')),
      );
    }
  }

  @override
  void dispose() {
    recorder?.closeRecorder();
    _textController.dispose();
    _translatedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Speak Malayalam")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _textController,
                readOnly: true,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Recognized Text',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(isListening ? Icons.stop : Icons.mic),
                label:
                    Text(isListening ? 'Stop Listening' : 'Start Listening'),
                onPressed: isListening ? _stopListening : _startListening,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.translate),
                label: Text('Translate'),
                onPressed: _translateText,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _translatedController,
                readOnly: true,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Translated English Text',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.share),
                label: Text('Share to WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _shareToWhatsApp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
