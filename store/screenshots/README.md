# Store screenshots

1. Put raw captures in `raw/` with these names (PNG or JPG):
   `01-home`, `02-reader`, `03-feelings`, `04-purport`, `05-hindi`,
   `06-listen`, `07-trainer`, `08-library`, `09-goto`, and for the
   light/dark pair `10-themes` (dark) + `10-themes-light`.
   A clean 9:41 status bar is painted over each capture automatically
   (set `"cleanStatus": false` on a slide to turn it off).
   Android captures can go in `raw-android/`; otherwise `raw/` is used for Play too.
2. Edit captions, theme (`light`/`dark`) and layout (`bottom`/`top`) in `slides.json`.
   App Store shows all 10; Play allows 8, so slides with `"play": false`
   (08-library, 09-goto) are skipped there.
3. Run `node store/screenshots/build.mjs` (or name targets: `ios-6.9 play-phone`).

Output in `out/`:

| Folder | Size | Store slot |
| --- | --- | --- |
| ios-6.9 | 1320 x 2868 | App Store iPhone 6.9" |
| ios-6.3 | 1206 x 2622 | App Store iPhone 6.3" |
| ipad-13 | 2064 x 2752 | App Store iPad 13" (only if iPad support is turned on; the app is iPhone-only today) |
| play-phone | 1080 x 1920 | Google Play phone |
| play-tablet-7 | 1200 x 1920 | Google Play 7" tablet |
| play-tablet-10 | 1600 x 2560 | Google Play 10" tablet |

Needs Google Chrome installed (set `CHROME=` to another Chromium path). No npm packages.
