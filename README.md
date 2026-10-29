# HÜKÜM

Godot 4.7.2 ile geliştirilmiş, altı medeniyetli sıra tabanlı hex strateji oyunu.
2–6 kişi yerel ağ, özel WebSocket sunucusu veya PARDEX masa koduyla oynar. Tek oyunculu seçenek, rakipsiz bir
alıştırma haritasıdır. Zafer hedefi 50 puandır.

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
- Herkes kurulumunu bitirdiğinde tur başına 3 AP alırsın. Üretim tur sonunda gelir.
- Öncüyle komşu hex'leri keşfet; toprak kazan, kart çek, bina kur/yükselt ve ticaret yap.
- İnşa ve savaş ellerinin her biri en fazla 7 karttır. Atılan inşa kartları deste
  bittiğinde yeniden karıştırılır; savaş kartlarının ayrı atık destesi vardır.
- Savaşta kartlarını seçip kilitle, ardından kendi zarını at. Eşitlikte savunan kazanır.
- Her toprak 1; şehir dışındaki bina seviyesi 2; doğrudan vasal 5; kazanılan savaş
  +2, kaybedilen savaş −2 puan. İlk 50 puana ulaşan oyuncu kazanır.
- Maç sonucu sıralamayı gösterir ve ana menüye dönmeye izin verir.

WASD/oklar ve sağ tuşla sürükleme kamerayı hareket ettirir. Fare tekerleği
zoom yapar. **Esc / Menü–Yardım** kuralları, ayarları ve ayrılma seçeneğini açar.
Çevrimiçi maç menü açıkken devam eder. Ayrılan oyuncu maçına yeniden katılamaz;
sunucu ayrılırsa istemciler açıklamayla ana menüye döner. Maç kaydı yoktur.
Deste sırası yalnızca sunucuda tutulur; kartları sunucu dağıtır ve istemciler
kalan kartların sırasını hesaplayamaz. Oyuncu elleri hâlâ bütün eşlere gider,
bu yüzden rekabetçi gizli el garantisi yoktur.

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
