# HÜKÜM

Godot 4.7.2 ile geliştirilmiş, altı medeniyetli sıra tabanlı hex strateji oyunu.
2–6 kişi yerel ağ, özel WebSocket sunucusu veya PARDEX masa koduyla oynar. Tek oyunculuda
1, 3 veya 5 yapay zekâ hükümdara karşı oynanır ya da rakipsiz alıştırma seçilir. İlk kez
oynayanlar için **Öğreticiyle başla**, şehir kurmadan savaşa kadar her adımı gerçek
oyunda yaptırır; adım, oyuncu o hamleyi yapınca kendiliğinden ilerler. Zafer hedefi 50 puandır.

## Çalıştırma

1. Godot **4.7.2 stable** ile `project.godot` dosyasını içe aktar.
2. F6 yerine **F5** ile ana menüden başlat.
3. Profilinde adını ve avatarını seç. Ses ve tam ekran tercihi Ayarlar'dan değişir;
   tercihler cihazdaki `user://profil.cfg` dosyasına kaydedilir.
4. **PARDEX ONLINE:** Oyunu PARDEX kütüphanesinden aç; **Masa Kur** ile beş
   karakterli kod al veya **Kodla Katıl** ile arkadaşının masasına gir. Oturum
   bağlantısı ve iki aşamalı bilet doğrulaması otomatik yapılır.
5. **Yerel Ağ:** Bir kişi oda kursun; diğerleri sunucunun yerel IP adresini ve
   aynı portu girsin. Varsayılan port **UDP 7777**. Güvenlik duvarı buna izin vermelidir.
6. **Özel Sunucu:** Güvenilir bir HÜKÜM sunucusunun `ws://` / `wss://` adresine
   bağlan. İlk katılan oyuncu odayı yönetir. Sunucu oyuncu koltuğu işgal etmez.
7. Herkes farklı renk ve medeniyet seçip hazır olduğunda oda sahibi maçı başlatır.
   Merkezi maç, bütün oyuncuların sahnesi yüklenene kadar hamle kabul etmez.

PARDEX bağlantısı olmayan açılışlarda çevrimiçi düğmeler açıklama gösterir.
Resmî hizmetin çalışması için PARDEX sunucusunda `hukum` yönlendirmesi ve bu
sürümün HÜKÜM dedicated süreci gerekir. Bu kod değişikliği canlı hizmeti açmaz.

Özel sunucuyu Godot ile çalıştırma:

```bash
godot --headless --path . -- --hukum-server --port=8766
```

PARDEX resmî sunucusunda `PARDEX_ONLINE_SERVER_URL` ve `PARDEX_GAME_SERVER_TOKEN`
ortam değişkenleriyle `--pardex-dedicated --pardex-port=8766` kullanılır. Anahtar
istemciye verilmez. Kontrol düzleminde `HUKUM_GAME_SERVER_URL` (veya birden çok
süreç için `HUKUM_GAME_SERVER_URLS`) yapılandırılmalıdır. Kamuya açık özel sunucuda
TLS sonlandıran bir vekil üzerinden `wss://` kullan. Her dedicated süreç aynı anda
bir masa çalıştırır; resmî maç sonucu onaylandıktan sonra yeniden lobi açar.

## Oyun döngüsü

- Önce biyom seçip boş, keşfedilmemiş bir hex'e şehir kur: 10 odun + 10 taş.
- Herkes kurulumunu bitirdiğinde tur başına 3 AP alırsın. Üretim tur sonunda gelir;
  şehir merkezi her tur 1 altın üretir (savaş kartı 3 altın).
- Öncüyle komşu hex'leri keşfet; toprak kazan, kart çek, bina kur/yükselt ve ticaret yap.
- İnşa ve savaş ellerinin her biri en fazla 7 karttır. Atılan inşa kartları deste
  bittiğinde yeniden karıştırılır; savaş kartlarının ayrı atık destesi vardır.
- Savaşta kartlarını seçip kilitle, ardından kendi zarını at. Eşitlikte savunan kazanır.
- Her toprak 1; şehir dışındaki bina seviyesi 2; doğrudan vasal 5; kazanılan savaş
  +2, kaybedilen savaş −2 puan. İlk 50 puana ulaşan oyuncu kazanır.
