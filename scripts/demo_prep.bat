@echo off
setlocal

echo.
echo === Flutter Pub Get ===
flutter pub get || exit /b 1

echo.
echo === Code Generation (build_runner) ===
dart run build_runner build --delete-conflicting-outputs || exit /b 1

echo.
echo === Unit + Widget Tests ===
flutter test test\widget_test.dart test\widget\features\expense\expense_form_validation_test.dart test\unit\features\expense\domain\usecases\create_expense_usecase_test.dart || exit /b 1

echo.
echo Demo preparation completed successfully.
endlocal
