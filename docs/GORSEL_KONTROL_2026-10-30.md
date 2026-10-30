# 30 Ekim 2026 görsel kontrolü

Başlangıç: `a3eb845cfc1bc654e02b923f3999d30880b0ec43`.
Godot 4.7.2, 1920 × 1080, X11/Mesa Compatibility renderer.

- Ana menü, sekiz profil seçeneği ve büyük profil önizlemesi, lobi,
  altı medeniyet görünümü, harita/kart alanı, savaş ilanı/savaş penceresi,
  ticaret/takas/inşa onayları, yardım, ayarlar ve sonuç ekranları incelendi.
- Portreler tam boy çizilip üstlerine çerçeve konduğu için dış saydam alanlarda
  resim görünüyordu. `PortraitMask.gdshader` resmi çerçevenin iç açıklığında
  gösterir. `PortraitBorder.gd` bu maskeyi bütün portrelerde ortak uygular.
- Kare olmayan hükümdar görselleri ve portre alanları oranı korunarak merkezden
  kırpılır. Çerçeve kare kalır; yeniden boyutlandırma maskeyi günceller.
- Savaş ilanındaki iki TextureRect artık resmin doğal 1024 px boyutunu minimum
  pencere boyutu yapmaz. 200 px portreler pencere içinde kalır.
- Hover ve seçili çerçeveleri korunur; dekorasyon fare girişini engellemez.
- 80, 128, 200 px kare ve 240 × 120 dikdörtgen alanlarda hem TextureRect hem
  TextureButton ile piksel testi yapıldı. Parlak test resmi dış köşelere taşmaz,
  iç açıklıkta görünür; yeniden boyutlandırma da test edilir.
- 49 kart/bina/profil varlığı paftada incelendi. Oyunda kullanılan 29 farklı kart
  türünün dinamik görsel eşlemeleri dosyalarla karşılaştırıldı; eksik yok.
- Altı medeniyet arması, flamalar, kaynak/eylem ikonları ve yeni kamp çizimleri
  mevcut. Bu kontrolde yeni illüstrasyon gerektiren bir eksik bulunmadı.

Testler: proje/535 çeviri kontrolü, 135 kural kontrolü ve ENet; gerçek sahne
akışı ve ölçek/piksel kontrolleri. Güncel otomatik sonuçlar PR kontrolündedir.
Gerçek cihaz DPI ölçümleri ve insanlarla uzun maç testi bu görsel incelemenin
kapsamında değildir.
