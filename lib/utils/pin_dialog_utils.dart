import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> showParentalPinSetupDialog(BuildContext context, String userId) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final TextEditingController pinController = TextEditingController();
      final TextEditingController confirmPinController = TextEditingController();
      String? generalErrorMessage;

      void showSnackbar(String message, {bool isError = false}) {
        if (!dialogContext.mounted) return;
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : null,
          ),
        );
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set Parental PIN'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Please set a 4-digit PIN for supervisor access to the dashboard.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter 4-digit PIN',
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                    onChanged: (value) {
                      if (value.length == 4) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: 'Confirm 4-digit PIN',
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                  ),
                  if (generalErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        generalErrorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    generalErrorMessage = null;
                  });

                  if (pinController.text.length != 4 || confirmPinController.text.length != 4) {
                    setState(() {
                      generalErrorMessage = 'Both PIN fields must contain 4 digits.';
                    });
                    return;
                  }

                  if (pinController.text != confirmPinController.text) {
                    setState(() {
                      generalErrorMessage = 'PINs do not match.';
                      pinController.clear();
                      confirmPinController.clear();
                    });
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance.collection('users').doc(userId).set({
                      'parentalPin': pinController.text,
                      'pinSetAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    showSnackbar('Parental PIN set successfully!');
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  } on FirebaseException catch (e) {
                    setState(() {
                      generalErrorMessage = 'Failed to set PIN: ${e.message ?? 'Unknown Firebase error'}';
                    });
                    showSnackbar(generalErrorMessage!, isError: true);
                  } catch (e) {
                    setState(() {
                      generalErrorMessage = 'An unexpected error occurred: $e';
                    });
                    showSnackbar(generalErrorMessage!, isError: true);
                  }
                },
                child: const Text('Set PIN'),
              ),
            ],
          );
        },
      );
    },
  );
}