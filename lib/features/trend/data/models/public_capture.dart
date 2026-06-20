import 'package:cloud_firestore/cloud_firestore.dart';

class PublicCapture {
  const PublicCapture({
    required this.id,
    required this.captureId,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.quote,
    required this.comment,
    required this.pageNumber,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String captureId;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String quote;
  final String comment;
  final int? pageNumber;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory PublicCapture.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final createdAtValue = data['createdAt'];
    final updatedAtValue = data['updatedAt'];

    return PublicCapture(
      id: doc.id,
      captureId: data['captureId'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      bookId: data['bookId'] as String? ?? '',
      bookTitle: data['bookTitle'] as String? ?? '제목 없음',
      quote: data['quote'] as String? ?? '',
      comment: data['comment'] as String? ?? '',
      pageNumber: data['pageNumber'] as int?,
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
      updatedAt: updatedAtValue is Timestamp ? updatedAtValue.toDate() : null,
    );
  }
}