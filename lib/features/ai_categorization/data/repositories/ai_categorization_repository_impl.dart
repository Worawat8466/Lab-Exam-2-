import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ai_category_result.dart';
import '../../domain/repositories/ai_categorization_repository.dart';
import '../datasources/ai_cache_data_source.dart';
import '../datasources/gemini_remote_data_source.dart';

class AiCategorizationRepositoryImpl implements AiCategorizationRepository {
  const AiCategorizationRepositoryImpl({
    required GeminiRemoteDataSource remoteDataSource,
    required AiCacheDataSource cacheDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _cacheDataSource = cacheDataSource;

  final GeminiRemoteDataSource _remoteDataSource;
  final AiCacheDataSource _cacheDataSource;

  @override
  Future<Either<Failure, AiCategoryResult>> categorizeReceiptText(
    String rawText,
  ) async {
    try {
      final cached = await _cacheDataSource.getCached(rawText);
      if (cached != null) {
        return right(
          AiCategoryResult(
            category: cached.category,
            confidence: cached.confidence,
            reason: cached.reason,
          ),
        );
      }

      final remote = await _remoteDataSource.categorize(rawText);
      await _cacheDataSource.save(rawText, remote);

      return right(
        AiCategoryResult(
          category: remote.category,
          confidence: remote.confidence,
          reason: remote.reason,
        ),
      );
    } on DioException catch (error) {
      return left(NetworkFailure('AI request failed: ${error.message}'));
    } on FormatException catch (error) {
      return left(
        NetworkFailure('AI response format invalid: ${error.message}'),
      );
    } catch (error) {
      return left(CacheFailure('AI categorization failed: $error'));
    }
  }
}
