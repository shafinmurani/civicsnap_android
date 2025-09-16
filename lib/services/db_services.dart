import 'package:cloud_firestore/cloud_firestore.dart';

class DbServices {
  // Create a document for every user
  static Future checkAndCreateDocument(String? docID, name, email) async {
    final snapShot = await FirebaseFirestore.instance
        .collection('/data')
        .doc(docID)
        .get();
    var collection = FirebaseFirestore.instance.collection('/users');

    if (!snapShot.exists) {
      // document is not exist
      collection.doc(docID).set({"name": name, "email": email, "reports": []});
    }
  }
}
