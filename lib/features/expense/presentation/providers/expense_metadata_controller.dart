import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_tag.dart';
import '../../domain/usecases/delete_expense_category_usecase.dart';
import '../../domain/usecases/delete_expense_tag_usecase.dart';
import '../../domain/usecases/get_expense_metadata_usecase.dart';
import '../../domain/usecases/save_expense_category_usecase.dart';
import '../../domain/usecases/save_expense_tag_usecase.dart';

final expenseMetadataControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      ExpenseMetadataController,
      ExpenseMetadataBundle
    >(ExpenseMetadataController.new);

class ExpenseMetadataController
    extends AutoDisposeAsyncNotifier<ExpenseMetadataBundle> {
  @override
  Future<ExpenseMetadataBundle> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> saveCategory({
    required String name,
    int? existingId,
    DateTime? createdAt,
    bool isDefault = false,
    String? emoji,
    String? colorHex,
  }) async {
    final now = DateTime.now();
    final useCase = sl<SaveExpenseCategoryUseCase>();
    final result = await useCase(
      SaveExpenseCategoryParams(
        category: ExpenseCategory(
          id: existingId ?? 0,
          name: name,
          emoji: emoji,
          colorHex: colorHex,
          isDefault: isDefault,
          createdAt: createdAt ?? now,
          updatedAt: now,
        ),
      ),
    );

    result.fold((failure) => throw Exception(failure.message), (_) {});
    await refresh();
  }

  Future<void> saveTag({required String name}) async {
    final now = DateTime.now();
    final useCase = sl<SaveExpenseTagUseCase>();
    final result = await useCase(
      SaveExpenseTagParams(
        tag: ExpenseTag(id: 0, name: name, createdAt: now, updatedAt: now),
      ),
    );

    result.fold((failure) => throw Exception(failure.message), (_) {});
    await refresh();
  }

  Future<void> deleteCategory(int id) async {
    final useCase = sl<DeleteExpenseCategoryUseCase>();
    final result = await useCase(DeleteExpenseCategoryParams(id: id));
    result.fold((failure) => throw Exception(failure.message), (_) {});
    await refresh();
  }

  Future<void> deleteTag(int id) async {
    final useCase = sl<DeleteExpenseTagUseCase>();
    final result = await useCase(DeleteExpenseTagParams(id: id));
    result.fold((failure) => throw Exception(failure.message), (_) {});
    await refresh();
  }

  Future<ExpenseMetadataBundle> _load() async {
    final useCase = sl<GetExpenseMetadataUseCase>();
    final result = await useCase(const NoParams());
    return result.fold((failure) => throw Exception(failure.message), (data) {
      return data;
    });
  }
}
