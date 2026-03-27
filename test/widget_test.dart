import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Aera/model/embedding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
    test('Embedding generation test', () async {
    final emb = EmbeddingService();

    await emb.init();

    final vector = emb.generateEmbedding("Hello world");

    expect(vector.length, 384);
  });
}