import 'package:geolocator/geolocator.dart';

class Report {
  final String? id;
  final String imageUrl;
  final Position position;
  final String description;
  final String category;
  final String uid;
  final String uploadTime;
  final String status;
  final String remarks;

  Report({
    this.id,
    required this.imageUrl,
    required this.position,
    required this.description,
    required this.category,
    required this.uid,
    required this.uploadTime,
    required this.status,
    required this.remarks,
  });

  toJson() {
    return {
      "id": id,
      "imageUrl": imageUrl,
      "position": position.toJson(),
      "description": description,
      "category": category,
      "reportedBy": uid,
      "uploadTime": uploadTime,
      "status": status,
      "remarks": remarks,
    };
  }
}
