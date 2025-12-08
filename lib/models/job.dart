class Job {
  final String id;
  final String company;
  final String role;
  String status;
  final DateTime appliedDate;
  String? resumePath;
  String? description;

  Job({
    required this.id,
    required this.company,
    required this.role,
    required this.status,
    required this.appliedDate,
    this.resumePath,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'role': role,
      'status': status,
      'appliedDate': appliedDate.toIso8601String(),
      'resumePath': resumePath,
      'description': description,
    };
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      company: json['company'],
      role: json['role'],
      status: json['status'],
      appliedDate: DateTime.parse(json['appliedDate']),
      resumePath: json['resumePath'],
      description: json['description'],
    );
  }
}
