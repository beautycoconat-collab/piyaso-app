# E-posta durumu
Bu dosyalar Supabase Auth şablon taslaklarıdır, Dashboard'a otomatik uygulanmadı. ConfirmationURL Supabase'in ürettiği tek kullanımlık bağlantıdır; token uydurulmaz. Şifre sıfırlama isteği istemcide hazır; bağlantı dönüşü ve parola değiştirme E2E henüz doğrulanmadı.
Varsayılan sağlayıcının alıcı/gönderim sınırları üretim SMTP yerine geçmez. SMTP kimliği, alan adı/DNS ve gerçek teslimat testi bekler. Silme/güvenlik e-postaları için sağlayıcı ve iş kuyruğu entegrasyonu henüz yok; çalışıyor denmemelidir. Mevcut uygulama içi silme talebi durumu korunur.
