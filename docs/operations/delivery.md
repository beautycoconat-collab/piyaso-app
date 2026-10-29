# Dış bildirim teslimatı

Kuyruk kalıcı ve özeldir. Varsayılan e-posta/push tercihleri ve global gönderim bayrakları kapalıdır. Tarihsel bildirimler topluca kuyruğa alınmaz. Uygulama içi bildirimler ayrı çalışır.

Worker yalnızca service-role kimliğiyle çağrılır; normal kullanıcı RPC/HTTP worker'ını kullanamaz. Claim 2 dakikalık lease ve SKIP LOCKED kullanır; göndermeden önce görünürlük, engel, hesap ve tercihler tekrar kontrol edilir. En çok 5 deneme; süre aşımı ve kalıcı hata ayrıdır. Provider HTTP kabulü cihaz/posta teslimatı değildir.

Sağlayıcı bağlanmadan gönderim yapılmaz. KIYI_EMAIL_DELIVERY_URL/TOKEN, KIYI_PUSH_DELIVERY_URL/TOKEN ve KIYI_DELIVERY_ALLOWED_HOSTS yalnızca sunucu secret olarak tanımlanır. HTTPS/443, tam hostname listesi ve yönlendirme yasağı uygulanır. Webhook sözleşmesi Idempotency-Key'i kalıcı olarak tekilleştirmeli; zaman aşımı sonrası tekrarlar aynı anahtarı kullanır. Leases tek başına ağ üzerinde exactly-once garantisi vermez. SMTP/Auth e-postalarının Dashboard yapılandırması bu worker'dan ayrıdır. Mevcut SMTP kimlik bilgilerine bu bağlantıdan erişim yoktur.

İşler 24 saatte sona erer; sona eren ek teslimat metaverisi 30 gün sonra temizlenir. Gelen Kutusu ve finansal defter bu temizlikte silinmez. Tamamlanan hesap silmesinde tercihler temizlenir; önceden izin verilmiş tek tamamlanma e-postası için kısa ömürlü iş korunur. Sağlayıcıya kabul edilmiş mesaj geri alınamaz.

Push cihazı canlı auth.sessions kimliğine bağlı olmalıdır; eski/session_id boş kayıtlar gönderilemez. Yerel SDK izin/cihaz kayıt entegrasyonu ve APNs/FCM erişimi bekler; tercih ekranı OS izni istemez. Güvenli kayıt yolu doğrulanmadan push bayrağını açma.

Global bayraklar delivery_email_enabled ve delivery_push_enabled ops_settings içinde false bırakılır. Gerçek teslimat testi ve sağlayıcı idempotency/mahremiyet incelemesi tamamlanmadan açılmamalı. Ücretsiz plan için 200 alıcı / 5000 toplam bekleyen iş sınırı vardır; doluluk yönetici olay kaydına düşer, uygulama içi bildirim korunur.
