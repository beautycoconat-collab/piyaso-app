# Kıyı yedekleme ve geri yükleme

Durum: otomatik yedek kurulmuş değildir. Bu ortamda pg_dump/psql/Docker yok; izole geri yükleme testi yapılmadı. Git geçmişi kullanıcı verisi ve Storage yedeği değildir.

1. Proje sahibi erişimiyle Supabase CLI veya pg_dump kullanarak yalnızca kiyi tabloları, kiyi_private fonksiyonları ve migration geçmişi için şifreli mantıksal yedek al. Auth paylaşımlıdır; başka uygulamaların kullanıcılarını Kıyı geri yüklemesiyle değiştirme.
2. Storage dosyalarını ayrıca Storage API ile envanterle; veritabanı yedeği dosya baytlarını içermez. Yedeği özel, şifreli ve erişim kaydı olan yerde tut. Kaynak depoya/CI günlüklerine koyma.
3. PostgreSQL/PostGIS sürümü eşleşen izole test projesinde şema, veri, sequence ve kısıtları geri yükle. Üretim URL'sini hedef olarak kabul etme. Dosya nesnelerini ayrıca geri koy.
4. Tablo sayımları, özelleştirme/araç ilişkileri, kredi defteri toplamları, RLS/grant ve iki hesap izolasyon testlerini çalıştır. Sonuç ve kurtarma süresini kaydet.
5. Silinmiş hesapların yedekten tekrar canlanmasını engellemek için erasure/tombstone kayıtlarını uzlaştır. Saklama süresini işletmeci belirlemeli.

Gerçek planın yedekleme imkanları Dashboard üzerinden doğrulanmalıdır; ücretli plan açılmadı. Otomatik zamanlama ancak hedef, saklama, şifreleme anahtarı ve geri yükleme testi doğrulanınca etkinleştirilmeli.
