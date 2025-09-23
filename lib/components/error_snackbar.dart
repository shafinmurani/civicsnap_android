import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

void showErrorSnackbar(BuildContext context, String err) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(err),
      showCloseIcon: true,
      duration: Duration(seconds: 2),
    ),
  );
}
