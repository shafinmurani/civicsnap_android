import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteConfig {
  static final Client client = Client()
      .setEndpoint("https://fra.cloud.appwrite.io/v1")
      .setProject(dotenv.env['APPWRITE_APP_ID']);

  static Storage get storage => Storage(client);
}
