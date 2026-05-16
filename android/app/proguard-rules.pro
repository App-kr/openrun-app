# ─────────────────────────────────────────────────────────────────────────────
# Taekit ProGuard/R8 난독화 규칙
# 적용 대상: release 빌드 (minifyEnabled = true)
# ─────────────────────────────────────────────────────────────────────────────

# ── Flutter 기본 규칙 ─────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }

# ── Firebase / Google Services ────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# FCM
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.installations.** { *; }

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-keepattributes *Annotation*
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ── JSON 직렬화 (Dart json_serializable / 네이티브 파싱) ──────────────────────
# Gson/Jackson 미사용이나 혹시 모를 리플렉션 보호
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ── OkHttp (Dio 내부 사용) ────────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# ── Android 기본 컴포넌트 ─────────────────────────────────────────────────────
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# ── 알림 / 로컬 알림 (flutter_local_notifications) ───────────────────────────
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ── 크래시 디버깅을 위한 SourceFile/LineNumber 유지 ──────────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ── 직렬화 클래스 보호 ────────────────────────────────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ── Enum 보호 ─────────────────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Native 메서드 보호 ────────────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ── 불필요한 경고 제거 ────────────────────────────────────────────────────────
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.**
-dontwarn edu.umd.cs.findbugs.annotations.**
