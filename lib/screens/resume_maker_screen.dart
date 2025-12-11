import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'package:open_filex/open_filex.dart';

import '../providers/job_provider.dart';
import '../models/resume.dart';

class ResumeMakerScreen extends StatefulWidget {
  const ResumeMakerScreen({super.key});

  @override
  State<ResumeMakerScreen> createState() => _ResumeMakerScreenState();
}

class _ResumeMakerScreenState extends State<ResumeMakerScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resumes'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.folder_open), text: 'My Resumes'),
              Tab(icon: Icon(Icons.create), text: 'Create Resume'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [SavedResumesTab(), ResumeBuilderTab()],
        ),
      ),
    );
  }
}

class SavedResumesTab extends StatelessWidget {
  const SavedResumesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, provider, child) {
        final resumes = provider.resumes;
        // Group by category
        final Map<String, List<StoredResume>> grouped = {};
        for (var r in resumes) {
          if (!grouped.containsKey(r.category)) {
            grouped[r.category] = [];
          }
          grouped[r.category]!.add(r);
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _uploadResume(context),
            child: const Icon(Icons.upload_file),
          ),
          body: resumes.isEmpty
              ? const Center(child: Text("No resumes saved yet."))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            entry.key, // Category
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                          ),
                        ),
                        ...entry.value.map(
                          (resume) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                              title: Text(resume.name),
                              subtitle: Text(
                                "Added: ${resume.dateAdded.toString().split(' ')[0]}",
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  provider.deleteStoredResume(resume.id);
                                },
                              ),
                              onTap: () => _openResume(context, resume),
                            ),
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Future<void> _openResume(BuildContext context, StoredResume resume) async {
    if (kIsWeb) {
      if (resume.base64Content != null) {
        // Prepare bytes
        final bytes = base64Decode(resume.base64Content!);
        // Printing package can preview raw PDF bytes easily on web
        await Printing.layoutPdf(onLayout: (format) async => bytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot open file on Web without stored content."),
          ),
        );
      }
    } else {
      OpenFilex.open(resume.filePath);
    }
  }

  Future<void> _uploadResume(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb, // Important for Web
    );

    if (result != null) {
      final file = result.files.single;

      String? path = file.path;
      Uint8List? bytes = file.bytes;

      if (kIsWeb && bytes == null) {
        return;
      }

      // On Web path is null
      String filePath =
          path ?? 'web_upload_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (!context.mounted) return;
      _showAddDialog(context, filePath, bytes);
    }
  }

  void _showAddDialog(BuildContext context, String path, Uint8List? bytes) {
    // Handling path safely
    String initialName = path;
    try {
      initialName = path.split(Platform.pathSeparator).last;
    } catch (e) {
      // Fallback if path parsing fails or is empty
      initialName = "Resume";
    }

    final nameController = TextEditingController(text: initialName);
    String selectedCategory = 'Core';
    final categories = ['Core', 'IT', 'Management', 'Other'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Resume'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Resume Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newResume = StoredResume(
                id: const Uuid().v4(),
                name: nameController.text,
                filePath: path,
                category: selectedCategory,
                dateAdded: DateTime.now(),
                base64Content: bytes != null ? base64Encode(bytes) : null,
              );
              Provider.of<JobProvider>(
                context,
                listen: false,
              ).addStoredResume(newResume);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class ResumeBuilderTab extends StatefulWidget {
  const ResumeBuilderTab({super.key});

  @override
  State<ResumeBuilderTab> createState() => _ResumeBuilderTabState();
}

class _ResumeBuilderTabState extends State<ResumeBuilderTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _summaryController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  _nameController.text,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_emailController.text),
                  pw.Text(_phoneController.text),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildSection('Summary', _summaryController.text),
              _buildSection('Experience', _experienceController.text),
              _buildSection('Education', _educationController.text),
              _buildSection('Skills', _skillsController.text),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSection(String title, String content) {
    if (content.isEmpty) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(content),
        pw.SizedBox(height: 15),
      ],
    );
  }

  void _previewPdf() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Resume Preview')),
            body: PdfPreview(build: (format) => _generatePdf(format)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(_nameController, 'Full Name'),
            _buildTextField(_emailController, 'Email'),
            _buildTextField(_phoneController, 'Phone'),
            _buildTextField(
              _summaryController,
              'Professional Summary',
              maxLines: 3,
            ),
            _buildTextField(_experienceController, 'Experience', maxLines: 5),
            _buildTextField(_educationController, 'Education', maxLines: 3),
            _buildTextField(
              _skillsController,
              'Skills (comma separated)',
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _previewPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate & Preview PDF'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        maxLines: maxLines,
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
    );
  }
}
