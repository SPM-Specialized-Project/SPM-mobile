param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$fixturePath = Join-Path $workspace 'output\tssa-validation-20261004\preview-fixture.json'
$fixture = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json
$copyRoot = Join-Path $workspace 'output\tssa-validation-20261004\android-app'
New-Item -ItemType Directory -Force -Path $copyRoot | Out-Null
foreach ($folder in @('lib','assets','integration_test')) {
  Copy-Item -LiteralPath (Join-Path $workspace $folder) -Destination $copyRoot -Recurse -Force
}
$androidTarget = Join-Path $copyRoot 'android'
New-Item -ItemType Directory -Force -Path $androidTarget | Out-Null
Get-ChildItem -LiteralPath (Join-Path $workspace 'android') -Force |
  Where-Object { $_.Name -notin @('.gradle','build') } |
  ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $androidTarget -Recurse -Force }
foreach ($file in @('pubspec.yaml','pubspec.lock','analysis_options.yaml')) {
  Copy-Item -LiteralPath (Join-Path $workspace $file) -Destination $copyRoot -Force
}
$gradle = Join-Path $androidTarget 'app\build.gradle.kts'
$source = Get-Content -LiteralPath $gradle -Raw
$source = $source.Replace('applicationId = "com.example.spm_mobile"','applicationId = "com.example.spm_mobile.validation"')
Set-Content -LiteralPath $gradle -Value $source -Encoding utf8
$manifest = Join-Path $androidTarget 'app\src\main\AndroidManifest.xml'
$source = Get-Content -LiteralPath $manifest -Raw
Set-Content -LiteralPath $manifest -Value ($source.Replace('android:label="Tutor Support System"','android:label="SPM Validation"')) -Encoding utf8
Push-Location $copyRoot
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'Validation dependency resolution failed.' }
  flutter test integration_test/tssa_smoke_test.dart -d $Device `
    --dart-define=TEST_ISOLATED_ANDROID=true `
    --dart-define=API_BASE_URL=http://10.0.2.2:4317 `
    "--dart-define=TEST_LEARNER_EMAIL=$($fixture.learnerEmail)" `
    "--dart-define=TEST_TUTOR_EMAIL=$($fixture.tutorEmail)" `
    "--dart-define=TEST_PASSWORD=$($fixture.password)" `
    "--dart-define=TEST_BOOKING_ID=$($fixture.bookingId)" --reporter expanded
  if ($LASTEXITCODE -ne 0) { throw 'Android integration test failed.' }
} finally { Pop-Location }
