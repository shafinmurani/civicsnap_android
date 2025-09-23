import 'dart:io';

import 'package:civicsnap_android/models/report.dart';
import 'package:civicsnap_android/services/db_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:easy_localization/easy_localization.dart';
import '../components/error_snackbar.dart';

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
  final TextEditingController _addressController = TextEditingController();

  // Use a map to store the English key and the localized value
  final Map<String, String> _categories = {
    'roadDamage': 'roadDamage'.tr(),
    'garbage': 'garbage'.tr(),
    'streetLight': 'streetLight'.tr(),
    'waterSupply': 'waterSupply'.tr(),
    'otherCategory': 'otherCategory'.tr(),
  };

  String? _selectedCategory; // This will now store the English key

  Position? location;
  bool _isLoading = false;
  bool _locationLoading = true;
  bool _isTakingPhoto = true;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _determinePosition();
    await _takePhoto();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _locationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      location = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        location!.latitude,
        location!.longitude,
      );

      if (mounted) {
        setState(() {
          _city = placemarks.first.locality;
          _latitude = location!.latitude;
          _longitude = location!.longitude;

          Placemark element;
          for (element in placemarks) {
            if (element == placemarks.last) {
              _addressController.text += "${element.name}";
            } else {
              _addressController.text += "${element.name}, ";
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'locationNotAvailable'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (!mounted) return;

    if (image != null) {
      setState(() {
        _image = image;
        _isTakingPhoto = false;
      });
    } else {
      setState(() {
        _isTakingPhoto = false;
      });
      if (mounted) {
        context.pop();
      }
    }
  }

  void _submitReport() async {
    if (_image == null) {
      if (mounted) showErrorSnackbar(context, 'imageNotSelected'.tr());
      return;
    }
    if (_selectedCategory == null) {
      if (mounted) showErrorSnackbar(context, 'categoryNotSelected'.tr());
      return;
    }
    if (_city == null) {
      if (mounted) showErrorSnackbar(context, 'locationNotAvailable'.tr());
    }
    if (_descriptionController.text.isEmpty) {
      if (mounted) showErrorSnackbar(context, 'descriptionIsEmpty'.tr());
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final report = Report(
        id: '',
        uid: FirebaseAuth.instance.currentUser!.uid,
        imageUrl: "",
        // The _selectedCategory now holds the English key, e.g., 'road_damage'
        category: _selectedCategory!,
        description: _descriptionController.text,
        latitude: _latitude!,
        longitude: _longitude!,
        city: _city!,
        address: _addressController.text,
        status: 'Submitted',
        uploadTime: DateTime.now(),
        remarks: "N/A",
        priority: "",
      );

      await DbServices.uploadReport(report, _image!.path);
      if (mounted) {
        showErrorSnackbar(context, 'reportSuccess'.tr());

        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString().split(": ")[1].tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTakingPhoto) {
      return Scaffold(
        appBar: AppBar(title: Text('reportTitle'.tr()), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const Gap(16),
              Text('openingCamera'.tr()),
            ],
          ),
        ),
      );
    }

    if (_image == null) {
      return Scaffold(
        appBar: AppBar(title: Text('reportTitle'.tr()), centerTitle: true),
        body: Center(child: Text('noImageSelected'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('reportTitle'.tr()), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_image!.path), fit: BoxFit.cover),
              ),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera),
              label: Text('retakePhoto'.tr()),
            ),
            const Gap(24),
            _buildInfoRow(
              context,
              Icons.location_city_sharp,
              'selectLocation'.tr(),
              _locationLoading
                  ? 'locationLoading'.tr()
                  : _city ?? 'locationNotAvailable'.tr(),
            ),
            const Gap(16),
            _buildInfoRow(
              context,
              Icons.location_on,
              'address'.tr(),
              _locationLoading
                  ? 'locationLoading'.tr()
                  : _addressController.text,
            ),
            const Gap(16),
            Text(
              'reportCategory'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'categoryPlaceholder'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              initialValue: _selectedCategory,
              onChanged: (String? newValue) {
                if (mounted) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              items: _categories.entries.map<DropdownMenuItem<String>>((
                MapEntry<String, String> entry,
              ) {
                return DropdownMenuItem<String>(
                  value: entry.key, // The unique English key
                  child: Text(entry.value), // The localized string for display
                );
              }).toList(),
            ),

            const Gap(16),
            Text(
              'addDescription'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'descriptionPlaceholder'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              maxLines: 4,
            ),
            const Gap(32),
            ElevatedButton(
              onPressed: (_isLoading || _locationLoading)
                  ? null
                  : _submitReport,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('submitReport'.tr()),
            ),
            const Gap(16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () => context.go("/"),
              icon: const Icon(Icons.cancel_outlined),
              label: Text('cancel'.tr()),
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
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
