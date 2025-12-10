import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String _repoOwner = 'devsunil124';
  static const String _repoName = 'Job_Tracker';

  /// Checks if an update is available on GitHub Releases
  Future<Map<String, dynamic>?> checkForUpdate() async {
    final url = Uri.parse(
      "https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String tagName = data['tag_name'] ?? '';
        final String serverVersion = tagName.replaceAll(
          'v',
          '',
        ); // Remove 'v' prefix if present

        // Find asset
        final List assets = data['assets'] ?? [];
        final apkAsset = assets.firstWhere(
          (asset) => asset['name'] == 'app-release.apk',
          orElse: () => null,
        );

        if (apkAsset == null) {
          print("Release found but 'app-release.apk' is missing.");
          return null;
        }

        final String downloadUrl = apkAsset['browser_download_url'];

        // Get current app version
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isVersionNewer(serverVersion, currentVersion)) {
          return {"version": serverVersion, "url": downloadUrl};
        }
      } else {
        print("GitHub API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error checking for updates: $e");
      rethrow;
    }
    return null; // No update available
  }

  /// Starts the OTA update
  Stream<OtaEvent> update(String url) {
    return OtaUpdate().execute(url);
  }

  bool _isVersionNewer(String serverVersion, String currentVersion) {
    // Simple semantic version check (assumes x.y.z)
    try {
      List<int> s = serverVersion.split('.').map(int.parse).toList();
      List<int> c = currentVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < s.length && i < c.length; i++) {
        if (s[i] > c[i]) return true;
        if (s[i] < c[i]) return false;
      }
      return s.length > c.length;
    } catch (e) {
      print("Error parsing versions: $e");
      return false;
    }
  }
}
