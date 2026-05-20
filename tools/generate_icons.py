"""
택킷(Taekit) 아이콘 생성 스크립트
- assets/icons/classic/conductor.png  — 클래식 로고 (흰색 음표/오선, 투명 배경)
- assets/icons/gugak/gayageum.png     — 국악 로고  (흰색 가야금, 투명 배경)
- android/app/src/main/res/mipmap-*/ic_launcher.png  — 안드로이드 앱 아이콘 전 사이즈
실행: python tools/generate_icons.py
"""

import math, os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).parent.parent
ASSETS = ROOT / "assets"
ANDROID_RES = ROOT / "android/app/src/main/res"

# ── 팔레트 ────────────────────────────────────────────────────────────────────
NAVY   = (13, 43, 78, 255)      # #0D2B4E
AMBER  = (184, 114, 10, 255)    # #B8720A
WHITE  = (255, 255, 255, 255)
WHITE70 = (255, 255, 255, 178)
TRANSP = (0, 0, 0, 0)


# ─────────────────────────────────────────────────────────────────────────────
# 공통 헬퍼
# ─────────────────────────────────────────────────────────────────────────────
def circle_mask(size: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size-1, size-1], fill=255)
    return mask


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG", optimize=True)
    print(f"  OK {path.relative_to(ROOT)}  ({img.width}x{img.height})")


