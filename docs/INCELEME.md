# HÜKÜM — oyun akışı ve görsel inceleme

> Bu rapor 28 Ekim sürümünü kaydeder. 29 Ekim güncellemesi ana menüyü, PARDEX
> masa kodu akışını ve merkezi WebSocket sunucusunu ekledi; güncel bağlantı ve
> test bilgileri README.md içindedir.

Tarih: 28 Ekim 2026. Başlangıç sürümü: `100aef7e87711de73467c39d33377bb98ee5a429`.
Motor: Godot 4.7.2 stable. Ortam: Linux, headless testler ve X11/Mesa yazılımsal
OpenGL ile gerçek sahne çizimi. Bu rapor sınırsız hatasızlık garantisi değildir.

## İncelenen sistemler

| Alan | Kaynaklar | Kontrol ve sonuç |
|---|---|---|
| Başlangıç/profil | AnaMenu, Global, MenuIntro, Kuslar, SahneGecisleri, SesYoneticisi | Ana menü, profil/ayar kaydı, hata mesajları, sahne geçişleri; sessiz Ayarlar/Tek Oyunculu düğmeleri bağlandı. |
| Lobi/ağ | Network, LobiPaneli, MedeniyetKart, OyuncuSlot | Kimlik/renk/medeniyet/hazır kontrolleri, sohbet gönderici denetimi, çıkış ve kopmalar. Üç gerçek süreçte lobi ve maç geçişi geçti. |
| Oyun durumu | AnaOyun, AksiyonYonetici | Sıra/gönderen/AP doğrulaması, 50 puan, maç sonu. Puan hesabı tekleştirildi; sonucu tüm ağ eşlerine sunucu bildiriyor. |
| Kurulum/inşa | AksiyonInsa, AksiyonKart | Kurulum maliyeti, kart tüketimi, yükseltme, kaynak dönüşümü. Keşfedilmiş toprağın/başka öncünün üstüne şehir kurma engellendi. |
| Harita | Harita, Camera2D | Deterministik biyom, sis/görüş, komşuluk, seçim, bina/piyon çizimi. Menü ve sonuçta kamera girdisi engellendi. |
| Ekonomi/diplomasi | TurEkonomiYonetici, ArayuzDiplomasi | Üretim, vergi, medeniyet bonusları, ticaret, vasal zinciri ve puanlar; mevcut regresyon kapsamı çalıştırıldı. |
| Kartlar | DesteYonetici, KartUI | Ayrı 7 kart sınırları, deterministik karıştırma, görsel eşlemeleri; yeniden başlatma birikmesi ve inşa destesinin tükenmesi düzeltildi. |
| Savaş | AksiyonSavasTetik, SavasYonetici | Kart kilidi, kanonik kart açma, saldırı/savunma, kuşatma, zar yetkisi, sonuç, iptal. İzleyicinin iki tarafın kartlarını görmesi düzeltildi. |
| Arayüz | ArayuzYonetici, ArayuzPanel, ArayuzLog, OyunMenu | Yardım, ses/tam ekran, ayrılma, sonuç/sıralama, seçimsiz bilgi paneli; okunmayan dekoratif emoji ve başlık örtüşmeleri giderildi. |

## Yapılan düzeltmeler

1. Zafer artık ağacın tamamını dondurmuyor: sıralama ve ana menüye dönüş ekranı var;
   maç bittikten sonraki oyun işlemleri reddediliyor.
2. İnşa atıkları deste bittiğinde aynı tohumlu RNG ile yeniden karışıyor; uzun maç
   kart kalmadığı için durmuyor. Deste hazırlama önce eski durumu temizliyor.
3. Savaş açılımında hem saldıran hem savunan kartları izleyicide çiziliyor.
4. Bağlantı hatası/geçersiz IP/sunucu kopması kullanıcıya gösteriliyor; 12 saniyelik
   bağlantı zaman aşımı ve tekrar deneme var; eski lobi/tohum/peer temizleniyor.
5. Profil, avatar, ses ve tam ekran tercihi saklanıyor. Mevcut Ayarlar düğmesi çalışıyor.
6. Tek Oyunculu, açıkça rakipsiz alıştırma olarak açıklanıp çevrimdışı başlatılıyor.
7. Keşfedilmiş/kontrol edilen/öncünün bulunduğu hex'e şehir yerleştirilemiyor.
8. Ticaret Merkezi için gerçek saydam bina çizimi eklendi. Harita ve detay paneli
   aynı görseli kullanıyor; kart resmi bina yerine kullanılmıyor.
9. Menü düğmesi tur/bayrak başlığını kapatmıyor. Seçim öncesindeki örnek bina ve
   üretim yazıları temizlendi. Kilit, puan, günlük ve bonus metinleri okunur hale geldi.
