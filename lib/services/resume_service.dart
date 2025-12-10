import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class ResumeService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final resumeDir = Directory(p.join(directory.path, 'resumes'));
    if (!await resumeDir.exists()) {
      await resumeDir.create(recursive: true);
    }
    return resumeDir.path;
  }

  Future<String?> pickAndSaveResume(String jobId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, // Important for Web to get bytes
      );

      if (result != null) {
        if (kIsWeb) {
          // On Web, save bytes to SharedPreferences
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            final prefs = await SharedPreferences.getInstance();
            final base64File = base64Encode(bytes);
            await prefs.setString('resume_data_$jobId', base64File);
            return result.files.single.name;
          }
        }

        if (result.files.single.path != null) {
          final sourcePath = result.files.single.path!;
          final sourceFile = File(sourcePath);

          final resumeDirPath = await _localPath;
          final extension = p.extension(sourcePath);
          final fileName = '${jobId}_resume$extension';
          final destinationPath = p.join(resumeDirPath, fileName);

          await sourceFile.copy(destinationPath);
          return destinationPath;
        }
      }
      return null;
    } catch (e) {
      print('Error picking/saving resume: $e');
      return null;
    }
  }

  Future<Uint8List?> getResumeBytes(String jobId, String path) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final base64File = prefs.getString('resume_data_$jobId');
        if (base64File != null) {
          return base64Decode(base64File);
        }
      } else {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (e) {
      print('Error getting resume bytes: $e');
    }
    return null;
  }
}