# ─────────────────────────────────────────────────────────────────────────────
# 클래식 아이콘 — 원형 배경 없이 흰 음자리표+선 (투명 배경, splash container가 navy)
# ─────────────────────────────────────────────────────────────────────────────
def make_classic_icon(size: int = 300) -> Image.Image:
    img = Image.new("RGBA", (size, size), TRANSP)
    d   = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    s  = size / 300  # scale factor

    def p(x, y): return (x * s, y * s)

    # ── 오선 (5줄) ──────────────────────────────────────────────────
    line_col = (255, 255, 255, 200)
    lw = max(2, int(4 * s))
    line_xs = [55, 85, 115, 145, 175]   # y positions (0~300 기준)
    for ly in line_xs:
        d.line([p(40, ly), p(260, ly)], fill=line_col, width=lw)

    # ── 음자리표 (G clef) — 단순화된 path ──────────────────────────
    # Pillow에 베지어 없으므로 폴리곤 근사
    clef_col = (255, 255, 255, 240)
    cw = max(3, int(5 * s))

    # 수직 기둥
    d.line([p(130, 40), p(130, 240)], fill=clef_col, width=cw)

    # G 루프 (타원)
    loop_r = int(38 * s)
    d.ellipse([
        (130*s - loop_r, 115*s - loop_r),
        (130*s + loop_r, 115*s + loop_r)
    ], outline=clef_col, width=cw)

    # 상단 컬 (작은 원)
    top_r = int(16 * s)
    d.ellipse([
        (130*s - top_r, 40*s - top_r),
        (130*s + top_r, 40*s + top_r)
    ], outline=clef_col, width=cw)

    # G 고리 가로선 (sol 선)
    d.line([p(130, 115), p(168, 115)], fill=clef_col, width=cw)

    # 하단 컬
    bot_r = int(22 * s)
    d.ellipse([
        (130*s - bot_r, 220*s - bot_r),
        (130*s + bot_r, 220*s + bot_r)
    ], outline=clef_col, width=cw)

    # ── 음표 2개 (오른쪽) ─────────────────────────────────────────
    note_col = (255, 255, 255, 210)
    # 첫 번째 음표 (8분음표)
    nr = int(14 * s)
    d.ellipse([(190*s - nr, 100*s - nr//2), (190*s + nr, 100*s + nr//2)],
              fill=note_col)
    d.line([p(190+nr-1, 100), p(190+nr-1, 55)], fill=note_col,
           width=max(2, int(3*s)))
    # 꺾임 (플래그)
    d.line([p(190+nr-1, 55), p(210, 72)], fill=note_col,
           width=max(2, int(3*s)))

    # 두 번째 음표
    nr2 = int(11 * s)
    d.ellipse([(220*s - nr2, 140*s - nr2//2), (220*s + nr2, 140*s + nr2//2)],
              fill=note_col)
    d.line([p(220+nr2-1, 140), p(220+nr2-1, 90)], fill=note_col,
           width=max(2, int(3*s)))
    d.line([p(220+nr2-1, 90), p(240, 108)], fill=note_col,
           width=max(2, int(3*s)))

    return img.resize((size, size), Image.LANCZOS)


# ─────────────────────────────────────────────────────────────────────────────
# 국악 아이콘 — 흰 가야금 (투명 배경, splash container가 amber)
# ─────────────────────────────────────────────────────────────────────────────
def make_gugak_icon(size: int = 300) -> Image.Image:
    img = Image.new("RGBA", (size, size), TRANSP)
    d   = ImageDraw.Draw(img)
    s   = size / 300

    def p(x, y): return (x * s, y * s)

    body_col  = (255, 255, 255, 230)
    str_col   = (255, 255, 255, 160)
    anjok_col = (255, 255, 255, 190)
    bw        = max(3, int(5 * s))

    # ── 가야금 본체 (둥근 직사각형) ───────────────────────────────
    # 세로로 긴 형태 (실제 가야금은 가로형이지만 아이콘 세로 레이아웃에 최적)
    bx1, by1 = 80*s, 30*s
    bx2, by2 = 220*s, 270*s
    br = int(18 * s)
    d.rounded_rectangle([bx1, by1, bx2, by2], radius=br,
                         outline=body_col, width=bw)

    # ── 상/하단 나비 장식 (현침) ──────────────────────────────────
    # 상단
    d.rounded_rectangle([bx1 + 14*s, by1 + 8*s,
                          bx2 - 14*s, by1 + 28*s],
                         radius=int(6*s), fill=body_col)
    # 하단
    d.rounded_rectangle([bx1 + 14*s, by2 - 28*s,
                          bx2 - 14*s, by2 - 8*s],
                         radius=int(6*s), fill=body_col)

    # ── 12현 (세로선) ─────────────────────────────────────────────
    n_strings = 12
    for i in range(n_strings):
        t = i / (n_strings - 1)
        x = bx1 + 22*s + (bx2 - bx1 - 44*s) * t
        d.line([(x, by1 + 30*s), (x, by2 - 30*s)],
               fill=str_col, width=max(1, int(2*s)))

    # ── 안족 (삼각형 받침, 12개) ─────────────────────────────────
    for i in range(n_strings):
        t = i / (n_strings - 1)
        x = bx1 + 22*s + (bx2 - bx1 - 44*s) * t
        # 짝수/홀수 행 엇갈리게
        base_y = (155 if i % 2 == 0 else 165) * s
        tri = [
            (x - 5*s, base_y + 9*s),
            (x,       base_y - 5*s),
            (x + 5*s, base_y + 9*s),
        ]
        d.polygon(tri, fill=anjok_col)

    return img.resize((size, size), Image.LANCZOS)


# ─────────────────────────────────────────────────────────────────────────────
# 앱 아이콘 (Play Store 512px + 안드로이드 미프맵 전체)
# icon_512.png가 이미 있으면 그것을 기반으로, 없으면 새로 생성
# ─────────────────────────────────────────────────────────────────────────────
def make_app_icon(size: int = 512) -> Image.Image:
    existing = ASSETS / "icon_512.png"
    if existing.exists():
        base = Image.open(existing).convert("RGBA").resize((size, size), Image.LANCZOS)
        # 기존 아이콘이 실 콘텐츠가 있으면 그대로 사용
        # (1x1 더미인 경우에만 재생성 — 이 스크립트 실행 전에 이미 대체됨)
        if base.getbbox():  # 픽셀이 있으면
            print("  ℹ  icon_512.png 기존 파일 사용")
            return base

    # ── 새로 생성: 좌(navy) + 우(amber) 분할 + "T" 레터마크 ──────
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d   = ImageDraw.Draw(img)
    s   = size / 512

    # 배경 원형 클립
    circle = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cd     = ImageDraw.Draw(circle)
    cd.ellipse([0, 0, size-1, size-1], fill=(0, 0, 0, 255))

    # 좌측 navy
    left = Image.new("RGBA", (size, size), NAVY[:3] + (255,))
    # 우측 amber
    right = Image.new("RGBA", (size, size), AMBER[:3] + (255,))

    combined = Image.new("RGBA", (size, size))
    combined.paste(left,  (0, 0))
    combined.paste(right, (size // 2, 0))
    combined.putalpha(circle.getchannel("A"))

    # 중앙 수직 구분선
    dv = ImageDraw.Draw(combined)
    lw = max(2, int(3 * s))
    dv.line([(size//2, 0), (size//2, size)],
            fill=(255, 255, 255, 100), width=lw)

    # "T" 레터마크
    try:
        # Noto Sans Bold 시도
        font = ImageFont.truetype("C:/Windows/Fonts/NotoSansKR-Bold.ttf",
                                  int(240 * s))
    except Exception:
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/malgunbd.ttf",
                                      int(240 * s))
        except Exception:
            font = ImageFont.load_default()

    text = "T"
    bbox = dv.textbbox((0, 0), text, font=font)
    tw   = bbox[2] - bbox[0]
    th   = bbox[3] - bbox[1]
    tx   = (size - tw) // 2 - bbox[0]
    ty   = (size - th) // 2 - bbox[1]

    # 그림자
    shadow = combined.copy()
    sd = ImageDraw.Draw(shadow)
    sd.text((tx + int(4*s), ty + int(4*s)), text, font=font,
             fill=(0, 0, 0, 80))
    combined = Image.alpha_composite(combined, shadow)

    # 흰 글자
    wd = ImageDraw.Draw(combined)
    wd.text((tx, ty), text, font=font, fill=(255, 255, 255, 245))

    return combined


# ─────────────────────────────────────────────────────────────────────────────
# 안드로이드 미프맵 크기
# ─────────────────────────────────────────────────────────────────────────────
MIPMAP_SIZES = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}


def generate_mipmaps(icon: Image.Image) -> None:
    print("\n[mipmap 아이콘 생성]")
    for folder, px in MIPMAP_SIZES.items():
        resized = icon.resize((px, px), Image.LANCZOS)
        # RGBA → RGB (일부 런처는 알파 미지원)
        bg = Image.new("RGB", (px, px), (255, 255, 255))
        bg.paste(resized, mask=resized.getchannel("A") if resized.mode == "RGBA" else None)
        final = bg.convert("RGBA")
        path  = ANDROID_RES / folder / "ic_launcher.png"
        save_png(final, path)


# ─────────────────────────────────────────────────────────────────────────────
# 메인
# ─────────────────────────────────────────────────────────────────────────────
def main() -> None:
    print("=== 택킷 아이콘 생성기 ===\n")

    print("[클래식 아이콘]")
    classic_icon = make_classic_icon(300)
    save_png(classic_icon, ASSETS / "icons/classic/conductor.png")

    print("\n[국악 아이콘]")
    gugak_icon = make_gugak_icon(300)
    save_png(gugak_icon, ASSETS / "icons/gugak/gayageum.png")
    # 기존 daegeum도 동일한 디자인으로 교체
    save_png(gugak_icon, ASSETS / "icons/gugak/daegeum.png")

    print("\n[앱 아이콘 512×512]")
    app_icon = make_app_icon(512)
    save_png(app_icon, ASSETS / "icon_512.png")
    # Play Store 고해상도 아이콘 (별도 저장)
    save_png(app_icon, ASSETS / "icon_playstore.png")

    print()
    generate_mipmaps(app_icon)

    print("\n✅ 모든 아이콘 생성 완료")
    print("   스플래시 화면에 자동 반영됩니다 (flutter run 시 확인)")


if __name__ == "__main__":
    main()
