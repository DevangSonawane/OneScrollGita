# Sharing verses

Each verse in the reader has a share button. It shares a picture of the verse
(1080 x 1350), the translation and a link:

    https://<your-domain>/verse?id=bg-02-047

## What happens when someone opens the link

- **App installed:** the app opens on that verse.
  - With the domain verified (below), iOS and Android open the app directly.
  - Otherwise the web page opens `gitaapp://open/verse?id=…`, which the app
    handles today.
- **App not installed:** the web page (`web_link/verse.html`) sends them to the
  App Store or Play Store.

## Setup before release (placeholders to replace)

1. Host the `web_link/` folder on your domain (any static host: GitHub Pages,
   Netlify, Firebase Hosting). `verse.html` must be served at `/verse`
   (most hosts do this automatically for `.html` files).
2. Replace `gita.example.com` with your domain in:
   - `lib/core/config/app_links.dart` (`webBase`)
   - `android/app/src/main/AndroidManifest.xml` (the https intent filter)
3. In `web_link/verse.html`, set `APP_STORE` and `PLAY_STORE`.
4. Android app links: put your release signing certificate's SHA-256 in
   `web_link/.well-known/assetlinks.json`.
5. iOS universal links: put your Team ID in
   `web_link/.well-known/apple-app-site-association`, then in Xcode add the
   Associated Domains capability with `applinks:<your-domain>`.

Until then, links still open the app through the `gitaapp://` scheme from the
web page, and you can test on a simulator with:

    xcrun simctl openurl booted "gitaapp://open/verse?id=bg-02-047"
