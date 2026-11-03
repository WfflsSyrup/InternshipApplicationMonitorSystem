class ApplicationModel {
  const ApplicationModel({
    required this.id,
    required this.applicationNumber,
    this.studentName,
    required this.studentId,
    required this.companyName,
    required this.position,
    required this.stage,
    required this.workflowState,
    required this.interviewStatus,
  });

  final String id;
  final String applicationNumber;
  final String? studentName;
  final String? studentId;
  final String? companyName;
  final String? position;
  final String stage;
  final String workflowState;
  final String interviewStatus;

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'].toString(),
      applicationNumber: json['application_number'] as String,
      studentName: json['student_name'] as String?,
      studentId: json['student_id'] as String?,
      companyName: json['company_name'] as String?,
      position: json['position'] as String?,
      stage: json['stage'] as String,
      workflowState: json['workflow_state'] as String,
      interviewStatus: json['interview_status'] as String,
    );
  }
}
