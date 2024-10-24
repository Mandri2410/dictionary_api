import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Entry point aplikasi Flutter
void main() {
  runApp(MyApp());
}

// Widget utama yang mendefinisikan tema dan konfigurasi dasar aplikasi
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dictionary App',
      // Konfigurasi tema aplikasi dengan warna indigo sebagai warna utama
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.amber,
        ),
        // Mendefinisikan gaya teks yang akan digunakan di seluruh aplikasi
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

// Widget halaman utama kamus yang dapat menerima input dan menampilkan hasil
class DictionaryPage extends StatefulWidget {
  @override
  _DictionaryPageState createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  // Controller untuk input teks
  final TextEditingController _controller = TextEditingController();

  // Variabel untuk menyimpan data hasil pencarian
  String _word = '';
  String _phonetic = '';
  List<String> _definitions = [];
  List<String> _synonyms = [];
  List<String> _antonyms = [];
  bool _isLoading = false;
  bool _showAllDefinitions = false;

  // Fungsi untuk melakukan pencarian kata menggunakan API
  Future<void> _searchWord(String word) async {
    // Reset state sebelum melakukan pencarian baru
    setState(() {
      _isLoading = true;
      _word = '';
      _phonetic = '';
      _definitions.clear();
      _synonyms.clear();
      _antonyms.clear();
      _showAllDefinitions = false;
    });

    // Melakukan HTTP request ke API kamus
    final response = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        // Update state dengan data yang diterima dari API
        setState(() {
          _word = data[0]['word'];
          _phonetic = data[0]['phonetic'] ?? '';
          // Mengumpulkan semua definisi dari setiap makna kata
          for (var meaning in data[0]['meanings']) {
            for (var definition in meaning['definitions']) {
              _definitions.add(definition['definition']);
            }
            // Mengumpulkan sinonim dan antonim
            _synonyms.addAll(List<String>.from(meaning['synonyms'] ?? []));
            _antonyms.addAll(List<String>.from(meaning['antonyms'] ?? []));
          }
          // Menghilangkan duplikat dari sinonim dan antonim
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

  // Widget untuk menampilkan daftar kata (sinonim/antonim) dalam bentuk chip
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

  // Widget untuk menampilkan bagian definisi dengan tombol show more/less
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
        // Tombol show more/less hanya ditampilkan jika ada lebih dari 3 definisi
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
      // Layout utama aplikasi
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar dengan styling kustom
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a word',
                labelStyle: TextStyle(fontSize: 16),
                hintText: 'Search for a word...',
                prefixIcon: Icon(Icons.search, color: Colors.indigo),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                // Styling untuk border dalam keadaan normal
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    width: 1.5,
                    color: Colors.indigo,
                  ),
                ),
                // Styling untuk border ketika tidak dalam fokus
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    width: 1.5,
                    color: Colors.indigo,
                  ),
                ),
                // Styling untuk border ketika dalam fokus
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    width: 2.0,
                    color: Colors.indigo,
                  ),
                ),
                fillColor: Colors.grey[200],
                filled: true,
              ),
              onSubmitted: (value) {
                _searchWord(value);
              },
            ),
            SizedBox(height: 20),
            // Menampilkan loading indicator atau hasil pencarian
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_word.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Menampilkan kata yang dicari
                      Text(
                        _word,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      // Menampilkan fonetik jika tersedia
                      if (_phonetic.isNotEmpty)
                        Text(
                          _phonetic,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      SizedBox(height: 20),
                      // Menampilkan definisi dalam card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: _buildDefinitionsSection(),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Menampilkan sinonim dan antonim
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
