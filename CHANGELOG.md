# Changelog

Bu dosya projedeki surum degisimlerini takip eder.

## [0.1.3] - 2026-02-25

### Added

- iOS tarafinda temiz klasorlenmis yeni mimari kuruldu: `Core`, `Features`, `Services`.
- 4 ana ekran moduler dosyalara ayrildi: Vakitler, Takvim, Gunun Icerigi, Ayarlar.
- iOS bildirim altyapisi eklendi:
  - Namaz hatirlatici (oncesi + vakit girdi + alarm modu)
  - Gunluk hadis bildirimi
  - Namaz oncesi mini hadis bildirimi
  - Ertele/Kapat aksiyonlu alarm akisi
- Alarm gorunumu (`AlarmRingView`) full screen akisla uygulandi.
- Notification ayarlari UI'si her vakit icin ac/kapat + sure + mod + ses secimi ile eklendi.

### Changed

- SwiftData template yapisi kaldirildi ve uygulama girisi (`Namaz_mApp`) yeni state + notification yonetimiyle guncellendi.
- Proje iPhone 17 Pro simulator hedefinde basarili build verdi.

## [0.1.2] - 2026-02-25

### Added

- SwiftUI tab tabanli yeni ekran yapisi kuruldu: Vakitler, Takvim, Gunun Icerigi, Ayarlar.
- Vakitler ekranina kalan sure, aktif vakit vurgusu, haftalik sheet ve il secimi eklendi.
- Takvim ekranina aylik vakit listesi ve Ramazan odakli liste/kalan sure karti eklendi.
- Gunun Icerigi ekranina paylas, kopyala, favori akislari eklendi.
- Ayarlar ekranina il secimi, bildirim, tema ve veri kaynagi bolumleri eklendi.

## [0.1.1] - 2026-02-25

### Added

- `scripts/release.sh` eklendi (patch/minor/major bump + commit + tag).
- README icine standart versiyonlama akis komutlari eklendi.

## [0.1.0] - 2026-02-25

### Added

- V2 kapsam ve urun cercevesi dokumantasyonu eklendi.
- `README.md` ile proje kapsami ozetlendi.
- `docs/V2_Uygulama_Kapsami.md` olusturuldu.
- `VERSION` dosyasi eklendi.
