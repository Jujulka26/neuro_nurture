import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveGameScore({
    required String userId,
    required String gameName,
    required int score,
  }) async {
    try {
      await _firestore.collection('game_scores').add({
        'userId': userId,
        'gameName': gameName,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}