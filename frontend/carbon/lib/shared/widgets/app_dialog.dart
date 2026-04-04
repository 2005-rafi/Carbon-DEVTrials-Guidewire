import 'package:flutter/material.dart';

class AppDialog {
  static Future<bool> showExitConfirmation(BuildContext context) async {
    final result =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Exit App?'),
              content: const Text('Do you want to close Carbon?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ??
        false;

    return result;
  }
}
