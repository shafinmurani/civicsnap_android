import 'package:appwrite/appwrite.dart';
import 'package:civicsnap_android/config/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageServices {
  Future<String> uploadImage({required String path}) async {
    Storage storage = AppwriteConfig.storage;
    final file = await storage.createFile(
      bucketId: "${dotenv.env["BUCKET_ID"]}",
      fileId: ID.unique(),
      file: InputFile.fromPath(path: path),
    );
    final url =
        "https://fra.cloud.appwrite.io/v1/storage/buckets/${dotenv.env["BUCKET_ID"]}/files/${file.$id}/view?project=${dotenv.env["PROJECT_ID"]}";

    return url;
  }
}
