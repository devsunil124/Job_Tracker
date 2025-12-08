import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../theme/app_theme.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          final wishlist = jobProvider.wishlistJobs;

          if (wishlist.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your wishlist is empty'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: wishlist.length,
            itemBuilder: (context, index) {
              final job = wishlist[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor,
                    child: Icon(Icons.business, color: Colors.white),
                  ),
                  title: Text(
                    job.company,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(job.role),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add_task,
                      color: AppTheme.primaryColor,
                    ),
                    tooltip: 'Move to Applied',
                    onPressed: () {
                      jobProvider.moveToApplied(job.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Moved ${job.company} to Applied'),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
