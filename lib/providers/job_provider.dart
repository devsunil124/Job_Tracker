import 'package:flutter/foundation.dart';
import '../models/job.dart';
import '../services/storage_service.dart';
import '../services/resume_service.dart';
import '../models/resume.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JobProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final ResumeService _resumeService = ResumeService();

  List<Job> _jobs = [];
  List<StoredResume> _resumes = [];
  bool _isLoading = false;

  List<Job> get jobs => _jobs;
  List<StoredResume> get resumes => _resumes;
  bool get isLoading => _isLoading;

  // Filtered lists
  List<Job> get appliedJobs =>
      _jobs.where((j) => j.status != 'Wishlist').toList();
  List<Job> get wishlistJobs =>
      _jobs.where((j) => j.status == 'Wishlist').toList();

  // Analytics getters
  int get totalApplications => appliedJobs.length;
  int get rejectedCount =>
      appliedJobs.where((j) => j.status == 'Rejected').length;
  int get noResponseCount =>
      appliedJobs.where((j) => j.status == 'No Response').length;
  int get activeCount => totalApplications - rejectedCount - noResponseCount;

  JobProvider() {
    loadJobs();
  }

  Future<void> loadJobs() async {
    _isLoading = true;
    notifyListeners();
    _jobs = await _storageService.loadJobs();
    await _loadResumes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addJob(Job job) async {
    _jobs.add(job);
    await _storageService.saveJobs(_jobs);
    notifyListeners();
  }

  Future<void> updateJobStatus(String id, String newStatus) async {
    final index = _jobs.indexWhere((j) => j.id == id);
    if (index != -1) {
      _jobs[index].status = newStatus;
      await _storageService.saveJobs(_jobs);
      notifyListeners();
    }
  }

  Future<String?> uploadResume(String jobId) async {
    return await _resumeService.pickAndSaveResume(jobId);
  }

  Future<Uint8List?> getResumeBytes(String jobId, String path) async {
    return await _resumeService.getResumeBytes(jobId, path);
  }

  Future<void> addToWishlist(Job job) async {
    job.status = 'Wishlist';
    await addJob(job);
  }

  Future<void> moveToApplied(String id) async {
    await updateJobStatus(id, 'Applied');
  }

  // --- Resume Logic ---

  Future<void> _loadResumes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? startData = prefs.getString('resumes');
    if (startData != null) {
      final List<dynamic> decoded = json.decode(startData);
      _resumes = decoded.map((item) => StoredResume.fromMap(item)).toList();
    }
  }

  Future<void> addStoredResume(StoredResume resume) async {
    _resumes.add(resume);
    await _saveResumes();
    notifyListeners();
  }

  Future<void> deleteStoredResume(String id) async {
    _resumes.removeWhere((r) => r.id == id);
    await _saveResumes();
    notifyListeners();
  }

  Future<void> _saveResumes() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_resumes.map((e) => e.toMap()).toList());
    await prefs.setString('resumes', encoded);
  }
}
