# Quran API Secret Setup (iOS)

## 1) Local secret dosyası oluştur
- `Config/Secrets.sample.xcconfig` dosyasını kopyala:
  - `Config/Secrets.xcconfig`

## 2) Değerleri doldur
- `QURAN_API_BASE_URL`
- `QURAN_API_KEY`
- `QURAN_API_KEY_HEADER`
- `QURAN_API_AUTH_PREFIX`
- `QURAN_API_FONTS_PATH`
- `QURAN_API_SURAHS_PATH`
- `QURAN_API_AYAHS_PATH`
- `QURAN_API_JUZS_PATH`

## 3) Xcode Build Settings
- App target (`Namazım`) için `Secrets.xcconfig` dosyasını Debug/Release konfigürasyonuna bağla.
- `Info.plist` alanları bu build setting değerlerini kullanacak şekilde hazırdır (`$(QURAN_API_*)`).

## 4) Güvenlik
- `Config/Secrets.xcconfig` `.gitignore` içinde; repoya gönderilmemeli.
