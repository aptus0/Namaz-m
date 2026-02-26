# iOS Widget + Live Activity Target Setup

Bu repoda uygulama hedefi (`Namazım`) var. Widget/Live Activity UI göstermek için Xcode'da ek olarak iki extension target açılmalı:

1. `NamazimWidgets` (WidgetKit)
2. `NamazimLiveActivity` (ActivityKit + Dynamic Island)

## Neden gerekli?
`PrayerLiveActivityService` uygulama içinde activity başlatma/güncelleme yapar. Kilit ekranı ve Dynamic Island görselini gösterecek `ActivityConfiguration` ise extension target içinde olmalıdır.

## Kurulum adımları
1. Xcode > File > New > Target > Widget Extension
2. Target adını `NamazimWidgets` yapın.
3. Widget Extension içinde Lock Screen ve Home Screen widget'larını oluşturun.
4. Aynı extension'da `ActivityConfiguration(for: PrayerLiveActivityAttributes.self)` ekleyin.
5. App Group kullanacaksanız:
   - App ve Extension entitlements'a aynı `group.*` değerini ekleyin.
   - `Info.plist` içindeki `WidgetAppGroupID` alanına aynı değeri yazın.
6. `WidgetSyncService` payload anahtarını extension tarafında okuyup timeline üretin.

## Uygulama tarafında hazır olanlar
- Bildirim planlama + kategoriler
- Widget payload + `reloadAllTimelines()`
- Live Activity start/update/end servisi
- Ayarlarda canlı vakit toggle + widget yenile aksiyonu
