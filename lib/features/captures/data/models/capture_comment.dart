import 'package:cloud_firestore/cloud_firestore.dart';

class CaptureComment {
  const CaptureComment({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory CaptureComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw StateError('CaptureComment document ${doc.id} has no data');
    }

    final createdAtValue = data['createdAt'];
    final updatedAtValue = data['updatedAt'];

    return CaptureComment(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
      updatedAt: updatedAtValue is Timestamp ? updatedAtValue.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestoreOnCreate() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
  }
}