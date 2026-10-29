# Kıyı admin paneli — talimat karşılığı ve teslim durumu

23 Ekim 2026. Araştırma, mimari ve uygulama ayrı değerlendirilmiştir. İlk M0–M1 yanıtı bütün kapsamı tamamlamıyordu. 2.0 sürümü aşağıdaki gerçek operasyonları ekler. İlk araştırma raporu 10 teslimatın tamamını içerir; ilgili kaynak kod ve canlı şema incelenmiştir. Ücretli dış servis varsayılmamıştır.

| Başlık | Uygulanan | Açık sınır |
|---|---|---|
| A Genel bakış | Kullanıcı/DAU/WAU/MAU, online, harita/hayalet/Premium, hediye/şarkı, şikâyet; gerçek veriye bağlı | Tahsilat/iade grafiği ödeme olmadan yok; tarihi aktiflik geriye dönük üretilmez |
| B Kullanıcı | Arama/filtre/detay, takip sayıları, role göre finans geçmişi, uyarı/askı/kalıcı kapatma/itiraz | İlk yönetici kurulmadı; gerçek MFA smoke testi bekliyor |
| C Plaka/araç | Normalize benzersiz plaka indeksi, sahiplik başvurusu, değişiklik talebi, fotoğraf gizleme, katalog fiyatı | Resmî araç sahipliği kaynağı bağlı değil; başvuru kararı insan incelemesidir |
| D Harita | Antalya bölge açık/Premium kuralları, aktif sayı, eski GPS temizliği, yaklaşık konum | Konum sahteciliği otomatik tespiti ve bağlantı gecikmesi APM hattı tamamlanmadı; yeni geometri editörü yok |
| E Premium/hayalet | Hak tarihleri, destek hakkı, görünürlük kuralları, bölge yönetimi | Gerçek mağaza abonelik/iptal/yenileme doğrulaması yok |
| F Ekonomi | Katalog/paket/kampanya, defter, gönderim/sipariş, ikinci yetkili onaylı düzeltme, atomik harcama | Ödeme, gerçek iade/ters ibraz ve otomatik dolandırıcılık skoru bağlı değil |
| G Hediye/şarkı | Hediye ekle/düzenle/kapat/görsel URL, fiyat, geçmiş/istatistik, şarkı fiyat ve link geçmişi | Canlı müzik sağlayıcısı erişimi ve geçersiz link tarama işi doğrulanmadı |
| H Fenomen | Sahibe özel rozet/fenomen/sıralama ve audit | Resmî kimlik doğrulama servisi yok |
| I Moderasyon | Şikâyet durumları, içerik/fotoğraf gizleme, yaptırım kaydı, itiraz ve farklı karar yetkilisi kuralı | Otomatik görsel sınıflandırıcı eklenmedi |
| J Duyuru | Tarihli/hedefli uygulama içi duyuru, pazarlama tercihi kontrolü, geçmiş/aktiflik | Push/e-posta/SMS teslimat hattı yok |
| K Ayarlar | Bakım, hediye/şarkı anahtarları, yardım/iletişim, katalog ve bölge erişimi; kullanıcı uygulaması tüketir | Mağaza TL tahsilat fiyatı panelden değiştirilemez; buluşmalar pasif |
| L Teknik | DB bağlantısı, bakım işinin gerçek son çalışması, kuyruk, audit, temel aktiflik | CPU, disk, fatura, PITR ve geri yükleme tatbikatı Supabase operasyonudur; tam APM yok |

## Roller ve kritik kontroller

| İşlem | Sahip | Admin | Moderatör | Finans | Destek |
|---|---|---|---|---|---|
| Kullanıcı genel detay | Evet | Evet | Evet | Evet | Evet, plaka/bakiye kısıtlı |
| Tam plaka/fotoğraf inceleme | Evet | Evet | Evet | Hayır | Hayır |
| Uyarı/süreli askı | Evet | Evet | En fazla 24 saat | Hayır | Hayır |
| Kalıcı kapatma | Evet | Hayır | Hayır | Hayır | Hayır |
| Katalog/ayar/bölge değişikliği | Evet | Evet | Hayır | Hayır | Hayır |
| Rozet/fenomen/Premium destek hakkı | Evet | Hayır | Hayır | Hayır | Hayır |
| Kredi talebi/onayı | Evet | Hayır | Hayır | Evet | Hayır |
| Şikâyet/içerik/itiraz kararı | Evet | Evet | Evet | Hayır | İtiraz yalnız okuma |
| Destek/veri talebi işleme | Evet | Evet | Destek | İade inceleme | Evet |
| Kıyı verilerini fiziksel silme | Evet | Hayır | Hayır | Hayır | Hayır |
| Yetkili verme/kaldırma | Evet, sahip rolü hariç | Hayır | Hayır | Hayır | Hayır |

