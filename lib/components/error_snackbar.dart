import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void showErrorSnackbar(BuildContext context, e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("reportFailed".tr()),
      showCloseIcon: true,
      duration: Duration(seconds: 2),
    ),
  );
  if (kDebugMode) {
    print(e);
  }
}