10. Ana sahne yolu taze klonda UID önbelleğine bağımlı değil. CI artık asıl sahneleri
    içe aktarıp gerçek UI akışını ve üç süreçli ağı da çalıştırıyor.

## Görseller

Başlangıçtaki **248 PNG** dosyası, dosya adları korunarak hazırlanan 11 temas
paftasında tek tek görüntülendi; ana menü katmanları, düğme durumları, medeniyet
flamaları, avatarlar, hex/sis, şehirler, binalar, öncüler, kartlar, çerçeveler ve
kaynak ikonları kontrol edildi. Pafta incelemesi her resmin doğal çözünürlükte
piksel düzeyinde denetlendiği anlamına gelmez. Bina örnekleri ve yeni çizim ayrıca
büyük görüntülendi. Öncü kampı SVG'si mevcut regresyon ve harita çiziminde kontrol edildi.

Ana menü, lobi, kurulum, normal tur/kart, Ticaret Merkezi/Öncü Kampı, yardım,
ayarlar, maç sonucu ve savaş izleyicisi **1920×1080** gerçek motor çıktısında
incelendi. Yeni envanter, üretilen çizimle **249 PNG + 1 SVG** içerir.
Boyutlar, alfa kanalı, SHA-256 ve kontrol notu `visual-assets.csv` içindedir.

Yeni varlık: `Assets/Resimler/binalar/ticaret_merkezi.png`, OpenAI image generation
ile bu çalışma için üretildi, saydam PNG olarak eklendi. Üretim tarifi: mevcut
HÜKÜM binalarına uyumlu, tarihi/isometrik bir tüccar merkezi; ahşap ve taş yapı,
ikili pazar tentesi, sandıklar ve terazi, yazısız ve saydam arka plan. Çizim kaynak
boyutuyla korunur. Mevcut varlıkların mülkiyet/lisans zinciri bu teknik incelemeyle
belirlenmiş sayılmaz.

## Test kanıtı

- Dosya/sahne referans kontrolü: PASS; tüm sabit `res://` yolları taranır.
- Oyun kuralları regresyonu: **104 kontrol, 0 hata**.
- İki süreçli ENet: host/client PASS; sahte kimlik ve geçersiz işlemlerin reddi dahil.
- Asıl proje içe aktarma: parse veya kaynak yükleme hatası yok.
- Asıl UI akışı: **0 hata**; menü → lobi → kurulum → kart → yardım/ayar → zafer →
  temiz ana menü → çevrimdışı alıştırma.
- Üç gerçek sahne: host + iki client PASS; iki turun ardından kartlı savaş,
  izleyicide iki elin açılması, sunucu zarları, kaynak/el/deste/puan/bina/piyon
  durumlarının eşitliği, istemci ayrılması ve sunucu kopunca ana menüye dönüş.
- Grafik testleri yazılımsal OpenGL ve dummy ses sürücüsünde yapılmıştır;
  bu yüzden gerçek ses donanımı/işitme kalitesi doğrulanmış sayılmaz.

## Sürüm kapsamı ve açık doğrulamalar

Bu sürümün çekirdeği IP bağlantılı çok oyunculu maç ve rakipsiz alıştırmadır.
Yapay zekâ, kampanya, maç kaydet/yükle, devam eden maça yeniden bağlanma,
eşleştirme/NAT relay, mobil dokunmatik kontrol ve dağıtım paketi bulunmuyor.
Bunlar varmış gibi sunulmadı. “Tam ticari sürüm” denmeden önce:

- Windows/macOS/Linux dışa aktarımlarını hazırlayıp gerçek hedef cihazlarda çalıştır.
- Altı insanlı uzun maçlar, yavaş sahne yükleme, yüksek gecikme/paket kaybı,
  farklı DPI/en-boy oranları ve gerçek internet bağlantısını dene.
- Dengeyi insan oyunlarıyla değerlendir; 50 puanın doğal oyunla erişilebilirliği,
  maç süresi ve her medeniyetin kazanma oranını ölç.
- Dağıtılacak bütün eski görseller/fontlar/sesler için lisans kaynaklarını doğrula.

Zafer ekranı otomatik testte kontrollü puan fikstürüyle tetiklenmiştir; insanlarla
baştan sona doğal 50 puanlık bir maç oynandığı iddia edilmez. Mevcut ağ mimarisi
tüm istemcilere kanonik elleri de taşır; rekabetçi gizli-bilgi/anti-cheat garantisi
vermez. Teknik testlerin geçmesi bu ürün kapsamı ve platform doğrulamalarının
yerini tutmaz.
