import 'package:cloud_firestore/cloud_firestore.dart';

enum CaptureSource {
  camera,
  gallery,
  manual,
}

extension CaptureSourceX on CaptureSource {
  String get value {
    switch (this) {
      case CaptureSource.camera:
        return 'camera';
      case CaptureSource.gallery:
        return 'gallery';
      case CaptureSource.manual:
        return 'manual';
    }
  }

  static CaptureSource fromValue(String value) {
    switch (value) {
      case 'camera':
        return CaptureSource.camera;
      case 'gallery':
        return CaptureSource.gallery;
      case 'manual':
        return CaptureSource.manual;
      default:
        return CaptureSource.manual;
    }
  }
}

class Capture {
  const Capture({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.quote,
    required this.comment,
    required this.pageNumber,
    required this.isPublic,
    required this.source,
    required this.createdAt,
    this.ocrRawText,
  });

  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String quote;
  final String comment;
  final int? pageNumber;
  final bool isPublic;
  final CaptureSource source;
  final String? ocrRawText;
  final DateTime createdAt;

  factory Capture.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Capture document ${doc.id} has no data');
    }

    final createdAtValue = data['createdAt'];

    return Capture(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      bookId: data['bookId'] as String? ?? '',
      bookTitle: data['bookTitle'] as String? ?? '',
      quote: data['quote'] as String? ?? '',
      comment: data['comment'] as String? ?? '',
      pageNumber: data['pageNumber'] as int?,
      isPublic: data['isPublic'] as bool? ?? false,
      source: CaptureSourceX.fromValue(data['source'] as String? ?? 'manual'),
      ocrRawText: data['ocrRawText'] as String?,
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreOnCreate() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'quote': quote,
      'comment': comment,
      'pageNumber': pageNumber,
      'isPublic': isPublic,
      'source': source.value,
      'ocrRawText': ocrRawText,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}