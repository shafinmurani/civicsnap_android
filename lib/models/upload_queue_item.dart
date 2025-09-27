import 'package:civicsnap_android/models/report.dart';

enum UploadStatus {
  queued,
  aiValidation,
  uploadingImage,
  verification,
  uploaded,
  failed,
  permanentFailure
}

class UploadQueueItem {
  final String id;
  final Report report;
  final String imagePath;
  final UploadStatus status;
  final DateTime queuedAt;
  final String? errorMessage;
  final double? progress;

  UploadQueueItem({
    required this.id,
    required this.report,
    required this.imagePath,
    required this.status,
    required this.queuedAt,
    this.errorMessage,
    this.progress,
  });

  UploadQueueItem copyWith({
    String? id,
    Report? report,
    String? imagePath,
    UploadStatus? status,
    DateTime? queuedAt,
    String? errorMessage,
    double? progress,
  }) {
    return UploadQueueItem(
      id: id ?? this.id,
      report: report ?? this.report,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      queuedAt: queuedAt ?? this.queuedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report': report.toLocalJson(),
      'imagePath': imagePath,
      'status': status.index,
      'queuedAt': queuedAt.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
      'progress': progress,
    };
  }

  factory UploadQueueItem.fromJson(Map<String, dynamic> json) {
    return UploadQueueItem(
      id: json['id'],
      report: Report.fromLocalJson(json['report']),
      imagePath: json['imagePath'],
      status: UploadStatus.values[json['status']],
      queuedAt: DateTime.fromMillisecondsSinceEpoch(json['queuedAt']),
      errorMessage: json['errorMessage'],
      progress: json['progress']?.toDouble(),
    );
  }
}