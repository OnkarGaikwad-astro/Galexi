import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'tokenizer.dart';

class EmbeddingService {
  late Interpreter _interpreter;
  late Tokenizer _tokenizer;

  Future<void> init() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/embedding_model/model.tflite',
    );

    _tokenizer = await Tokenizer.load(
      'assets/embedding_model/vocab.txt',
    );
  }

  List<double> generateEmbedding(String text) {
    final tokens = _tokenizer.tokenize(text);

    final inputIds = List.filled(128, 0);
    final attentionMask = List.filled(128, 0);
    final tokenTypeIds = List.filled(128, 0);

    for (int i = 0; i < tokens.length && i < 128; i++) {
      inputIds[i] = tokens[i];
      attentionMask[i] = 1;
    }

    final output = List.generate(
      1,
      (_) => List.generate(128, (_) => List.filled(384, 0.0)),
    );

    _interpreter.run(
      {
        0: [inputIds],
        1: [attentionMask],
        2: [tokenTypeIds],
      },
      output,
    );

    final pooled = _meanPooling(output[0], attentionMask);
    return _normalize(pooled);
  }

  List<double> _meanPooling(List<List<double>> tokens, List<int> mask) {
    final dim = tokens[0].length;
    final result = List.filled(dim, 0.0);
    int count = 0;

    for (int i = 0; i < tokens.length; i++) {
      if (mask[i] == 1) {
        for (int j = 0; j < dim; j++) {
          result[j] += tokens[i][j];
        }
        count++;
      }
    }

    return result.map((v) => v / count).toList();
  }

  List<double> _normalize(List<double> v) {
    final norm = sqrt(v.fold(0, (sum, x) => sum + x * x));
    return v.map((x) => x / norm).toList();
  }
}