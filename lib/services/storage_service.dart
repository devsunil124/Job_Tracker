import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job.dart';

class StorageService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File(p.join(path, 'jobs.json'));
  }

  Future<List<Job>> loadJobs() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final content = prefs.getString('jobs_data');
        if (content == null) return [];
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((json) => Job.fromJson(json)).toList();
      } else {
        final file = await _localFile;
        if (!await file.exists()) {
          return [];
        }
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((json) => Job.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading jobs: $e');
      return [];
    }
  }

  Future<void> saveJobs(List<Job> jobs) async {
    try {
      final jsonList = jobs.map((job) => job.toJson()).toList();
      final content = jsonEncode(jsonList);

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jobs_data', content);
      } else {
        final file = await _localFile;
        await file.writeAsString(content);
      }
    } catch (e) {
      print('Error saving jobs: $e');
    }
  }
}
