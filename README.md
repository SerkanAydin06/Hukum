# HÜKÜM

Godot 4.7.2 ile geliştirilmiş, altı medeniyetli sıra tabanlı hex strateji oyunu.
2–6 kişi yerel ağda/IP bağlantısıyla oynar. Tek oyunculu seçenek, rakipsiz bir
alıştırma haritasıdır. Zafer hedefi 50 puandır.

## Çalıştırma

1. Godot **4.7.2 stable** ile `project.godot` dosyasını içe aktar.
2. F6 yerine **F5** ile ana menüden başlat.
3. Profilinde adını ve avatarını seç. Ses ve tam ekran tercihi Ayarlar'dan değişir;
   tercihler cihazdaki `user://profil.cfg` dosyasına kaydedilir.
4. Alıştırma için **Tek Oyunculu** düğmesine bas. Çok oyunculu için bir kişi oda
   kursun; diğerleri sunucunun IP adresini yazıp bağlansın. Herkes farklı renk ve
   medeniyet seçip hazır olduğunda sunucu oyunu başlatır.

UDP **7777** bağlantısına izin verilmelidir. İnternetten doğrudan bağlantı,
sunucunun erişilebilir IP adresi ve ağ yönlendirmesini gerektirir; otomatik
oda bulma, NAT geçişi veya adanmış sunucu hizmeti yoktur.

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

## Doğrulama

```bash
python tests/check_project.py
python tests/run_regressions.py /path/to/godot
/path/to/godot --headless --path . --editor --import --quit
/path/to/godot --headless --path . --script tests/runtime_smoke.gd
python tests/run_scene_network.py /path/to/godot
```

Son iki test gerçek sahneleri kullanır. Aynı portu kullanan başka bir HÜKÜM
sunucusuyla aynı anda çalıştırma. `runtime_smoke.gd` grafik ortamında çalıştırılırsa
`/tmp/hukum-*.png` ekran görüntülerini de oluşturur. Üç süreçli testte
`--render-spectator` seçeneği savaşın izleyici ekranını kaydeder.

Kapsam, bulgular ve doğrulanmayan koşullar: [inceleme raporu](docs/INCELEME.md).
Tek tek görsel dosyaları: [görsel envanteri](docs/visual-assets.csv).
