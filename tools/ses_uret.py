"""HÜKÜM oyun sesleri ve müzikleri için sentezleyici.

Bütün sesler bu betikle sıfırdan üretilir (örnek veya dış kaynak kullanılmaz),
bu yüzden lisans zinciri bu depodadır. Yeniden üretmek için:

    python tools/ses_uret.py

Çıktı: Assets/Audio/Oyun/*.wav (efektler) ve Assets/Audio/Muzik/*.ogg (döngü müzik).
OGG dönüşümü için ffmpeg gerekir.
"""
import pathlib
import subprocess
import wave

import numpy as np
from scipy import signal

SR = 44100
ROOT = pathlib.Path(__file__).resolve().parents[1]
EFEKT = ROOT / "Assets/Audio/Oyun"
MUZIK = ROOT / "Assets/Audio/Muzik"
rng = np.random.default_rng(1453)


def t(sure):
    return np.arange(int(sure * SR)) / SR


def zarf(n, atak=0.005, sonum=0.2):
    x = np.arange(n) / SR
    bitis = np.minimum(1.0, (n / SR - x) / 0.03)   # kuyruğu tıklamasız kapat
    return np.minimum(1.0, x / max(atak, 1e-4)) * np.exp(-x / sonum) * bitis


def suzgec(x, tur, f, derece=2):
    b, a = signal.butter(derece, f, btype=tur, fs=SR)
    return signal.lfilter(b, a, x)


def gurultu(n):
    return rng.standard_normal(n)


def karistir(*parcalar):
    n = max(int(bas * SR) + len(p) for p, bas in parcalar)
    cikti = np.zeros(n)
    for p, bas in parcalar:
        i = int(bas * SR)
        cikti[i : i + len(p)] += p
    return cikti