- Maç sonucu sıralamayı gösterir ve ana menüye dönmeye izin verir.

WASD/oklar ve sağ tuşla sürükleme kamerayı hareket ettirir. Fare tekerleği
zoom yapar. **Esc / Menü–Yardım** kuralları, ayarları ve ayrılma seçeneğini açar.
Yerel ağda oda sahibi, özel sunucuda oda kurucusu lobideki **Yapay zekâ** satırından
boş koltuklara zorluk seçerek yapay zekâ ekleyip çıkarabilir; yapay zekâ boştaki
ilk renk ve medeniyeti alır ve hazırdır. Resmî PARDEX maçlarında yapay zekâ koltuğu
yoktur (sonuçlar gerçek hesaplara yazılır). Tek oyunculuda menü açıkken oyun durur.

Rakip zorluğu tek oyunculu menüsünden seçilir: **Kolay** AP'sini sık sık yarıda bırakır
ve bina geliştirmez, **Orta** dengelidir, **Zor** yiyecek ekonomisini önce kurar,
geliştirmelere öncelik verir ve liderin öncülerine saldırır. Hiçbir seviye gizli
bilgiye bakmaz veya ek kaynak almaz.

Yapay zekâ rakipler oyun sunucusunda çalışır ve yalnızca senin de görebildiğin
bilgiyi (keşfedilmiş arazi, binalar, öncüler, kaynaklar) ve kendi elini kullanır;
keşfedilmemiş araziyi, senin elini veya deste sırasını görmez. Hamlelerini oyuncu
hamleleriyle aynı kurallardan geçirir: şehir kurar, keşfeder, toprak kazanır, bina
kurup yükseltir, kart çeker ve ordusu varsa komşu öncülere saldırır.

Maç içinde Oyun Günlüğü'nün altındaki kutudan herkese mesaj yazılır (birden çok
insan oyuncu varken). Sol taraftaki **TAKAS** ile kendi turunda başka bir hükümdara
kaynak takası önerirsin; karşı taraf Kabul/Reddet ile yanıtlar, teklif 30 saniye
veya tur sonuna kadar geçerlidir. Yapay zekâ adil (aldığından az vermeyen) takası
kabul eder. Takas AP harcamaz; kaynaklar sunucuda kabul anında yeniden doğrulanır.

