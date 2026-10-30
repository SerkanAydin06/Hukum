"""Oyuncuya görünen Türkçe metinleri tr() ile sarar (bir kerelik göç aracı).

Veri olarak kullanılan metinler (kart/medeniyet tanımları, karşılaştırmalar,
düğüm yolları, geliştirici günlükleri) sarılmaz; onlar gösterildikleri yerde çevrilir.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
LIT = re.compile(r'"((?:[^"\\]|\\.)*)"')
TURKCE = re.compile(r"[çğıöşüÇĞİÖŞÜ]|[A-Za-z]{2,}[ .,:;!?…'·-]+[A-Za-z]|[A-ZÇĞİÖŞÜ]{3,}")
ATLA_SATIR = re.compile(
    r"push_error|push_warning|print\(|assert\(|printerr|@export|export_group|"
    r"==|!=|\bin \[|\bnot in\b|\bmatch\b|get_node|has_node|find_child|\.name ==|"
    r"^\s*const |^\s*\"[^\"]*\":|^\s*\{\"|\"(tur|isim|tanim|kategori|hikaye|bonus|lakap|baslik|metin|ad|med)\":|"
    r"\.replace\(|\.begins_with|\.ends_with|load\(|preload\(|change_scene|rpc|set_meta|get_meta|_send\(|\"type\":|"
    r"Time\.|DirAccess|FileAccess|ConfigFile|set_value|get_value|OS\.|_arg\(|close\("
)
ATLA_DOSYA = {"PardexBridge.gd", "PardexBiletDogrulayici.gd", "PardexSunucuRaporlayici.gd", "MenuIntro.gd", "Kuslar.gd"}


def sar(satir: str) -> str:
    if satir.lstrip().startswith("#") or ATLA_SATIR.search(satir):
        return satir
    cikti = []
    son = 0
    for m in LIT.finditer(satir):
        metin = m.group(1)
        once = satir[: m.start()]
        if once.rstrip().endswith(("tr(", "%", "&", "^")) or once.endswith("&") or metin.startswith(("res://", "user://", "%")) and " " not in metin:
            continue
        if not TURKCE.search(metin) or "\\n" == metin:
            continue
        # Yorum sonrası dizgileri atla
        if "#" in once and once.count('"') % 2 == 0 and once.rfind("#") > once.rfind('"'):
            continue
        cikti.append(satir[son : m.start()])
        cikti.append('tr("%s")' % metin)
        son = m.end()
    cikti.append(satir[son:])
    return "".join(cikti)


def main():
    degisen = 0
    for yol in sorted(list((ROOT / "Scripts").glob("*.gd")) + list((ROOT / "UI").glob("*.gd"))):
        if yol.name in ATLA_DOSYA:
            continue
        eski = yol.read_text()
        yeni = "\n".join(sar(s) for s in eski.split("\n"))
        if yeni != eski:
            yol.write_text(yeni)
            degisen += 1
    print("sarılan dosya:", degisen)


if __name__ == "__main__":
    sys.exit(main())
