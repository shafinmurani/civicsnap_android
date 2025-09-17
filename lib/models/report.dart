import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String? id;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String description;
  final String category;
  final String uid;
  final DateTime uploadTime;
  final String status;
  final String remarks;
  Report({
    this.id,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.category,
    required this.uid,
    required this.uploadTime,
    required this.status,
    required this.remarks,
  });
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "imageUrl": imageUrl,
      "position": {"latitude": latitude, "longitude": longitude},
      "description": description,
      "category": category,
      "reportedBy": uid,
      "uploadTime": uploadTime,
      "status": status,
      "remarks": remarks,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json["id"],
      imageUrl: json["imageUrl"],
      latitude: json["position"]["latitude"],
      longitude: json["position"]["longitude"],
      description: json["description"],
      category: json["category"],
      uid: json["reportedBy"],
      uploadTime: (json["uploadTime"] as Timestamp).toDate(),
      status: json["status"],
      remarks: json["remarks"],
    );
  }
}
