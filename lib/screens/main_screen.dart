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
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      if (await Permission.storage.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission is required for updates. Please enable it in settings.',
            ),
          ),
        );
        openAppSettings();
      }
      return;
    }

    // Also request install packages permission (often handled by OS, but good to check)
    // Note: 'requestInstallPackages' is not a standard runtime permission request in the same way,
    // usually handled by intent, but managing storage is key for the download.

    if (!mounted) return;

    // Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Updating...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  LinearProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Downloading update..."),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      service
          .update(url)
          .listen(
            (OtaEvent event) {
              if (event.status == OtaStatus.DOWNLOADING) {
                // We can update progress here if we want to show %, but indefinite is fine for now
              } else if (event.status == OtaStatus.INSTALLING) {
                Navigator.pop(context); // Close dialog
              }
            },
            onError: (e) {
              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Update Error: $e")));
            },
            onDone: () {
              // Usually handled by INSTALLING or close
              // Navigator.pop(context);
            },
          );
    } catch (e) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error starting update: $e")));
    }
  }
}
