// lib/services/db_services.dart

import 'package:civicsnap_android/models/report.dart';
import 'package:civicsnap_android/services/storage_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DbServices {
  static const double duplicateRadius = 5; // meters
  static const Duration duplicateDuration = Duration(hours: 24);

  static Future checkAndCreateDocument(String? docID, name, email) async {
    final snapShot = await FirebaseFirestore.instance
        .collection('/users')
        .doc(docID)
        .get();
    if (!snapShot.exists) {
      await FirebaseFirestore.instance.collection('/users').doc(docID).set({
        "name": name,
        "email": email,
        "reports": [],
      });
    }
  }

  static Future<bool> isDuplicateReport(
    Position position,
    String uid,
    Report report,
  ) async {
    final now = DateTime.now();
    final cutoff = now.subtract(duplicateDuration);

    final snapshot = await FirebaseFirestore.instance
        .collection("reports")
        .where("uid", isEqualTo: uid) // Correct key
        .where("uploadTime", isGreaterThanOrEqualTo: cutoff)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final reportLat = data["latitude"] as double; // Access top-level fields
      final reportLon = data["longitude"] as double; // Access top-level fields

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        reportLat,
        reportLon,
      );

      if (distance <= duplicateRadius && data['category'] == report.category) {
        return true; // Found a duplicate
      }
    }
    return false;
  }

  static Future uploadReport(
    final Report report,
    final String imagePath,
  ) async {
    final duplicate = await isDuplicateReport(
      Position(
        latitude: report.latitude,
        longitude: report.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
      report.uid,
      report,
    );
    if (duplicate) {
      throw Exception(
        "You already reported an issue in this location within 24 hours.",
      );
    }

    final String imageUrl = await StorageServices().uploadImage(
      path: imagePath,
    );

    final docRef = FirebaseFirestore.instance.collection("reports").doc();
    final reportWithId = Report(
      id: docRef.id,
      address: report.address,
      imageUrl: imageUrl,
      latitude: report.latitude,
      longitude: report.longitude,
      description: report.description,
      category: report.category,
      uid: report.uid,
      city: report.city,
      uploadTime: DateTime.now(),
      status: report.status,
      remarks: report.remarks,
    );

    await docRef.set(reportWithId.toJson());
    await FirebaseFirestore.instance
        .collection("/users")
        .doc(report.uid)
        .update({
          "reports": FieldValue.arrayUnion([docRef.id]),
        });
  }

  static Stream<List<Report>> getUserReportsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .asyncMap((userDoc) async {
          final data = userDoc.data();
          if (data == null || data["reports"] == null) return [];

          final List<String> reportIds = List<String>.from(data["reports"]);
          if (reportIds.isEmpty) return [];

          final List<Report> reports = [];

          for (int i = 0; i < reportIds.length; i += 10) {
            final batch = reportIds.skip(i).take(10).toList();

            final snapshot = await FirebaseFirestore.instance
                .collection("reports")
                .where(FieldPath.documentId, whereIn: batch)
                .get();

            reports.addAll(
              snapshot.docs.map((doc) => Report.fromJson(doc.data())),
            );
          }

          reports.sort((a, b) => b.uploadTime.compareTo(a.uploadTime));
          return reports;
        });
  }
}
