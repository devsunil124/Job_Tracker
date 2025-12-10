import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'wishlist_screen.dart';
import 'resume_maker_screen.dart';

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

  void _startUpdate(UpdateService service, String url) {
    service
        .update(url)
        .listen(
          (OtaEvent event) {
            if (event.status == OtaStatus.DOWNLOADING) {
              // Optional: Show progress, maybe update a state to show a progress bar
              // print("Downloading: ${event.value}%");
            } else if (event.status == OtaStatus.INSTALLING) {
              // Installation started
            }
          },
          onError: (e) {
            print("Update Error: $e");
          },
        );
  }
}
