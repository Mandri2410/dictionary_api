import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dictionary App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.amber,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
          headlineSmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
          titleMedium: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600]),
        ),
      ),
      home: DictionaryPage(),
    );
  }
}

class DictionaryPage extends StatefulWidget {
  @override
  _DictionaryPageState createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _controller = TextEditingController();
  String _word = '';
  String _phonetic = '';
  List<String> _definitions = [];
  List<String> _synonyms = [];
  List<String> _antonyms = [];
  bool _isLoading = false;
  bool _showAllDefinitions = false;

  Future<void> _searchWord(String word) async {
    setState(() {
      _isLoading = true;
      _word = '';
      _phonetic = '';
      _definitions.clear();
      _synonyms.clear();
      _antonyms.clear();
      _showAllDefinitions = false;
    });

    final response = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        setState(() {
          _word = data[0]['word'];
          _phonetic = data[0]['phonetic'] ?? '';
          for (var meaning in data[0]['meanings']) {
            for (var definition in meaning['definitions']) {
              _definitions.add(definition['definition']);
            }
            _synonyms.addAll(List<String>.from(meaning['synonyms'] ?? []));
            _antonyms.addAll(List<String>.from(meaning['antonyms'] ?? []));
          }
          _synonyms = _synonyms.toSet().toList();
          _antonyms = _antonyms.toSet().toList();
        });
      }
    } else {
      print('Failed to load word');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildWordSection(String title, List<String> items) {
    return items.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: items
                    .map((item) => Chip(
                          label: Text(item),
                          backgroundColor: Colors.amber.shade100,
                        ))
                    .toList(),
              ),
              SizedBox(height: 20),
            ],
          )
        : SizedBox.shrink();
  }

  Widget _buildDefinitionsSection() {
    final displayedDefinitions =
        _showAllDefinitions ? _definitions : _definitions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Definitions:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ...displayedDefinitions.map((def) => Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('• $def'),
            )),
        if (_definitions.length > 3)
          TextButton(
            onPressed: () {
              setState(() {
                _showAllDefinitions = !_showAllDefinitions;
              });
            },
            child: Text(_showAllDefinitions ? 'Show Less' : 'Show More'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dictionary'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a word',
                labelStyle: TextStyle(
                  fontSize: 16, // Ukuran font yang lebih kecil
                ),
                hintText: 'Search for a word...',
                prefixIcon: Icon(Icons.search, color: Colors.indigo),
                contentPadding: EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 15.0), // Slim padding
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(30.0), // Radius lebih melengkung
                  borderSide: BorderSide(
                    width: 1.5, // Border lebih tipis
                    color: Colors.indigo, // Warna border
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    width: 1.5,
                    color: Colors.indigo,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    width: 2.0,
                    color: Colors.indigo, // Warna lebih gelap ketika fokus
                  ),
                ),
                fillColor: Colors.grey[200],
                filled: true, // Memberi warna latar belakang pada search bar
              ),
              onSubmitted: (value) {
                _searchWord(value);
              },
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_word.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _word,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (_phonetic.isNotEmpty)
                        Text(
                          _phonetic,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: _buildDefinitionsSection(),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildWordSection('Synonyms:', _synonyms),
                      _buildWordSection('Antonyms:', _antonyms),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
