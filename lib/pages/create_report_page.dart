import 'dart:io';

import 'package:civicsnap_android/models/report.dart';
import 'package:civicsnap_android/services/db_services.dart';
import 'package:civicsnap_android/services/storage_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  XFile? _image;
  double? _latitude;
  double? _longitude;
  String? _city;
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  Position? location;
  bool _isLoading = false;
  bool _locationLoading = true;

  final List<String> _categories = [
    "Road Damage",
    "Garbage",
    "Street Light",
    "Water Supply",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _openCamera();
    await _getLocation();
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          setState(() => _locationLoading = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        location = position;
        _city = placemarks.isNotEmpty
            ? placemarks.first.locality ?? "Unknown"
            : "Unknown";
        _locationLoading = false;
      });
    } catch (_) {
      setState(() => _locationLoading = false);
    }
  }

  Future<void> _uploadReport() async {
    if (_image == null ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null ||
        location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all the required inputs.")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String imageUrl = await StorageServices().uploadImage(
        path: _image!.path,
      );

      final Report report = Report(
        imageUrl: imageUrl,
        latitude: location!.latitude,
        longitude: location!.longitude,
        description: _descriptionController.text,
        category: _selectedCategory!,
        uid: FirebaseAuth.instance.currentUser!.uid,
        uploadTime: DateTime.now(),
        status: "Under Review",
        remarks: "N/A",
      );

      await DbServices.uploadReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report submitted successfully!")),
        );
        context.go("/");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null || _locationLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Report Issue"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Photo",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Gap(8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_image!.path),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Location Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Location Details",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Gap(8),
                    _buildInfoRow(
                      context,
                      Icons.location_on_outlined,
                      "City",
                      _city ?? "Unknown",
                    ),
                    const Gap(10),
                    _buildInfoRow(
                      context,
                      Icons.gps_fixed_outlined,
                      "Coordinates",
                      _latitude != null
                          ? "(${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)})"
                          : "Unavailable",
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Report Details Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Report Details",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Gap(16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Category",
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const Gap(16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // Buttons Section
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadReport,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: const Text("Submit Report"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const Gap(16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () => context.go("/"),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text("Cancel"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
