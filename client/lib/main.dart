// Add this with your imports
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:google_speech/generated/google/protobuf/empty.pb.dart';
// import 'package:google_speech/google_speech.dart';
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
  bool isReadOnly = false;
  bool _isTranslating = false; // <-- Added flag

  // SpeechToText? speechToText;
  StreamController<Uint8List>? audioStream;
  FlutterSoundRecorder? recorder;

  @override
  void initState() {
    super.initState();
    // _initGoogleSpeech();
  }

  // Future<void> _initGoogleSpeech() async {
  //   try {
  //     var micStatus = await Permission.microphone.request();
  //     if (!micStatus.isGranted) {
  //       _updateTextBox('❌ Error: Microphone permission denied.');
  //       return;
  //     }

  //     final serviceAccountJson =
  //         await rootBundle.loadString('assets/credentials.json');
  //     final serviceAccount = ServiceAccount.fromString(serviceAccountJson);

  //     speechToText = SpeechToText.viaServiceAccount(serviceAccount);

  //     recorder = FlutterSoundRecorder();
  //     await recorder!.openRecorder();
  //   } catch (e) {
  //     _updateTextBox('❌ Initialization Error: $e');
  //   }
  // }

  // RecognitionConfig getConfig() => RecognitionConfig(
  //       encoding: AudioEncoding.LINEAR16,
  //       sampleRateHertz: 16000,
  //       languageCode: 'ml-IN',
  //       model: RecognitionModel.basic,
  //     );

//   void _startListening() async {
//     if (speechToText == null || recorder == null) {
//       _updateTextBox('❌ Error: Speech service not initialized.');
//       return;
//     }

//     try {
//       audioStream = StreamController<Uint8List>();
//       setState(() {
//         isListening = true;        
//         isReadOnly = true;
//       });
//       _updateTextBox('🎙️ Listening...');

//       final responseStream = speechToText!.streamingRecognize(
//         StreamingRecognitionConfig(
//           config: getConfig(),
//           interimResults: true,
//         ),
//         audioStream!.stream,
//       );

//       responseStream.listen((data) {
//         if (data.results.isNotEmpty) {
//           final result = data.results.first;
//           if (result.alternatives.isNotEmpty) {
//             final transcript = result.alternatives.first.transcript;
//             _updateTextBox(transcript.isNotEmpty
//                 ? transcript
//                 : '⚠️ No speech detected.');
//           }
//         } else {
//           _updateTextBox('⚠️ No speech detected.');
//         }
//       }, onError: (error) {
//         _updateTextBox('❌ Recognition Error: $error');
//       });

//       await recorder!.startRecorder(
//         toStream: audioStream!.sink,
//         codec: Codec.pcm16,
//         sampleRate: 16000,
//         numChannels: 1,
//         bitRate: 16000 * 2,
//       );
//     } catch (e) {
//       _updateTextBox('❌ Error starting recognition: $e');
//       setState(() {
//         isListening = false;
//       });
//     }
//   }

//  void _stopListening() async {
//   try {
//     await recorder?.stopRecorder();
//     await audioStream?.close();
//   } catch (e) {
//     _updateTextBox('❌ Error stopping recorder: $e');
//   }
//   final ipText = _textController.text.trim();
//   if (ipText.startsWith('🎙️')) {
//     _textController.clear();
//   }
//   setState(() {
//     isListening = false;       
//     isReadOnly = false;
//   });
// }
  
  
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

  setState(() {
    _isTranslating = true;
    _translatedController.text = '';
  });

  try {
    final response = await http.post(
      Uri.parse('https://malayalam-to-english.onrender.com/translate'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': malayalamText,
        'source': 'ml',
        'target': 'en'
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String translatedText = data['translatedText'];

      setState(() {
        _translatedController.text = translatedText;
      });
    } else {
      setState(() {
        _translatedController.text =
            '❌ API Error: ${response.statusCode} ${response.reasonPhrase}';
      });
    }
  } catch (e) {
    setState(() {
      _translatedController.text = '❌ Translation Error: $e';
    });
  } finally {
    setState(() {
      _isTranslating = false;
    });
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
      appBar: AppBar(title: Text("Malayalam to English Translator")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color.fromARGB(25, 25, 25, 25),
              child: TextField(
                controller: _textController,
                readOnly: isReadOnly,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      children: [
                        TextSpan(text: 'Type or Speak in Malayalam'),
                      ],
                    ),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // IconButton(
                //   icon: Icon(Icons.mic),
                //   color: isListening ? Colors.blue : Colors.grey,
                //   iconSize: 30,
                //   onPressed: isListening ? _stopListening : _startListening,
                // ),
                IconButton(
                  icon: Icon(Icons.send),                  
                  color: Colors.blue,
                  tooltip: 'Send',
                  onPressed: () {
                    // _stopListening();
                    _translateText();
                  },
                ),
                // SizedBox(width: 20), // spacing between buttons
                IconButton(
                  icon: Icon(Icons.clear),
                  color: Colors.red,
                  tooltip: 'Clear',
                  onPressed: () {
                    _textController.clear();
                    _updateTextBox('');
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color.fromARGB(25, 25, 25, 25),
              child: _isTranslating
                  ? Center(child: CircularProgressIndicator())
                  : TextField(
                      controller: _translatedController,
                      readOnly: true,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: 'Translated to English Text',
                        border: OutlineInputBorder(),
                      ),
                    ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            width: double.infinity,
            color: Colors.green,
            child: Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.share),
                label: Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _shareToWhatsApp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
