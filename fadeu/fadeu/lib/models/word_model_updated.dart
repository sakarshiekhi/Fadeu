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
    
    return Word(
      id: map['id'] is int ? map['id'] as int : 0, // Handle potential null id
      germanWord: (map['german'] ?? map['german_word']) as String?,
      englishWord: (map['english'] ?? map['english_word']) as String?,
      persianWord: (map['persian'] ?? map['persian_word']) as String?,
      level: map['level'] as String?,
      example: map['example'] as String?,
      exampleEnglish: map['example_english'] as String?,
      examplePersian: map['example_persian'] as String?,
      partOfSpeech: map['part_of_speech'] as String?,
      article: map['article'] as String?,
      plural: map['plural'] as String?,
      cases: map['cases'] as String?,
      tenses: map['tenses'] as String?,
      audioFilename: map['audio_filename'] as String?,
    );
  }
}
