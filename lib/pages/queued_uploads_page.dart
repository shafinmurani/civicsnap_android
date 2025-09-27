import 'dart:io';
import 'package:flutter/material.dart';
import 'package:civicsnap_android/models/upload_queue_item.dart';
import 'package:civicsnap_android/services/upload_queue_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gap/gap.dart';

class QueuedUploadsPage extends StatefulWidget {
  const QueuedUploadsPage({super.key});

  @override
  State<QueuedUploadsPage> createState() => _QueuedUploadsPageState();
}

class _QueuedUploadsPageState extends State<QueuedUploadsPage> {
  final UploadQueueService _queueService = UploadQueueService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('queuedUploads'.tr()),
        centerTitle: true,
      ),
      body: StreamBuilder<List<UploadQueueItem>>(
        stream: _queueService.queueStream,
        initialData: _queueService.currentQueue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final queueItems = snapshot.data ?? [];

          if (queueItems.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: queueItems.length,
            itemBuilder: (context, index) {
              final item = queueItems[index];
              return _buildQueueItem(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const Gap(16),
          Text(
            'noQueuedUploads'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const Gap(8),
          Text(
            'noQueuedUploadsDescription'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(UploadQueueItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(item.imagePath),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.report.category.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Gap(4),
                      Text(
                        item.report.description.isNotEmpty
                            ? item.report.description
                            : 'noDescription'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Text(
                        'queuedAt'.tr(namedArgs: {
                          'time': DateFormat('MMM dd, yyyy HH:mm')
                              .format(item.queuedAt)
                        }),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(item.status),
              ],
            ),
            const Gap(12),
            _buildStatusIndicator(item),
            if (item.status == UploadStatus.failed || item.status == UploadStatus.permanentFailure) ...[
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.errorMessage ?? 'unknownError'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Show retry for both network and non-network failures
                      TextButton(
                        onPressed: () => _queueService.retryFailedUpload(item.id),
                        child: Text('retryUpload'.tr()),
                      ),
                      TextButton(
                        onPressed: () => _showDeleteConfirmation(item.id),
                        child: Text('cancelUpload'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.queued:
        return Icon(Icons.schedule, color: Colors.orange[600], size: 20);
      case UploadStatus.aiValidation:
        return Icon(Icons.psychology, color: Colors.cyan[600], size: 20);
      case UploadStatus.uploadingImage:
        return Icon(Icons.cloud_upload, color: Colors.blue[600], size: 20);
      case UploadStatus.verification:
        return Icon(Icons.verified, color: Colors.purple[600], size: 20);
      case UploadStatus.uploaded:
        return Icon(Icons.check_circle, color: Colors.green[600], size: 20);
      case UploadStatus.failed:
        return Icon(Icons.error, color: Colors.red[600], size: 20);
      case UploadStatus.permanentFailure:
        return Icon(Icons.block, color: Colors.red[800], size: 20);
    }
  }

  Widget _buildStatusIndicator(UploadQueueItem item) {
    String statusText;
    Color? progressColor;
    
    switch (item.status) {
      case UploadStatus.queued:
        statusText = 'statusQueued'.tr();
        progressColor = Colors.orange;
        break;
      case UploadStatus.aiValidation:
        statusText = 'statusAiValidation'.tr();
        progressColor = Colors.cyan;
        break;
      case UploadStatus.uploadingImage:
        statusText = 'statusUploadingImage'.tr();
        progressColor = Colors.blue;
        break;
      case UploadStatus.verification:
        statusText = 'statusVerification'.tr();
        progressColor = Colors.purple;
        break;
      case UploadStatus.uploaded:
        statusText = 'statusUploaded'.tr();
        progressColor = Colors.green;
        break;
      case UploadStatus.failed:
        statusText = 'statusFailed'.tr();
        progressColor = Colors.red;
        break;
      case UploadStatus.permanentFailure:
        statusText = 'statusPermanentFailure'.tr();
        progressColor = Colors.redAccent;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: progressColor,
              ),
            ),
            if (item.progress != null)
              Text(
                '${(item.progress! * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: progressColor,
                ),
              ),
          ],
        ),
        const Gap(4),
        LinearProgressIndicator(
          value: item.progress ?? (item.status == UploadStatus.queued ? 0 : 1),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(progressColor ?? Colors.grey),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirmDelete'.tr()),
        content: Text('confirmDeleteQueuedUpload'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _queueService.removeFromQueue(itemId);
    }
  }
}