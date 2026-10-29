# Hediye görselleri

Kullanıcının 22 Ekim 2026 tarihinde sağladığı JPEG dosyaları doğrudan kullanıldı. Yeniden üretilmedi, kırpılmadı veya arka planı değiştirilmedi.

- `gift-box.jpeg`: `BC7C1DC6-9440-4632-861A-EF3C980E5FB5.jpeg`
- `rose.jpeg`: `DE055BFA-AB99-4F40-B9AA-02FF82F99A78.jpeg`
- `tulip.jpeg`: `751183E3-BD09-4556-B506-6D99146AB5B9.jpeg`
- `evil-eye.jpeg`: `DB9A6996-E010-43DA-888B-1A83B700A1F8.jpeg`
- `bouquet.jpeg`: `736E411B-B951-4066-A2CA-405699852829.jpeg`
- `friendship.jpeg`: `8C7EC2CD-1B3D-48C1-9683-BEAA04E9C766.jpeg`
- `coffee.jpeg`: `0631DF25-B6A8-480E-91C6-336A4E64303A.jpeg`
- `tea.jpeg`: `AF42C4F8-E9EF-451D-B7ED-D1BD7D7FAF1B.jpeg`
- `ring.jpeg`: `D70373B7-00D2-4EAE-A916-E76DF9D7B677.jpeg`
- `cat.jpeg`: `8F694079-2E3A-4B34-87F4-B0C6E88735C3.jpeg`

Konum: `dist/assets/gifts/`. Limon için dosya sağlanmadığı için 🍋 simgesi kullanılır.

Kedi güncellemesi: `cat-wink.jpeg` doğrudan `980FDAEE-1DE2-462C-ADAA-F16563F7A412.jpeg` dosyasından alındı.

## Beyaz arka plan sürümü

Yerleşik image_gen aracıyla arka plan düzenlemesi. Son dosya: `/workspace/sites/kiyi/dist/assets/gifts/gifts-white.png`. Dokuz hediye 3×3 sprite olarak kullanılır.

İstem: Replace only dark navy backgrounds with pure white. Preserve original gift designs, arrange rose/tulip/evil-eye, bouquet/friendship/coffee, tea/ring/winking cat in an exact 3×3 square grid, no text, no borders, no gutters.

Pink lighter: user-supplied white-background JPEG, displayed without regeneration; 50 credits. White atlas objects use individual SVG viewports to retain complete artwork.

Gift atlas and lighter now use transparent alpha PNG cutouts (imagegen background removal), preserving object positions. Music suggestions use locally cached Apple/iTunes album artwork; search results render provider artwork and duration.

Credit coin now uses a native SVG gold relief with a ghost emblem. Gift actions use a pink present SVG. Song selection immediately records a 60-credit demo gift plus an atomic recipient notification; real cross-device delivery awaits server integration.
