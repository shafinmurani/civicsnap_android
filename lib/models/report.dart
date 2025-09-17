// lib/models/report.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String? id;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String description;
  final String category;
  final String uid; // Use a single, consistent key
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
      // Create top-level location fields
      "latitude": latitude,
      "longitude": longitude,
      "description": description,
      "category": category,
      "uid": uid, // Use the correct, consistent key
      "uploadTime": uploadTime,
      "status": status,
      "remarks": remarks,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json["id"],
      imageUrl: json["imageUrl"] as String,
      // Access top-level location fields and handle nulls
      latitude: (json["latitude"] as num?)?.toDouble() ?? 0.0,
      longitude: (json["longitude"] as num?)?.toDouble() ?? 0.0,
      description: json["description"] as String,
      category: json["category"] as String,
      uid: json["uid"] as String,
      uploadTime: (json["uploadTime"] as Timestamp).toDate(),
      status: json["status"] as String,
      remarks: json["remarks"] as String,
    );
  }
}
