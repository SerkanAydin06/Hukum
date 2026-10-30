"""Çevrilecek metinleri (msgid) toplar ve Locale/en.po kapsamını denetler.

    python tools/ceviri_cikar.py            # eksik çevirileri listeler (CI'da çıkış kodu 1)
    python tools/ceviri_cikar.py --json     # bütün msgid'leri JSON olarak yazar

Kaynaklar: betiklerdeki tr("...") çağrıları, sahnelerdeki text/placeholder/tooltip
alanları ve gösterilirken tr() ile çevrilen veri tabloları (kartlar, medeniyetler,
öğretici adımları, bina/kaynak adları).
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
PO = ROOT / "Locale/en.po"
TR_CAGRI = re.compile(r'\btr\("((?:[^"\\]|\\.)*)"\)')
LITERAL = re.compile(r'"((?:[^"\\]|\\.)*)"')
SAHNE_ALAN = re.compile(r'^(text|placeholder_text|tooltip_text) = "((?:[^"\\]|\\.)*)"', re.M | re.S)
TURKCE = re.compile(r"[A-Za-zçğıöşüÇĞİÖŞÜ]{2,}")
# Gösterilirken tr(deger) ile çevrilen veri alanları
VERI_ALANLARI = re.compile(r'"(isim|tanim|kategori|hikaye|bonus|lakap|baslik|metin)":\s*"((?:[^"\\]|\\.)*)"')
VERI_SOZLUKLERI = {
    "Scripts/Global.gd": ("BINA_ADLARI", "KAYNAK_ADLARI"),
    "Scripts/SavasYonetici.gd": ("medeniyet_savas_bonuslari",),
}
EK = [
    # Medeniyet adları ve sunucunun alıcı dilinde çevrilen hazır iletileri
    "Osmanlı", "Venedik", "Bizans", "Mısır", "Moğol", "Viking", "Müzik", "Efektler", "Birlik", "Bu birim",
    "Özel etkili kart.", "Bilinmeyen", "odun", "taş", "yiyecek", "altın", "❌ %s",
    "📨 Takas teklifin %s hükümdarına iletildi.", "⌛ Takas teklifi zaman aşımına uğradı.",
    "Takas şu an yapılamaz.", "Takas teklifini yalnızca kendi turunda, savaş yokken yapabilirsin.",
    "Önceki teklifin yanıt bekliyor.", "Geçersiz takas hedefi.", "Farklı iki kaynak seçmelisin.",
    "Miktar 1 ile 30 arasında olmalı.", "Teklif ettiğin kadar kaynağın yok.", "Suvari", "Okcu",
    "Tur %d · %s · %s", "%d rakip", "rakipsiz", "Dil · Language", "Kolay", "Orta", "Zor",
    "Bu renk veya medeniyet başka bir oyuncu tarafından seçildi.", "Maç için en az iki oyuncu gerekli.",
    "Bu maça dönülemiyor: maç bitmiş, koltuk dolu veya sunucu yeniden başlamış.",
]


GD_KACIS = {"n": "\n", "t": "\t", '"': '"', "\\": "\\", "'": "'"}


def gd_coz(s: str) -> str:
    return re.sub(r"\\(.)", lambda m: GD_KACIS.get(m.group(1), "\\" + m.group(1)), s)


def tscn_coz(s: str) -> str:
    return s.replace('\\"', '"').replace("\\\\", "\\")


def msgidler() -> list:
    kume = []
    for yol in sorted(list((ROOT / "Scripts").glob("*.gd")) + list((ROOT / "UI").glob("*.gd"))):
        metin = yol.read_text()
        kume += [gd_coz(m) for m in TR_CAGRI.findall(metin)]
        kume += [gd_coz(m[1]) for m in VERI_ALANLARI.findall(metin)]
        for sozluk in VERI_SOZLUKLERI.get(str(yol.relative_to(ROOT)), ()):
            blok = re.search(sozluk + r"\s*=\s*\{(.*?)\n?\}", metin, re.S)
            if blok:
                parcalar = LITERAL.findall(blok.group(1))
                kume += [gd_coz(p) for p in parcalar[1::2]]
    for yol in sorted(ROOT.glob("*.tscn")):
        for alan, deger in SAHNE_ALAN.findall(yol.read_text()):
            kume.append(tscn_coz(deger))
    kume += EK
    gorulen = []
    for m in kume:
        if TURKCE.search(m) and m not in gorulen:
            gorulen.append(m)
    return gorulen


def po_oku() -> dict:
    if not PO.exists():
        return {}
    sozluk = {}
    anahtar = None
    alan = None
    for satir in PO.read_text().split("\n"):
        if satir.startswith("msgid "):
            alan, anahtar = "id", json.loads(satir[6:])
        elif satir.startswith("msgstr "):
            alan = "str"
            sozluk[anahtar] = json.loads(satir[7:])
        elif satir.startswith('"') and alan == "id":
            anahtar += json.loads(satir)
        elif satir.startswith('"') and alan == "str":
            sozluk[anahtar] += json.loads(satir)
    sozluk.pop("", None)
    return sozluk


YER_TUTUCU = re.compile(r"%[-+ 0#]*\d*(?:\.\d+)?[sdfxX%]")
ETIKET = re.compile(r"\[/?[a-z_]+(?:=[^\]]*)?\]")


def denetle() -> int:
    po = po_oku()
    hatalar = []
    for m in msgidler():
        if not po.get(m):
            hatalar.append("Çeviri eksik: %r" % m[:90])
            continue
        if [y for y in YER_TUTUCU.findall(m) if y != "%%"] != [y for y in YER_TUTUCU.findall(po[m]) if y != "%%"]:
            hatalar.append("Yer tutucular farklı: %r" % m[:90])
        if sorted(ETIKET.findall(m)) != sorted(ETIKET.findall(po[m])):
            hatalar.append("BBCode etiketleri farklı: %r" % m[:90])
    for h in hatalar:
        print(h)
    print("HUKUM TRANSLATIONS: %d strings, %d problems" % (len(po), len(hatalar)))
    return 1 if hatalar else 0


if __name__ == "__main__":
    if "--json" in sys.argv:
        print(json.dumps(msgidler(), ensure_ascii=False, indent=0))
    else:
        sys.exit(denetle())
