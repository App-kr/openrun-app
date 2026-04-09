# OpenRun — 공연 티켓 오픈 알림

국립·시립 공연장 클래식/국악 티켓 오픈 알림 Flutter 앱.

## 빌드 방법

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (freezed, riverpod, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 실행 (백엔드 URL 주입)
flutter run --dart-define=BACKEND_URL=https://your-api.example.com

# 릴리즈 빌드
flutter build apk --dart-define=BACKEND_URL=https://your-api.example.com
```

## Firebase 설정
1. Firebase Console에서 Android 앱 등록
2. `android/app/google-services.json` 다운로드 후 배치
3. FCM 서버 키 백엔드 환경변수로 설정

## 프로젝트 구조
```
lib/
├── main.dart
├── core/
│   ├── theme.dart       # AppColors + AppTheme
│   └── router.dart      # go_router + MainShell(BottomNav)
├── features/
│   ├── onboarding/      # Splash → Genre → City
│   ├── performances/    # 공연 목록 + PerfCard + CountdownTimer
│   ├── alarms/          # 알림 목록 + AlarmService
│   └── settings/        # 설정 화면
└── shared/
    ├── widgets/          # AppErrorWidget
    └── services/         # ApiService(Dio) + CacheService(sqflite) + NotificationService(FCM)
```

## 보안
- `booking_url` 화이트리스트 검증 후 url_launcher 실행
- FCM 토큰 `flutter_secure_storage` 암호화 저장
- `BACKEND_URL` `--dart-define` 으로만 주입 (코드에 하드코딩 금지)
