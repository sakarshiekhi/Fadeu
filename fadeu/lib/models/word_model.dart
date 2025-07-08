import 'dart:convert';

// Often needed for debugPrint or other utility imports in models

// This class represents a single entry in your 'words' table.
class Word {
  final int id;
  final String? germanWord;
  final String? englishWord;
  final String? persianWord;
  final String? level;
  final String? example;
  final String? exampleEnglish;
  final String? examplePersian;
  final String? partOfSpeech;
  final String? article;
  final String? plural;
  final String? cases;
  final String? tenses;
  final String? audioFilename;

  // UI-specific state, not stored in the database
  bool isLiked;
  bool isSaved;

  Word({
    required this.id,
    this.germanWord,
    this.englishWord,
    this.persianWord,
    this.level,
    this.example,
    this.exampleEnglish,
    this.examplePersian,
    this.partOfSpeech,
    this.article,
    this.plural,
    this.cases,
    this.tenses,
    this.audioFilename,
    this.isLiked = false,
    this.isSaved = false,
  });

  /// Creates a Word object from a database map.
  factory Word.fromMap(Map<String, dynamic> map) {
    // Debug print to help diagnose mapping issues
    print('Word.fromMap received: $map');
    
    // Helper function to safely get string values with fallback
    String? getString(dynamic value, {String? fallback}) {
      if (value == null) return fallback;
      if (value is String) return value.trim().isNotEmpty ? value : fallback;
      return value.toString().trim().isNotEmpty ? value.toString() : fallback;
    }
    
    // Parse JSON strings for cases and tenses
    String? parseJsonField(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          final parsed = jsonDecode(value);
          return parsed.toString();
        } catch (e) {
          return value;
        }
      }
      return value.toString();
    }
    
    // Extract values directly from the map using the exact field names from the API
    final word = Word(
      id: map['id'] is int ? map['id'] as int : 0,
      germanWord: getString(map['german']),
      englishWord: getString(map['english']),
      persianWord: getString(map['persian']),
      level: getString(map['level'], fallback: 'A1'),
      example: getString(map['example']),
      exampleEnglish: getString(map['example_english']),
      examplePersian: getString(map['example_persian']),
      partOfSpeech: getString(map['part_of_speech']),
      article: getString(map['article']),
      plural: getString(map['plural']),
      cases: parseJsonField(map['cases']),
      tenses: parseJsonField(map['tenses']),
      audioFilename: getString(map['audio_filename']),
    );
    
    // Debug print the constructed word
    print('Constructed word: ${word.germanWord} | ${word.englishWord} | ${word.persianWord}');
    
    return word;
  }

  /// Converts the Word instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'german': germanWord,
      'english': englishWord,
      'persian': persianWord,
      'level': level,
      'example': example,
      'example_english': exampleEnglish,
      'example_persian': examplePersian,
      'part_of_speech': partOfSpeech,
      'article': article,
      'plural': plural,
      'cases': cases,
      'tenses': tenses,
      'audio_filename': audioFilename,
      'is_liked': isLiked ? 1 : 0,
      'is_saved': isSaved ? 1 : 0,
    };
  }

  /// Creates a copy of this word with the given fields replaced with the new values.
  Word copyWith({
    int? id,
    String? germanWord,
    String? englishWord,
    String? persianWord,
    String? level,
    String? example,
    String? exampleEnglish,
    String? examplePersian,
    String? partOfSpeech,
    String? article,
    String? plural,
    String? cases,
    String? tenses,
    String? audioFilename,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Word(
      id: id ?? this.id,
      germanWord: germanWord ?? this.germanWord,
      englishWord: englishWord ?? this.englishWord,
      persianWord: persianWord ?? this.persianWord,
      level: level ?? this.level,
      example: example ?? this.example,
      exampleEnglish: exampleEnglish ?? this.exampleEnglish,
      examplePersian: examplePersian ?? this.examplePersian,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      article: article ?? this.article,
      plural: plural ?? this.plural,
      cases: cases ?? this.cases,
      tenses: tenses ?? this.tenses,
      audioFilename: audioFilename ?? this.audioFilename,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  String toString() {
    return 'Word{id: $id, germanWord: $germanWord, englishWord: $englishWord, persianWord: $persianWord, isSaved: $isSaved}';
  }
}
