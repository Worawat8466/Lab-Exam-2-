param(
    [switch]$RunIntegration,
    [switch]$RunApp
)

$ErrorActionPreference = 'Stop'

function Run-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
    & $Action
}

Run-Step -Title 'Flutter Pub Get' -Action {
    flutter pub get
}

Run-Step -Title 'Code Generation (build_runner)' -Action {
    dart run build_runner build --delete-conflicting-outputs
}

Run-Step -Title 'Unit + Widget Tests' -Action {
    flutter test test/widget_test.dart test/widget/features/expense/expense_form_validation_test.dart test/unit/features/expense/domain/usecases/create_expense_usecase_test.dart
}

if ($RunIntegration) {
    Run-Step -Title 'Integration Test' -Action {
        flutter test integration_test/app_e2e_test.dart
    }
}

if ($RunApp) {
    Run-Step -Title 'Run App' -Action {
        flutter run
    }
}

Write-Host "`nDemo preparation completed successfully." -ForegroundColor Green
