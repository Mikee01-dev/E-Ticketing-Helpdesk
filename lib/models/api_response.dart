class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.fromMap(Map<String, dynamic> map, T Function(dynamic) fromJson) {
    if (map['error'] != null) {
      return ApiResponse.error(
        map['error']['message'] ?? 'Unknown error',
        statusCode: map['error']['code'],
      );
    }
    
    return ApiResponse.success(
      fromJson(map['data'] ?? map),
      message: map['message'],
    );
  }
}