import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../models/loan.dart';
import '../models/page_result.dart';

class LoanRepository {
  LoanRepository(this._dio);

  final Dio _dio;

  Future<PageResult<Loan>> find({
    int page = 1,
    int size = 20,
    int? readerId,
    int? bookId,
    String? status,
  }) => guard(() async {
    final response = await _dio.get(
      '/loans',
      queryParameters: {
        'page': page,
        'size': size,
        if (readerId != null) 'readerId': readerId,
        if (bookId != null) 'bookId': bookId,
        if (status != null) 'status': status,
        'sort': 'issuedAt,desc',
      },
    );
    return parsePage(response.data, Loan.fromJson, fallbackSize: size);
  });

  Future<Loan> createLoan({
    required int readerId,
    required int bookId,
    int days = 14,
  }) => guard(() async {
    final response = await _dio.post(
      '/loans',
      data: {'readerId': readerId, 'bookId': bookId, 'days': days},
    );
    return Loan.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<Loan> returnLoan(int id) => guard(() async {
    final response = await _dio.post('/loans/$id/return');
    return Loan.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<Loan> renewLoan(int id, {int days = 14}) => guard(() async {
    final response = await _dio.post('/loans/$id/renew', data: {'days': days});
    return Loan.fromJson(Map<String, dynamic>.from(response.data as Map));
  });
}
