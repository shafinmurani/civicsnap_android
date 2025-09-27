import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:civicsnap_android/models/upload_queue_item.dart';
import 'package:civicsnap_android/models/report.dart';
import 'package:civicsnap_android/services/gemini_servies.dart';
import 'package:civicsnap_android/services/storage_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UploadQueueService {
  static final UploadQueueService _instance = UploadQueueService._internal();
  factory UploadQueueService() => _instance;
  UploadQueueService._internal();

  final _queueController = StreamController<List<UploadQueueItem>>.broadcast();
  final List<UploadQueueItem> _queue = [];
  final Connectivity _connectivity = Connectivity();
  bool _isProcessing = false;
  late StreamSubscription _connectivitySubscription;
  Timer? _periodicTimer;

  Stream<List<UploadQueueItem>> get queueStream => _queueController.stream;
  List<UploadQueueItem> get currentQueue => List.unmodifiable(_queue);

  Future<void> initialize() async {
    await _loadQueueFromStorage();
    // Always emit the current queue state
    _queueController.add(List.unmodifiable(_queue));

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Check if any of the connectivity results indicate connection
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (hasConnection && !_isProcessing) {
        _processQueue();
      }
    });

    // Start processing if we have network
    final connectivityResults = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
    if (hasConnection) {
      _processQueue();
    }

    // Set up periodic processing every 2 minutes when app is active
    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!_isProcessing && _queue.isNotEmpty) {
        _processQueue();
      }
    });
  }

  Future<void> addToQueue(Report report, String imagePath) async {
    try {
      // Copy image to app's permanent directory
      final String permanentImagePath = await _copyImageToPermanentLocation(
        imagePath,
      );

      final queueItem = UploadQueueItem(
        id: const Uuid().v4(),
        report: report,
        imagePath: permanentImagePath,
        status: UploadStatus.queued,
        queuedAt: DateTime.now(),
      );

      _queue.add(queueItem);
      await _saveQueueToStorage();
      _queueController.add(List.unmodifiable(_queue));

      // Try to process immediately if we have network
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );
      if (hasConnection && !_isProcessing) {
        _processQueue();
      }
    } catch (e) {
      print('Error in addToQueue: $e');
      // Throw a translatable key instead of raw English
      throw Exception('failedToQueueReport');
    }
  }

  Future<String> _copyImageToPermanentLocation(String originalPath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory uploadDir = Directory('${appDir.path}/queued_uploads');

      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      final String fileName = '${const Uuid().v4()}.jpg';
      final String newPath = '${uploadDir.path}/$fileName';

      final File originalFile = File(originalPath);
      await originalFile.copy(newPath);

      return newPath;
    } catch (e) {
      // Throw a localizable error key
      throw Exception('errorCopyImageFailed');
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    final connectivityResults = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasConnection) return;

    _isProcessing = true;

    try {
      final queuedItems = _queue
          .where(
            (item) => item.status == UploadStatus.queued,
          )
          .toList();

      for (final item in queuedItems) {
        await _processUploadItem(item);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processUploadItem(UploadQueueItem item) async {
    String? imageUrl;
    try {
      // Step 1: AI Image Validation
      _updateItemStatus(item.id, UploadStatus.aiValidation, progress: 0.1);

      // Check if image file still exists
      if (!File(item.imagePath).existsSync()) {
        // Use localized key for missing image file
        throw Exception('errorImageFileNotFound');
      }

      final validReport = await GeminiService.validateReport(
        imageUrl: item.imagePath, // Use local path for validation
        category: item.report.category,
        description: item.report.description,
      );

      if (!validReport) {
        throw Exception('validationErr');
      }

      _updateItemStatus(item.id, UploadStatus.aiValidation, progress: 0.3);

      // Step 2: Image Upload
      _updateItemStatus(item.id, UploadStatus.uploadingImage, progress: 0.4);

      imageUrl = await StorageServices().uploadImage(path: item.imagePath);

      _updateItemStatus(item.id, UploadStatus.uploadingImage, progress: 0.6);

      // Step 3: Report Prioritization
      _updateItemStatus(item.id, UploadStatus.verification, progress: 0.7);

      final priority = await GeminiService.getPriority(
        imageUrl: imageUrl,
        description: item.report.description,
        category: item.report.category,
        city: item.report.city,
        address: item.report.address,
      );

      _updateItemStatus(item.id, UploadStatus.verification, progress: 0.8);

      // Step 4: DB Upload
      _updateItemStatus(item.id, UploadStatus.uploadingImage, progress: 0.9);

      // Check for duplicate reports
      final duplicate = await _isDuplicateReport(
        Position(
          latitude: item.report.latitude,
          longitude: item.report.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
        item.report.uid,
        item.report,
      );

      if (duplicate) {
        throw Exception('reportFailed');
      }

      // Create and save report
      final docRef = FirebaseFirestore.instance.collection("reports").doc();
      final reportWithId = Report(
        priority: priority,
        id: docRef.id,
        address: item.report.address,
        imageUrl: imageUrl,
        latitude: item.report.latitude,
        longitude: item.report.longitude,
        description: item.report.description,
        category: item.report.category,
        uid: item.report.uid,
        city: item.report.city,
        uploadTime: DateTime.now(),
        status: item.report.status,
        remarks: item.report.remarks,
      );

      await docRef.set(reportWithId.toJson());
      await FirebaseFirestore.instance
          .collection("/users")
          .doc(item.report.uid)
          .update({
            "reports": FieldValue.arrayUnion([docRef.id]),
          });

      // Mark as uploaded
      _updateItemStatus(item.id, UploadStatus.uploaded, progress: 1.0);

      // Clean up image file
      try {
        await File(item.imagePath).delete();
      } catch (_) {}

      // Remove from queue after successful upload
      Timer(const Duration(seconds: 3), () {
        _removeFromQueue(item.id);
      });
    } catch (e) {
      // Clean up uploaded image if upload failed after image upload
      if (imageUrl != null) {
        try {
          // You might want to implement image cleanup from storage
        } catch (_) {}
      }

      String errorMessage = _getUserFriendlyErrorMessage(e);
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      // Determine error type and appropriate status
      UploadStatus failureStatus;
      
      if (_isNetworkError(e)) {
        // Network errors should be retried - use 'failed' status
        failureStatus = UploadStatus.failed;
        print('Network error detected, will auto-retry: $errorMessage');
      } else if (_isPermanentError(e)) {
        // Permanent errors should not be retried - use 'permanentFailure' status
        failureStatus = UploadStatus.permanentFailure;
        print('Permanent error detected, no retry: $errorMessage');
      } else {
        // Unknown errors - treat as permanent for safety
        failureStatus = UploadStatus.permanentFailure;
        print('Unknown error detected, treating as permanent: $errorMessage');
      }
      
      // Mark with appropriate failure status
      _updateItemStatus(
        item.id,
        failureStatus,
        errorMessage: errorMessage.tr(), // Translate the error message
      );
    }
  }

  void _updateItemStatus(
    String itemId,
    UploadStatus status, {
    double? progress,
    String? errorMessage,
  }) {
    final index = _queue.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: status,
        progress: progress,
        errorMessage: errorMessage,
      );
      _saveQueueToStorage();
      _queueController.add(List.unmodifiable(_queue));
    }
  }

  void _removeFromQueue(String itemId) {
    _queue.removeWhere((item) => item.id == itemId);
    _saveQueueToStorage();
    _queueController.add(List.unmodifiable(_queue));
  }

  Future<void> retryFailedUpload(String itemId) async {
    final index = _queue.indexWhere((item) => item.id == itemId);
    if (index != -1 && 
        (_queue[index].status == UploadStatus.failed || 
         _queue[index].status == UploadStatus.permanentFailure)) {
      _queue[index] = _queue[index].copyWith(
        status: UploadStatus.queued,
        errorMessage: null,
        progress: null,
      );
      await _saveQueueToStorage();
      _queueController.add(List.unmodifiable(_queue));

      final connectivityResults = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );
      if (hasConnection && !_isProcessing) {
        _processQueue();
      }
    }
  }

  Future<void> removeFromQueue(String itemId) async {
    _queue.removeWhere((item) => item.id == itemId);
    await _saveQueueToStorage();
    _queueController.add(List.unmodifiable(_queue));
  }

  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _queue.map((item) => item.toJson()).toList();
      await prefs.setString('upload_queue', jsonEncode(queueJson));
      print('Saved ${_queue.length} items to queue storage');
    } catch (e) {
      print('Error saving queue to storage: $e');
    }
  }

  Future<void> _loadQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString('upload_queue');
      if (queueString != null) {
        final queueJson = jsonDecode(queueString) as List;
        _queue.clear();
        _queue.addAll(
          queueJson.map((item) => UploadQueueItem.fromJson(item)).toList(),
        );
        print('Loaded ${_queue.length} items from queue storage');
      } else {
        print('No queue data found in storage');
      }
    } catch (e) {
      print('Error loading queue from storage: $e');
      _queue.clear(); // Clear queue on error to prevent crashes
    }
  }

  Future<bool> hasNetworkConnection() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasConnection) {
      return false;
    }

    // Additional check to see if we can actually reach the internet
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> _isDuplicateReport(
    Position position,
    String uid,
    Report report,
  ) async {
    const double duplicateRadius = 5; // meters
    const Duration duplicateDuration = Duration(hours: 24);

    final now = DateTime.now();
    final cutoff = now.subtract(duplicateDuration);

    final snapshot = await FirebaseFirestore.instance
        .collection("reports")
        .where("uid", isEqualTo: uid)
        .where("uploadTime", isGreaterThanOrEqualTo: cutoff)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final reportLat = data["latitude"] as double;
      final reportLon = data["longitude"] as double;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        reportLat,
        reportLon,
      );

      if (distance <= duplicateRadius && data['category'] == report.category) {
        return true;
      }
    }
    return false;
  }

  /// Call this method when app resumes from background
  Future<void> resumeProcessing() async {
    if (!_isProcessing && _queue.isNotEmpty) {
      final hasConnection = await hasNetworkConnection();
      if (hasConnection) {
        _processQueue();
      }
    }
  }

  /// Determines if an error is network-related and should be retried
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network-related errors that should be retried
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable') ||
           errorString.contains('no internet') ||
           errorString.contains('socketexception') ||
           errorString.contains('handshakeexception') ||
           errorString.contains('failed host lookup') ||
           error is SocketException ||
           error is HttpException;
  }
  
  /// Determines if an error is a permanent business logic error
  bool _isPermanentError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Business logic and server-side errors that should not be auto-retried
    return errorString.contains('validationerr') ||
           errorString.contains('reportfailed') ||
           errorString.contains('duplicate') ||
           errorString.contains('already submitted') ||
           errorString.contains('invalid category') ||
           errorString.contains('errorimagefilenotfound') ||
           errorString.contains('image file not found') ||
           errorString.contains('permission denied') ||
           errorString.contains('servererror') ||
           errorString.contains('errorcopyimagefailed') ||
           errorString.contains('errorfetchimagefromurl');
  }
  
  /// Maps technical errors to user-friendly localization keys
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (_isNetworkError(error)) {
      if (errorString.contains('timeout')) {
        return 'errorNetworkTimeout';
      } else if (errorString.contains('failed host lookup')) {
        return 'errorCannotConnectServer';
      } else {
        return 'errorNetworkFailureAutoRetry';
      }
    }
    
    // Business/server errors mapped to localization keys
    if (errorString.contains('validationerr')) {
      return 'validationErr';
    }
    if (errorString.contains('reportfailed')) {
      return 'reportFailed';
    }
    if (errorString.contains('errorimagefilenotfound') || errorString.contains('image file not found')) {
      return 'errorImageFileNotFound';
    }
    if (errorString.contains('errorcopyimagefailed')) {
      return 'errorCopyImageFailed';
    }
    if (errorString.contains('errorfetchimagefromurl')) {
      return 'errorFetchImageFromUrl';
    }
    if (errorString.contains('failedtoqueuereport')) {
      return 'failedToQueueReport';
    }
    if (errorString.contains('servererror')) {
      return 'serverError';
    }
    
    // Fallback to generic error
    return 'errorUnknown';
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _periodicTimer?.cancel();
    _queueController.close();
  }
}
