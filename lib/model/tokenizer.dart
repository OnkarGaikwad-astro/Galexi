import 'package:flutter/services.dart';

class Tokenizer {
  late Map<String, int> vocab;

  static Future<Tokenizer> load(String path) async {
    final data = await rootBundle.loadString(path);
    final lines = data.split('\n');

    final vocab = <String, int>{};
    for (int i = 0; i < lines.length; i++) {
      vocab[lines[i].trim()] = i;
    }

    final t = Tokenizer();
    t.vocab = vocab;
    return t;
  }

  List<int> tokenize(String text) {
    final words = text.toLowerCase().split(" ");

    return words.map((word) {
      return vocab[word] ?? vocab["[UNK]"]!;
    }).toList();
  }
}