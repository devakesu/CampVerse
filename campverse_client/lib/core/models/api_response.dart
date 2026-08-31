/// Standardized API envelope response structure.
class ApiResponse<T> {
  /// Default constructor for immutable API response.
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  /// Factory deserializer converting JSON map to typed ApiResponse.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'] as String?,
      message: json['message'] as String?,
    );
  }

  /// Whether the request succeeded.
  final bool success;

  /// Typed payload data if successful.
  final T? data;

  /// Error message if request failed.
  final String? error;

  /// Informational response message.
  final String? message;
}
