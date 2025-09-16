import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void showErrorSnackbar(BuildContext context, e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Some error occured, Please try again."),
      showCloseIcon: true,
      duration: Duration(seconds: 2),
    ),
  );
  if (kDebugMode) {
    print(e);
  }
}
