/// HTML entity 디코더 — 공연 데이터 API 응답 처리용
String htmlDecode(String text) => text
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#x27;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&#34;', '"')
    .replaceAll('&nbsp;', ' ');
