# Harita, hazır istatistikler ve kota uyarıları

2026-10-23. Bu sürüm yalnız kullanıcının onayladığı üç maliyet önlemini içerir.

## Harita
Sunucu, görünen dikdörtgeni GiST point indeksiyle süzer. Ardından 90 saniyelik tazelik, etkin bölge, paylaşım, hesap durumu, engelleme ve onay listesi koşullarını uygular. Eşik bu koşulları geçen araç sayısıdır; toplam üyelik sayısı değildir. Premium / hayalet kimlik kuralları ve yaklaşık konum aynen korunur. Yeni İzmir geometrisi eklenmedi.

- 200 veya daha az: tamamı.
- 200'den fazla ve zoom <13: en fazla 100.
- Zoom 13–15: en fazla 200.
- Zoom 15–17: en fazla 400; daha az varsa tamamı.
- Zoom >=17: yalnız görünür alandaki tüm araçlar, 200 kayıtlık UUID imleç sayfalamasıyla.

Örneklemenin ilk yarısı boş olmayan görünür bölgelere sıra sıra eşit dağıtılır. Kalan yarı, seçilmemiş araç sayısına orantılı ve en büyük kalan yöntemiyle dağıtılır. Boş/küçük bölge payları boşa gitmez. Bölge içindeki seçim sabit hash sırasındadır; rastgele titreşim yaratılmaz. Anonim hayalet anahtarı kullanıcıya ve güne özeldir. Harita hareketinde 250 ms gecikmeyle yeni sorgu yapılır; eski isteklerin yanıtları sürüm kontrolüyle atılır. Leaflet ve MapLibre dinlenir. Mevcut yaklaşık konum gösterimi hassasiyeti değişmez.

## İstatistikler
Özetler pg_cron ile 5 dakikada bir ve ilk kurulumda hazırlanır. Dashboard ve analitik sayfaları yalnız özel önbelleği okur. Kartlarda veri zamanı, 10 dakikadan eskiyse gecikme uyarısı vardır. Hediye/şarkı günlük toplamları aynı transaction içindeki trigger ile güncellenir; rollback toplamı da geri alır. İlk geçmiş taraması migration sırasında bir defadır. DAU/WAU/MAU mevcut aktivite kaydından hesaplanır; geçmişe veri uydurulmaz. Gelir entegrasyonu yoksa gelir üretilmez.

## Kota ve uyarılar
Uyarı eşiği %75. Resmî Free kota kaynağı: https://supabase.com/pricing ve https://supabase.com/docs/guides/platform/billing-on-supabase . Kotalar zamanla değişebilir; bu sürüm Free varsayımları kullanır. Ücretli plana geçildiğinde kota konfigürasyonu da güncellenmelidir.

| Ölçüm | Kota | %75 |
|---|---:|---:|
| Proje veritabanı | 500 MB | 375 MB |
| Organizasyon Storage | 1 GB | 750 MB |
| Aylık uncached egress | 5 GB | 3,75 GB |
| Aylık cached egress | 5 GB | 3,75 GB |
| Organizasyon Auth MAU | 50.000 | 37.500 |
| Aylık Realtime mesajı | 2.000.000 | 1.500.000 |
| Tepe Realtime bağlantısı | 200 | 150 |

Ondalık byte eşikleri erken uyarı olarak kullanılır; faturalamada Supabase paneli esastır. Veritabanı ölçümü paylaşılan projenin tüm şemalarını kapsar. Storage metadata toplamı bu projeyi kapsar: organizasyondaki başka projeleri kapsamaz, alt sınır olarak etiketlidir. Eksik dosya boyutunda sıfır değil bilinmiyor gösterilir. Silinmiş/metadata dışında kalan fiziksel nesneler için sağlayıcı ölçümü esastır.

Egress, organizasyon MAU ve Realtime gerçek kullanım kaynağı henüz bağlı DEĞİLDİR. Supabase MCP bu kullanım verisini sağlamıyor; mevcut uygulama servis kimliklerini okumak veya tarayıcıya taşımak bu eksikliği çözmek için kullanılmadı. Güvenilir sağlayıcı toplayıcısına özel `ops_import_provider_usage` fonksiyonu hazırdır; authenticated, anon ve service_role çalıştıramaz. Dış toplayıcı, en az saatlik güncel ve doğru fatura dönemli resmî ölçümleri güvenli sunucu üzerinden aktarmalıdır. Kıyı DAU'su faturalandırılan Auth MAU yerine kullanılmaz.

Ölçüm bir saatten eskiyse veya dönemi geçmişse bilinmiyor gösterilir. %75 dahil uyarı açılır, aynı uyarı çoğaltılmaz, doğrulanmış normal kullanımda çözülür; ölçüm kesilmesi eski uyarıyı çözmez. Bildirim admin panelindedir; e-posta/SMS/push gönderimi ve harcama engeli eklenmemiştir. Erişim Super Admin, Admin ve Finans rollerindedir. Hassas bireysel konumlar eklenmedi.

## Değişiklikler ve doğrulama
- `supabase/viewport-map.sql`: indeks, private harita sorgusu, mevcut command içinde map yönlendirmesi.
- `supabase/cached-statistics-and-usage.sql`: özetler, günlük toplamlar, kullanım ölçümleri, uyarılar, özel fonksiyonlar.
- `supabase/cached-statistics-dispatcher.sql`: mevcut RBAC/MFA admin RPC'sinde cache okuma.
- `supabase/cached-statistics-schedule.sql`: ilk hesaplama ve beş dakikalık görev.
- Admin `src/operations.js`: kota sayfası ve özet zamanları; BFF hata çevirisi.
- Ana uygulama `public/cloud-domain.js`: viewport ve imleçler, eski yanıt koruması; `public/izmir-zones.js`: Tüm bölgeler seçimi.
- `tests/scaling.test.mjs`: gerçek PostgreSQL uyumlu PGlite üzerinde sınırlar, örnekleme, sayfalama, kota, cache ve yetki testleri.
- Ana uygulama `tests/map-viewport-client.test.mjs`: sayfalama ve pan/yanıt yarışı.

Gerçek cihazda 3D harita gezinmesi ve yoğun trafik yük testi bu otomatik testlerin kapsamı dışındadır. Canlı üretime sahte kullanıcı/araç eklenmez.
