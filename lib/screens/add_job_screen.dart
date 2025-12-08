import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';
import 'package:path/path.dart' as p;

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _resumePath;
  bool _isWishlist = false;
  late String _jobId;

  @override
  void initState() {
    super.initState();
    _jobId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final provider = Provider.of<JobProvider>(context, listen: false);

    final path = await provider.uploadResume(_jobId);
    if (path != null) {
      setState(() {
        _resumePath = path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resume attached: ${p.basename(path)}')),
      );
    }
  }

  void _saveJob() {
    if (_formKey.currentState!.validate()) {
      final newJob = Job(
        id: _jobId,
        company: _companyController.text,
        role: _roleController.text,
        status: _isWishlist ? 'Wishlist' : 'Applied',
        appliedDate: DateTime.now(),
        description: _descriptionController.text,
        resumePath: _resumePath,
      );

      Provider.of<JobProvider>(context, listen: false).addJob(newJob);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Job Application')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter company name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter role' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Add to Wishlist'),
                subtitle: const Text('Save for later instead of applying now'),
                value: _isWishlist,
                onChanged: (value) {
                  setState(() {
                    _isWishlist = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickResume,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach Resume'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _resumePath != null
                          ? 'Attached: ${p.basename(_resumePath!)}'
                          : 'No resume attached',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveJob,
                child: const Text('Save Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
