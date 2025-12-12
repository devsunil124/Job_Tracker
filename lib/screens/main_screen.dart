import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'wishlist_screen.dart';
import 'resume_maker_screen.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:ota_update/ota_update.dart';
import '../services/update_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WishlistScreen(),
    const ResumeMakerScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.system_update),
            onPressed: _handleUpdateCheck,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Resume',
          ),
        ],
      ),
    );
  }

  void _handleUpdateCheck() {
    final updateService = UpdateService();
    _checkForUpdate(updateService);
  }

  Future<void> _checkForUpdate(UpdateService service) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Checking for updates...')));

      final updateInfo = await service.checkForUpdate();

      if (!mounted) return;

      if (updateInfo != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Available'),
            content: Text(
              'New version ${updateInfo['version']} is available. Download now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startUpdate(service, updateInfo['url']);
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('App is up to date!')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _startUpdate(UpdateService service, String url) async {
    // Request storage permission
    if (await Permission.storage.request().isGranted) {
      // Permission granted
    } else if (await Permission.storage.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Storage permission required. Please enable in settings.',
          ),
        ),
      );
      openAppSettings();
      return;
    }

    if (!mounted) return;

    // Progress Notifier
    ValueNotifier<String> progressNotifier = ValueNotifier("Initializing...");
    ValueNotifier<double?> percentNotifier = ValueNotifier(null);

    // Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Updating...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double?>(
                valueListenable: percentNotifier,
                builder: (context, percent, child) {
                  return LinearProgressIndicator(value: percent);
                },
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<String>(
                valueListenable: progressNotifier,
                builder: (context, message, child) {
                  return Text(message);
                },
              ),
            ],
          ),
        );
      },
    );

    try {
      service
          .update(url)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: (sink) {
              sink.addError("Connection timed out. Please try again.");
            },
          )
          .listen(
            (OtaEvent event) {
              if (event.status == OtaStatus.DOWNLOADING) {
                // Update progress
                final progress = event.value; // string "10", "20" etc
                if (progress != null) {
                  try {
                    int p = int.parse(progress);
                    percentNotifier.value = p / 100.0;
                    progressNotifier.value = "Downloading: $p%";
                  } catch (_) {
                    progressNotifier.value = "Downloading...";
                  }
                }
              } else if (event.status == OtaStatus.INSTALLING) {
                progressNotifier.value = "Installing...";
                percentNotifier.value = null; // Indeterminate
                Navigator.pop(context); // Close dialog (or keep it open?)
                // Usually OTA Update plugin handles installation intent, so pop is safe
              } else if (event.status ==
                  OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
                Navigator.pop(context);
                _showErrorDialog("Permission not granted for update.");
              } else if (event.status == OtaStatus.INTERNAL_ERROR) {
                Navigator.pop(context);
                _showErrorDialog("Internal error (OTA) during update.");
              } else if (event.status == OtaStatus.DOWNLOAD_ERROR) {
                Navigator.pop(context);
                _showErrorDialog("Download failed. Check internet connection.");
              }
            },
            onError: (e) {
              if (!mounted) return;
              Navigator.pop(context); // Close progress dialog
              _showErrorDialog("Update Error: $e");
            },
          );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog
      _showErrorDialog("Error starting update: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
