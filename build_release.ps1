# 택킷 릴리즈 빌드 스크립트 — 원클릭 실행
# 사용법: 우클릭 -> "PowerShell로 실행"
# 또는 PowerShell에서: .\build_release.ps1

Set-Location $PSScriptRoot

# ── 1. pubspec.yaml에서 현재 버전 읽기 ──────────────────────────
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match 'version:\s+(\d+\.\d+\.\d+)\+(\d+)') {
    $versionName = $matches[1]
    $versionCode = [int]$matches[2]
} else {
    Write-Host "ERROR: pubspec.yaml에서 version을 읽을 수 없습니다." -ForegroundColor Red
    exit 1
}

# ── 2. versionCode +1 자동 증가 ──────────────────────────────────
$newVersionCode = $versionCode + 1
$newVersion = "${versionName}+${newVersionCode}"

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  택킷 릴리즈 빌드" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  이전: $versionName+$versionCode"
Write-Host "  신규: $newVersion (versionCode=$newVersionCode)" -ForegroundColor Green
Write-Host ""

# ── 3. pubspec.yaml 업데이트 ────────────────────────────────────
$pubspec = $pubspec -replace "version:\s+\d+\.\d+\.\d+\+\d+", "version: $newVersion"
Set-Content "pubspec.yaml" $pubspec -NoNewline

# ── 4. build.gradle versionCode 동기화 ──────────────────────────
$gradle = Get-Content "android/app/build.gradle" -Raw
$gradle = $gradle -replace "versionCode \d+", "versionCode $newVersionCode"
$gradle = $gradle -replace 'versionName "[^"]+"', "versionName `"$versionName`""
Set-Content "android/app/build.gradle" $gradle -NoNewline

Write-Host "빌드 시작..." -ForegroundColor Yellow
Write-Host ""

# ── 5. Flutter 빌드 (명시적 build-number 전달) ──────────────────
$buildResult = & flutter build appbundle --release `
    --build-number=$newVersionCode `
    --build-name=$versionName 2>&1

$buildOutput = $buildResult | Out-String
Write-Host $buildOutput

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: 빌드 실패!" -ForegroundColor Red
    # 실패 시 pubspec.yaml 롤백
    $pubspec = $pubspec -replace "version:\s+\d+\.\d+\.\d+\+\d+", "version: ${versionName}+${versionCode}"
    Set-Content "pubspec.yaml" $pubspec -NoNewline
    Write-Host "pubspec.yaml 롤백 완료." -ForegroundColor Yellow
    Read-Host "엔터를 눌러 종료"
    exit 1
}

# ── 6. 올바른 파일(app-release.aab) 복사 ────────────────────────
$src = "build\app\outputs\bundle\release\app-release.aab"
$destName = "taekit_v${newVersionCode}.aab"
$dest = "$env:USERPROFILE\Desktop\$destName"

if (Test-Path $src) {
    Copy-Item $src $dest -Force
    $size = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "  빌드 완료!" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "  파일: $destName ($size MB)" -ForegroundColor Green
    Write-Host "  versionCode: $newVersionCode" -ForegroundColor Green
    Write-Host "  versionName: $versionName" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Play Console 업로드 방법:" -ForegroundColor Cyan
    Write-Host "  1. Closed testing -> Manage track -> Create new release"
    Write-Host "  2. Upload -> 바탕화면의 $destName 선택"
    Write-Host "  3. Previous release 섹션의 구버전 번들 옆 ... -> Remove from release"
    Write-Host "  4. Next -> Save"
    Write-Host ""
} else {
    Write-Host "ERROR: app-release.aab 파일을 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "경로: $src" -ForegroundColor Red
    exit 1
}

Read-Host "엔터를 눌러 종료"
