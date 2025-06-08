class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    print('ApiResponse fromJson: $json');

    return ApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Logging outgoing JSON for debugging
    final json = {
      'success': success,
      'message': message,
      'data': data,
      'error': error,
    };

    print('ApiResponse toJson: $json');
    return json;
  }
}