Çevrimiçi maçta her turun süresi 120 saniyedir; savaşta kart seçmek için 45, zar
atmak için 20 saniye vardır. Son 15 saniyede uyarı çıkar. Süre dolunca sunucu
oyuncunun yerine davranır: turu bitirir (kurulumda boş bir hex'e şehir kurar),
kart seçmeyen tarafı kartsız kilitler ve atılmayan zarı atar. Tek oyunculu
alıştırmada süre sınırı yoktur. Çevrimiçi maç menü açıkken devam eder. Bağlantısı beklenmedik şekilde kopan oyuncu, sunucu açık ve maç sürüyorsa ana
menüdeki **Maça Dön** düğmesiyle kendi koltuğuna döner (oyunu kapatıp açsa bile).
Maç başında her oyuncuya gizli bir dönüş anahtarı verilir; sunucu bu anahtarla
koltuğu açar ve oyuncuya yalnızca görmesine izin verilen durumu gönderir. Savaş
sürüyorsa dönüş savaş bitince tamamlanır. Kopukken oyuncunun sırası atlanır.
Menüden kendi isteğiyle ayrılan oyuncu geri dönemez; sunucu ayrılırsa istemciler
açıklamayla ana menüye döner. Tek oyunculu maç her turunun başında kendiliğinden
kaydedilir; menüden **Maçı kaydet** de seçilebilir. Ana menüde Tek Oyunculu ›
**Kayıtlı maça devam et** maçı kaldığı yerden sürdürür (yapay zekâ, desteler ve
harita dahil). Biten maçın kaydı silinir. Çok oyunculu maçlar kaydedilmez.
Bütün hamleler sunucu üzerinden işlenir: sunucu hamleyi elindeki tam bilgiyle
doğrular, sonra herkese aynı sırayla uygulatır. Deste sırası, rakip elleri ve
keşfedilmemiş arazi yalnızca sunucuda bulunur. Rakip kartı oynanana kadar
"gizli kart" olarak görünür. Kalan kart panelinde istemciler, desteyle rakip
ellerindeki görülmemiş kartları birlikte görür.

**Yerel Ağ'da oda sahibi aynı zamanda sunucudur** ve bu bilgileri teknik olarak
görebilir (zarı da onun makinesi atar). Oda sahibine güvenilmeyen maçlarda
Özel Sunucu veya PARDEX kullan; orada sunucu oyuncu koltuğu işgal etmez.

## Dil

Oyun Türkçe ve İngilizce oynanır. İlk açılışta sistem dili Türkçe ise Türkçe,
değilse İngilizce seçilir; Ayarlar › **Dil · Language** ile değiştirilir ve
profilde saklanır. Çeviriler `Locale/en.po` dosyasındadır (kaynak metin Türkçe).
Yeni bir metin eklerken `tr()` ile sarın ve `python tools/ceviri_cikar.py` ile
eksik çevirileri görün; proje denetimi eksik çeviride hata verir.

## Ses ve müzik

Menü ve maç için iki döngü müzik (Re hicaz; ud, ney, davul) ve inşa, keşif,
toprak, kart, savaş borusu, kılıç, zar, savaş sonucu, sıra sende, zafer ve yenilgi
efektleri vardır. Ayarlar'da ana ses, müzik ve efekt seviyesi ayrı ayrı değişir.
Bütün oyun sesleri `tools/ses_uret.py` ile sıfırdan sentezlenir; örnek veya dış
kaynak kullanılmaz. Yeniden üretmek için `python tools/ses_uret.py` (ffmpeg gerekir).

## Yapay zekâ simülasyonu

`tests/ai_sim.gd` bütün koltukları yapay zekâya oynatarak maç süresini ve
kazananları ölçer:

```bash
godot --headless --path . --script tests/ai_sim.gd -- 20 zor,orta,kolay,orta 90
```

Her maç için bir `HUKUM_SIM {...}` JSON satırı yazar.

## Sürüm paketleri

`v1.0.0` gibi bir etiket gönderildiğinde (veya Actions'tan elle) **Release builds**
iş akışı doğrulanmış Godot 4.7.2 ve resmî export şablonlarıyla Windows, Linux,
macOS (imzasız) paketlerini ve Linux dedicated server'ı üretir, Linux paketini ve
sunucuyu çalıştırarak dener, sonra taslak bir GitHub sürümüne ekler. Sürüm
numarası `project.godot` içindeki `config/version` alanıdır ve ana menünün sağ
altında görünür. Oyun içinde Nasıl Oynanır › Lisanslar ve emeği geçenler, Godot,
yazı tipi ve ses lisanslarını gösterir.

## Dışa aktarma

`export_presets.cfg` Windows, Linux, macOS ve Linux dedicated server ön ayarlarını
içerir. Godot 4.7.2 export şablonlarını kurduktan sonra:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/Hukum.exe
godot --headless --path . --export-release "Linux" build/linux/Hukum.x86_64
godot --headless --path . --export-release "macOS" build/macos/Hukum.zip
```

Paketler `fonts/OFL-*.txt` font lisanslarını ve Kenney ses lisansını içerir; testler
ve geliştirici dokümanları paketlenmez. macOS paketi imzasız ve notarize edilmemiştir.

## Doğrulama

```bash
python tests/check_project.py
python tests/run_regressions.py /path/to/godot
/path/to/godot --headless --path . --editor --import --quit
/path/to/godot --headless --path . --script tests/runtime_smoke.gd
python tests/run_scene_network.py /path/to/godot
python tests/run_central_network.py /path/to/godot
# PARDEX kaynak kodu ve server/npm ci kurulumundan sonra:
node tests/run_pardex_online.js /path/to/godot /path/to/Pardex/server
```

Son iki test gerçek sahneleri kullanır. Aynı portu kullanan başka bir HÜKÜM
sunucusuyla aynı anda çalıştırma. `runtime_smoke.gd` grafik ortamında çalıştırılırsa
`/tmp/hukum-*.png` ekran görüntülerini de oluşturur. Üç süreçli testte
`--render-spectator` seçeneği savaşın izleyici ekranını kaydeder.

Kapsam, bulgular ve doğrulanmayan koşullar: [inceleme raporu](docs/INCELEME.md).
Tek tek görsel dosyaları: [görsel envanteri](docs/visual-assets.csv).
