import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import 'package:easy_localization/easy_localization.dart';

class ReportDetailsPage extends StatelessWidget {
  final String reportId;
  const ReportDetailsPage({super.key, required this.reportId});

  Future<Report?> _fetchReport() async {
    final doc = await FirebaseFirestore.instance
        .collection("reports")
        .doc(reportId)
        .get();

    if (!doc.exists) return null;
    return Report.fromJson(doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('reportDetailsTitle'.tr()), centerTitle: true),
      body: FutureBuilder<Report?>(
        future: _fetchReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'reportNotFound'.tr(),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final report = snapshot.data!;
          final formattedDate = DateFormat.yMMMd(
            context.locale.toString(),
          ).format(report.uploadTime);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportImage(report.imageUrl, context),
                const SizedBox(height: 20),
                Text(
                  report.category.tr(),
                  style: theme.textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.location_on,
                  'city'.tr(),
                  report.address,
                ),
                _buildInfoRow(
                  context,
                  Icons.category,
                  'category'.tr(),
                  report.category.tr(),
                ),
                _buildInfoRow(
                  context,
                  Icons.info_outline,
                  'status'.tr(),
                  report.status,
                ),
                _buildInfoRow(
                  context,
                  Icons.calendar_today,
                  'date'.tr(),
                  formattedDate,
                ),
                _buildInfoRow(
                  context,
                  Icons.description,
                  'description'.tr(),
                  report.description,
                ),
                _buildInfoRow(
                  context,
                  Icons.description,
                  'remarks'.tr(),
                  report.remarks,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openImageModal(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.red, size: 80),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportImage(String imageUrl, BuildContext context) {
    return InkWell(
      onTap: () => _openImageModal(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => SizedBox(
            height: 250,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text("Failed to load image".tr()),
                ],
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$label:", style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
