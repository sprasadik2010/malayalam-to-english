import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share/share.dart'; // For sharing to WhatsApp or any app

void main() {
  runApp(TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malayalam to English Translator',
      home: TranslatorHomePage(),
    );
  }
}

class TranslatorHomePage extends StatefulWidget {
  @override
  _TranslatorHomePageState createState() => _TranslatorHomePageState();
}

class _TranslatorHomePageState extends State<TranslatorHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _translatedText = '';
  bool _isLoading = false;

  Future<void> _translateText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.100:8000/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _translatedText = jsonResponse['translated_text'];
        });
      } else {
        setState(() {
          _translatedText = 'Translation failed.';
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareTranslation() {
    if (_translatedText.isNotEmpty) {
      Share.share(_translatedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Malayalam to English')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Malayalam text',
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _translateText,
              child: Text('Translate'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Text(
                    _translatedText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
            SizedBox(height: 20),
            if (_translatedText.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _shareTranslation,
                icon: Icon(Icons.share),
                label: Text('Share to WhatsApp'),
              ),
          ],
        ),
      ),
    );
  }
}
