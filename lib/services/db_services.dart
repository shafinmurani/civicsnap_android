import 'package:civicsnap_android/models/report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DbServices {
  static const double duplicateRadius = 50; // meters
  static const Duration duplicateDuration = Duration(hours: 24);

  // Create a document for every user
  static Future checkAndCreateDocument(String? docID, name, email) async {
    final snapShot = await FirebaseFirestore.instance
        .collection('/users')
        .doc(docID)
        .get();
    var collection = FirebaseFirestore.instance.collection('/users');

    if (!snapShot.exists) {
      // document is not exist
      collection.doc(docID).set({"name": name, "email": email, "reports": []});
    }
  }

  static Future<bool> isDuplicateReport(Position position, String uid) async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(hours: 24));

    // Bounding box for ~5m radius
    const double offset = 0.00005; // ~5m (varies by latitude)
    final lat = position.latitude;
    final lon = position.longitude;

    final snapshot = await FirebaseFirestore.instance
        .collection("reports")
        .where("reportedBy", isEqualTo: uid)
        .where("uploadTime", isGreaterThan: cutoff.toIso8601String())
        .where("position.latitude", isGreaterThan: lat - offset)
        .where("position.latitude", isLessThan: lat + offset)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final reportLat = data["position"]["latitude"];
      final reportLon = data["position"]["longitude"];

      final distance = Geolocator.distanceBetween(
        lat,
        lon,
        reportLat,
        reportLon,
      );

      if (distance <= 50) {
        return true; // Found nearby duplicate
      }
    }

    return false;
  }

  static Future uploadReport(final Report report) async {
    // final uid = FirebaseAuth.instance.currentUser!.uid;

    // Step 1: Duplicate check
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
    );
    if (duplicate) {
      throw Exception(
        "You already reported an issue in this location within 24 hours.",
      );
    }

    // Step 2: Upload new report
    final docRef = FirebaseFirestore.instance.collection("reports").doc();
    final reportWithId = Report(
      id: docRef.id,
      imageUrl: report.imageUrl,
      latitude: report.latitude,
      longitude: report.longitude,
      description: report.description,
      category: report.category,
      uid: report.uid,
      uploadTime: DateTime.now(),
      status: report.status,
      remarks: report.remarks,
    );

    await docRef.set(reportWithId.toJson());

    // Step 3: Update user’s reports array safely
    final userDoc = FirebaseFirestore.instance
        .collection("/users")
        .doc(report.uid);
    await userDoc.update({
      "reports": FieldValue.arrayUnion([docRef.id]),
    });
  }

  static Future<List<Report>> getUserReports() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Step 1: Get user document
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    final userData = userDoc.data();

    if (userData == null || userData["reports"] == null) {
      return [];
    }

    final List<String> reportIds = List<String>.from(userData["reports"]);

    if (reportIds.isEmpty) return [];

    // Step 2: Fetch reports using whereIn (limit of 10 per query in Firestore)
    final List<Report> reports = [];

    // Since whereIn has a limit of 10, we need batching
    for (int i = 0; i < reportIds.length; i += 10) {
      final batch = reportIds.skip(i).take(10).toList();

      final snapshot = await FirebaseFirestore.instance
          .collection("reports")
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      reports.addAll(snapshot.docs.map((doc) => Report.fromJson(doc.data())));
    }

    // Step 3: Sort by uploadTime (since we're not ordering in whereIn)
    reports.sort((a, b) => b.uploadTime.compareTo(a.uploadTime));

    return reports;
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
