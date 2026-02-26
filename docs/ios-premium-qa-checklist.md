# iOS Premium QA Checklist

## 1) Theme + Background
- [ ] Ayarlar > `Premium Tema Paketi` değiştiğinde tüm ekran anında tema değiştiriyor.
- [ ] Light/Dark modda kart, metin ve vurgu renkleri okunabilir.
- [ ] Splash, ana ekran ve tab ekranlarında arka plan geçişleri takılmadan çalışıyor.

## 2) Localization
- [ ] Ana sekmelerde `tab_prayers` gibi ham anahtarlar görünmüyor.
- [ ] Varsayılan dil Türkçe açılıyor.
- [ ] Ayarlar > `Dil` alanından dil değişince ekran metinleri anında güncelleniyor.

## 3) Alternate App Icon
- [ ] Ayarlar > `Uygulama İkonu` ekranı açılıyor.
- [ ] İkon seçimi sonrası uygulama ikonu anında değişiyor.
- [ ] Uygulama yeniden açıldığında seçilen ikon korunuyor.

## 4) Widget Visibility (Home + Lock Screen)
- [ ] `NamazimWidgets` widget listesinde görünüyor.
- [ ] Home Screen için `.systemSmall` ve `.systemMedium` eklenebiliyor.
- [ ] Lock Screen için `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline` eklenebiliyor.
- [ ] Widget içinde `Bir sonraki vakit + kalan süre` doğru görünüyor.
- [ ] Tema rengi widget'a yansıyor.

## 5) Notifications + Sounds
- [ ] Bildirim izni akışı doğru çalışıyor.
- [ ] Ayarlar > Bildirimler > `Bildirim Sesi` seçimleri görünüyor.
- [ ] `Test Bildirimi Gönder` ile seçilen sesle test bildirimi geliyor.
- [ ] Namaz yaklaşma, vakit girdi ve günlük hadis bildirimleri planlanıyor.

## 6) Hadith Premium Reader
- [ ] Hadis ekranı `Günlük / Kitaplar / Favoriler` sekmelerini gösteriyor.
- [ ] Okuma modunda yazı boyutu slider'ı anında etkiliyor.
- [ ] Okuma modunda satır aralığı slider'ı anında etkiliyor.
- [ ] Favoriye ekle/çıkar işlemi kalıcı çalışıyor.

## 7) Performance
- [ ] Ana ekran ve sekmeler arası geçişte frame drop yok.
- [ ] Qibla pusula ekranında heading güncellenirken donma yok.
- [ ] Widget timeline güncellemeleri sonrası UI bloklanmıyor.

