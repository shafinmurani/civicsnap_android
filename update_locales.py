#!/usr/bin/env python3
import json
import os

# Define the missing keys with their English values (to be translated)
missing_keys = {
    "queuedUploads": "Queued Uploads",
    "queuedUploadsTitle": "Queued Uploads", 
    "queuedUploadsSubtitle": "View your pending and processing uploads.",
    "noQueuedUploads": "No Queued Uploads",
    "noQueuedUploadsDescription": "All your reports have been uploaded successfully.",
    "statusQueued": "Queued",
    "statusAiValidation": "AI Validation",
    "statusUploadingImage": "Uploading Image", 
    "statusVerification": "Verification",
    "statusUploaded": "Uploaded",
    "statusFailed": "Failed",
    "statusPermanentFailure": "Permanent Failure",
    "queuedAt": "Queued at {time}",
    "retry": "Retry",
    "delete": "Delete",
    "confirmDelete": "Confirm Delete",
    "confirmDeleteQueuedUpload": "Are you sure you want to delete this queued upload?",
    "unknownError": "Unknown error occurred",
    "noDescription": "No description", 
    "reportQueuedSuccess": "Report queued for upload!",
    "failedToQueueReport": "Failed to queue report. Please try again.",
    "accountTitle": "Account",
    "logoutDescription": "Sign out of your account",
    "noImageSelected": "No image selected",
    "descriptionIsEmpty": "Please provide a description for your report.",
    "errorNetworkTimeout": "Network timeout. Please check your internet connection.",
    "errorCannotConnectServer": "Cannot connect to server. Please check your internet connection.",
    "errorNetworkFailureAutoRetry": "Network connection failed. Upload will retry automatically when connected.",
    "errorImageFileNotFound": "Image file not found. Please retry with a new photo.",
    "errorUnknown": "An unknown error occurred. Please try again."
}

# Get all JSON files in the translations directory
translations_dir = "./assets/translations"
json_files = [f for f in os.listdir(translations_dir) if f.endswith('.json')]

print("Updating locale files with missing keys...")
print(f"Found {len(json_files)} locale files: {json_files}")

for json_file in json_files:
    file_path = os.path.join(translations_dir, json_file)
    locale_code = json_file.replace('.json', '')
    
    try:
        # Read existing file
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Count existing keys
        original_count = len(data)
        
        # Add missing keys (with English values - would need manual translation)
        for key, value in missing_keys.items():
            if key not in data:
                data[key] = value
        
        # Write updated file
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        new_count = len(data)
        added_keys = new_count - original_count
        
        print(f"✓ Updated {locale_code}: {original_count} -> {new_count} keys (+{added_keys})")
        
    except Exception as e:
        print(f"✗ Error updating {locale_code}: {e}")

print("\nDone! All locale files have been updated with missing keys.")
print("Note: New keys use English text - manual translation is required for proper localization.")