Her değişiklikte gerekçe/işlem kimliği/audit. Uygun kayıtlarda sürüm kontrolü. Kritik işlemlerde yakın tarihli MFA. Kredi onayında ayrı iki kişi, kendine kredi yasağı; itirazda kendi yaptırımını değerlendirme yasağı. Anahtar veya gizli URL yetkilendirme yerine geçmez.

## Doğrulananlar

- Ana uygulama: 76 otomatik test (73 mevcut + 3 admin yapılandırma testi).
- Admin: 25 test grubu; SQL motoru + HTTP güvenliği. Son itiraz değişikliği operasyon senaryolarında yeniden doğrulandı.
- Worker ESM artifact doğrulandı. Ana uygulama framework üretim build’i alındı.
- Canlı özel operasyon tablolarında RLS açık ve authenticated SELECT kapalı.
- `ops_list` search_path uyarısı giderildi; canlı fonksiyon ayarı doğrulandı.
- `kiyi-privacy-cleanup` her 5 dakikada çalışır; gerçek son çalışma kaydı görüldü.
- Üretimde test hesabı/yaptırım/kredi hareketi oluşturulmadı. Kıyı profili ve yönetici sayısı kontrol anında sıfır.
- Tarayıcıda sentetik QA ortamıyla genel bakış, katalog, gerekçeli değişiklik/onay akışı kontrol edildi. Üretim sahibi girişinin uçtan uca testi sayılmaz.

## Çalışma sırası ve geri dönüş

1. `admin-foundation.sql`: kimlik, izin ve oturum sınırı.
2. `admin-operations.sql` + `domain-operations.sql`: özel operasyon tabloları ve mevcut RPC’lere kontrollü ekleme.
3. `operations-schedule.sql`: eski hassas verinin temizliği.
4. `operations-hardening.sql`: yardımcı search_path ve kullanıcının kendi kararlarını görmesi.
5. Admin `src/operations.js`, `worker/server.template.mjs`, `src/style.css`; ana uygulama `public/admin-operations-client.js`, `supabase-account.js`, `car-colors.js`, `featured-profiles.js`, `cloud-domain.js`, `kiyi.html`.

Önceki site sürümüne dönmek veritabanı migration’ını geri almaz. Olası geri dönüş, kaynak snapshot’larından inceleme ile yeni forward-fix migration gerektirir. Tablo silerek geri dönüş yapılmaz. Mali defter silinmez. Paylaşılan Auth/lab alanına müdahale edilmez.

## Gerçek yayına hazır sayılmadan gerekenler

1. Kullanıcının açıkça seçtiği doğrulanmış Kıyı hesabına ilk sahip yetkisi ve gerçek TOTP giriş testi.
2. Apple/Google hesapları ve gerçek ürün kimlikleriyle sunucuda makbuz/yenileme/iade akışı. Bağlanana kadar gerçek kredi satın alma kapalı kalır.
3. Push gerekiyorsa APNs/FCM kurulumu; aksi hâlde uygulama içi duyuru yeterlidir.
4. Hukuki metin/saklama/yurt dışı aktarım son incelemesi, geri yükleme tatbikatı ve gerçek cihaz mağaza kontrolleri.
5. Büyümede derin listeler için cursor, özet tablolar/önbellek, dağıtık rate limit ve yük testi. Araştırmadaki 1.000/10.000/50.000/250.000 senaryoları tahmindir; üretim benchmark’ı değildir.

Bu nedenle tüm ekranların uygulanması, bütün dış servislerin ve hukukî/operasyonel şartların tamamlanmış olması anlamına gelmez. Başarılı olmayan bir ödeme veya erişilemeyen ölçüm başarılıymış gibi gösterilmez.