def yaz_wav(ad, x, tepe=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * tepe
    son = int(0.01 * SR)
    x[-son:] *= np.linspace(1, 0, son)
    EFEKT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(EFEKT / f"{ad}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def vurmali(f, sure=0.35, egim=0.5, gurultu_payi=0.3, sonum=0.12):
    x = t(sure)
    frekans = f * (1 + egim * np.exp(-x / 0.02))
    faz = 2 * np.pi * np.cumsum(frekans) / SR
    ton = np.sin(faz) * zarf(len(x), 0.001, sonum)
    vur = suzgec(gurultu(len(x)), "low", 2500) * zarf(len(x), 0.0005, 0.015)
    return ton + gurultu_payi * vur


def can(f, sure=1.6, oranlar=(1, 2.76, 5.4, 8.93), sonum=0.6):
    x = t(sure)
    toplam = np.zeros(len(x))
    for i, oran in enumerate(oranlar):
        toplam += np.sin(2 * np.pi * f * oran * x) * np.exp(-x / (sonum / (1 + i * 0.8))) / (1 + i)
    return toplam * zarf(len(x), 0.002, 10)


def koru(f, sure, vibrato=5.0):
    x = t(sure)
    frekans = f * (1 + 0.006 * np.sin(2 * np.pi * vibrato * x))
    faz = 2 * np.pi * np.cumsum(frekans) / SR
    testere = signal.sawtooth(faz) + 0.5 * signal.sawtooth(2 * faz)
    govde = suzgec(testere, "low", 1400, 3)
    sisme = np.minimum(1, x / 0.25) * np.minimum(1, (sure - x) / 0.3)
    return govde * sisme


def efektler():
    # Kart çekme: kâğıt hışırtısı
    n = int(0.22 * SR)
    hisirti = suzgec(gurultu(n), "band", [1800, 7000]) * zarf(n, 0.01, 0.06)
    yaz_wav("kart_cek", karistir((hisirti, 0), (vurmali(900, 0.08, 0.2, 0.6, 0.02) * 0.3, 0.12)), 0.6)
    # İnşa: tahta ve taş vuruşları
    yaz_wav("insa", karistir((vurmali(190, 0.3), 0), (vurmali(150, 0.3), 0.16), (vurmali(110, 0.5, 0.8, 0.5, 0.18), 0.34)), 0.8)
    # Keşif: rüzgâr ve küçük çan
    n = int(0.9 * SR)
    ruzgar = suzgec(gurultu(n), "band", [400, 1600]) * np.sin(np.pi * np.arange(n) / n) ** 2
    yaz_wav("kesif", karistir((ruzgar * 0.6, 0), (can(1320, 0.8, sonum=0.3) * 0.5, 0.25)), 0.55)
    # Hakimiyet: bayrak dalgalanması ve davul
    n = int(0.4 * SR)
    bayrak = suzgec(gurultu(n), "band", [300, 2500]) * (0.5 + 0.5 * np.sin(2 * np.pi * 14 * np.arange(n) / SR)) * zarf(n, 0.02, 0.15)
    yaz_wav("hakimiyet", karistir((bayrak * 0.5, 0), (vurmali(80, 0.6, 0.9, 0.4, 0.25), 0.18)), 0.8)
    # Savaş başlangıcı: boru ve savaş davulu
    boru = koru(146.83, 1.2) * 0.7 + koru(220.0, 1.2) * 0.35
    yaz_wav("savas_baslat", karistir((boru, 0), (vurmali(70, 0.7, 1.0, 0.5, 0.3), 0.0), (vurmali(70, 0.7, 1.0, 0.5, 0.3), 0.45), (vurmali(65, 0.9, 1.0, 0.5, 0.35), 0.9)), 0.85)
    # Kartların açılması: kılıç çarpışması
    x = t(0.8)
    metal = sum(np.sin(2 * np.pi * f * x) * np.exp(-x / d) for f, d in [(1180, 0.35), (2734, 0.22), (4120, 0.15), (6050, 0.08)])
    carpma = suzgec(gurultu(len(x)), "high", 2000) * zarf(len(x), 0.0005, 0.03)
    yaz_wav("kilic", metal * zarf(len(x), 0.0008, 10) + 1.5 * carpma, 0.75)
    # Zar: kemik zarların tahtada yuvarlanması
    tiklar = []
    an = 0.0
    while an < 0.55:
        tiklar.append((vurmali(rng.uniform(1400, 2600), 0.05, 0.1, 0.9, 0.01) * rng.uniform(0.4, 1.0), an))
        an += rng.uniform(0.025, 0.09)
    tiklar.append((vurmali(700, 0.15, 0.3, 0.5, 0.04), an + 0.05))
    yaz_wav("zar", karistir(*tiklar), 0.7)
    # Savaş sonucu: davul ve tek darbe
    davul = [(vurmali(90, 0.2, 0.8, 0.6, 0.06) * 0.5, i * 0.06) for i in range(10)]
    yaz_wav("savas_sonu", karistir(*davul, (vurmali(60, 1.0, 1.0, 0.5, 0.4), 0.65), (can(392, 1.2) * 0.25, 0.65)), 0.85)
    # Sıra sende: tek çan
    yaz_wav("sira_sende", can(587.33, 1.6), 0.45)
    # Zafer: yükselen boru arpeji (Re majör)
    notalar = [146.83, 185.0, 220.0, 293.66]
    zafer = [(koru(f, 0.55 if i < 3 else 1.6) * 0.6, i * 0.28) for i, f in enumerate(notalar)]
    zafer += [(koru(f, 1.6) * 0.3, 0.84) for f in (220.0, 369.99)]
    zafer += [(vurmali(70, 0.8, 1.0, 0.5, 0.35), 0.84)]
    yaz_wav("zafer", karistir(*zafer), 0.85)
    # Yenilgi: inen hicaz motifi
    notalar = [293.66, 277.18, 233.08, 220.0]
    yenilgi = [(koru(f, 0.6 if i < 3 else 1.6, 4) * 0.6, i * 0.42) for i, f in enumerate(notalar)]
    yaz_wav("yenilgi", karistir(*yenilgi, (vurmali(55, 1.2, 1.0, 0.4, 0.5), 1.26)), 0.8)


# --- MÜZİK ---
HICAZ = [0, 1, 4, 5, 7, 8, 10, 12, 13, 16, 17, 19]   # Re hicaz, iki oktav


def nota(kok, derece):
    return kok * 2 ** (HICAZ[derece] / 12)


def ud(f, sure, parlaklik=0.996):
    # Karplus-Strong telli çalgı
    n = int(sure * SR)
    gecikme = int(SR / f)
    tampon = suzgec(rng.uniform(-1, 1, gecikme), "low", min(6000, f * 12))
    cikti = np.zeros(n)
    for i in range(n):
        deger = tampon[i % gecikme]
        cikti[i] = deger
        tampon[i % gecikme] = parlaklik * 0.5 * (deger + tampon[(i + 1) % gecikme])
    return cikti * zarf(n, 0.002, sure * 0.6)


def ney(f, sure):
    x = t(sure)
    frekans = f * (1 + 0.004 * np.sin(2 * np.pi * 4.8 * x) * np.minimum(1, x / 0.4))
    faz = 2 * np.pi * np.cumsum(frekans) / SR
    ton = np.sin(faz) + 0.25 * np.sin(2 * faz) + 0.08 * np.sin(3 * faz)
    nefes = suzgec(gurultu(len(x)), "band", [f * 0.8, f * 3.5]) * 0.18
    sisme = np.minimum(1, x / 0.18) * np.minimum(1, (sure - x) / 0.25)
    return (ton + nefes) * sisme


def bordun(kok, sure):
    x = t(sure)
    ses = np.zeros(len(x))
    for f, g in [(kok / 2, 1.0), (kok * 3 / 4, 0.6), (kok, 0.35)]:
        ses += g * signal.sawtooth(2 * np.pi * f * x + rng.uniform(0, 6))
    return suzgec(ses, "low", 500, 2) * (0.85 + 0.15 * np.sin(2 * np.pi * x / 8))


def melodi(sure, nota_sure, sentez, kok, yogunluk, tohum):
    yerel = np.random.default_rng(tohum)
    cikti = np.zeros(int(sure * SR))
    derece = 4
    an = 1.0
    while an < sure - 3.0:
        cumle = yerel.integers(3, 7)
        for _ in range(cumle):
            if an >= sure - 3.0:
                break
            derece = int(np.clip(derece + yerel.choice([-2, -1, -1, 1, 1, 2]), 0, len(HICAZ) - 1))
            uzunluk = nota_sure * yerel.choice([1, 1, 2, 2, 3])
            ses = sentez(nota(kok, derece), uzunluk * 1.4) * 0.5
            i = int(an * SR)
            cikti[i : i + len(ses)] += ses[: len(cikti) - i]
            an += uzunluk
        an += nota_sure * yerel.integers(2, 6) / yogunluk
    return cikti


def davul_deseni(sure, bpm):
    vurus = 60 / bpm
    cikti = np.zeros(int(sure * SR))
    dum = vurmali(70, 0.5, 0.9, 0.3, 0.2)
    tek = vurmali(320, 0.15, 0.2, 0.9, 0.04) * 0.45
    an = 0.0
    while an < sure - 1:
        for parca, kaydirma in [(dum, 0), (tek, 1.5), (dum * 0.7, 2.0), (tek, 3.0)]:
            i = int((an + kaydirma * vurus) * SR)
            cikti[i : i + len(parca)] += parca[: len(cikti) - i]
        an += 4 * vurus
    return cikti


def dongu_yaz(ad, x):
    # Uçları birbirine karıştırarak dikişsiz döngü
    gecis = int(2.0 * SR)
    x[:gecis] = x[:gecis] * np.linspace(0, 1, gecis) + x[-gecis:] * np.linspace(1, 0, gecis)
    x = x[:-gecis]
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.7
    MUZIK.mkdir(parents=True, exist_ok=True)
    gecici = MUZIK / f"{ad}.tmp.wav"
    with wave.open(str(gecici), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(gecici), "-c:a", "libvorbis", "-q:a", "3", str(MUZIK / f"{ad}.ogg")], check=True)
    gecici.unlink()


def muzikler():
    kok = 293.66
    sure = 74.0
    menu = bordun(kok / 2, sure) * 0.35 + melodi(sure, 0.9, ney, kok, 0.6, 7) * 0.55
    dongu_yaz("menu_muzigi", menu)
    oyun = bordun(kok / 2, sure) * 0.25 + melodi(sure, 0.36, ud, kok, 1.0, 11) * 0.7 + davul_deseni(sure, 84) * 0.35
    dongu_yaz("oyun_muzigi", oyun)


if __name__ == "__main__":
    efektler()
    muzikler()
    print("HUKUM sesleri üretildi:", sorted(p.name for p in EFEKT.glob("*.wav")), sorted(p.name for p in MUZIK.glob("*.ogg")))
