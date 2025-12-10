import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/job_provider.dart';
import '../models/job.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<JobProvider>(
            builder: (context, jobProvider, child) {
              final jobs =
                  jobProvider.appliedJobs; // Exclude wishlist for main stats

              if (jobProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Greeting
                  Text(
                    'Hi Sunil',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    'Here is your job search progress',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Quick Stats Row
                  _buildQuickStats(context, jobs),

                  const SizedBox(height: 24),

                  // Pie Chart
                  if (jobs.isNotEmpty) ...[
                    Text(
                      'Application Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 200, child: _buildPieChart(jobs)),
                  ],

                  const SizedBox(height: 24),

                  // Recent Activity
                  Text(
                    'Recent Applications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRecentActivity(jobs),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, List<Job> jobs) {
    final total = jobs.length;
    final interviews = jobs.where((j) => j.status == 'Interview').length;
    final offers = jobs.where((j) => j.status == 'Offer').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Applied',
            total.toString(),
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Interviews',
            interviews.toString(),
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Offers',
            offers.toString(),
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Job> jobs) {
    // Calculate distribution
    final statusCounts = <String, int>{};
    for (var job in jobs) {
      statusCounts[job.status] = (statusCounts[job.status] ?? 0) + 1;
    }

    final sections = statusCounts.entries.map((entry) {
      final color = _getStatusColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        _buildLegend(statusCounts),
      ],
    );
  }

  Widget _buildLegend(Map<String, int> statusCounts) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: statusCounts.keys.map((status) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(status),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity(List<Job> jobs) {
    // Sort by date descending
    final recentJobs = List<Job>.from(jobs)
      ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
    final displayJobs = recentJobs.take(3).toList();

    if (displayJobs.isEmpty) {
      return const Text("No recent activity.");
    }

    return Column(
      children: displayJobs
          .map(
            (job) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  job.company,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(job.role),
                trailing: Chip(
                  label: Text(
                    job.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(job.status),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Applied':
        return Colors.blue;
      case 'Interview':
        return Colors.orange;
      case 'Offer':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'No Response':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }
}
