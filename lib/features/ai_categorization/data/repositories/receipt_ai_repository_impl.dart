import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../expense/domain/entities/expense.dart';
import '../../domain/entities/parsed_receipt_data.dart';
import '../../domain/repositories/receipt_ai_repository.dart';
import '../datasources/receipt_ai_cache_data_source.dart';
import '../datasources/receipt_ai_remote_data_source.dart';
import '../models/parsed_receipt_data_dto.dart';

class ReceiptAiRepositoryImpl implements ReceiptAiRepository {
  const ReceiptAiRepositoryImpl({
    required ReceiptAiRemoteDataSource remoteDataSource,
    required ReceiptAiCacheDataSource cacheDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _cacheDataSource = cacheDataSource;

  final ReceiptAiRemoteDataSource _remoteDataSource;
  final ReceiptAiCacheDataSource _cacheDataSource;

  @override
  Future<Either<Failure, ParsedReceiptData>> parseReceiptText(
    String rawText,
  ) async {
    try {
      final cached = await _cacheDataSource.getCached(rawText);
      if (cached != null) {
        return right(_mapToDomain(cached));
      }

      final remote = await _remoteDataSource.parseReceiptText(rawText);
      await _cacheDataSource.save(rawText, remote);
      return right(_mapToDomain(remote));
    } on DioException catch (error) {
      return left(
        NetworkFailure('AI receipt parse request failed: ${error.message}'),
      );
    } on FormatException catch (error) {
      return left(
        NetworkFailure('AI receipt parse format invalid: ${error.message}'),
      );
    } catch (error) {
      return left(CacheFailure('AI receipt parsing failed: $error'));
    }
  }

  ParsedReceiptData _mapToDomain(ParsedReceiptDataDto cached) {
    final occurredAt = (cached.occurredAt == null || cached.occurredAt!.isEmpty)
        ? null
        : DateTime.tryParse(cached.occurredAt!);

    return ParsedReceiptData(
      transactionType: _mapTransactionType(cached.transactionType),
      merchant: cached.merchant,
      suggestedCategory: cached.suggestedCategory,
      amount: cached.amount,
      currency: cached.currency,
      suggestedTags: cached.suggestedTags,
      occurredAt: occurredAt,
      reasoning: cached.reasoning,
      confidence: cached.confidence,
    );
  }

  TransactionType _mapTransactionType(String type) {
    final value = type.toLowerCase().trim();
    if (value == 'income') {
      return TransactionType.income;
    }

    return TransactionType.expense;
  }
}
