class ApiResponseModel<T> {
  final bool success;
  final String message;
  final T? data;
  final String? errorCode;
  final Map<String, dynamic>? meta;

  ApiResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.meta,
  });

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errorCode: json['errorCode'],
      meta: json['meta'],
    );
  }
}
