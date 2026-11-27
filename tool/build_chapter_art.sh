#!/bin/sh
# Makes the chapter covers from the owner's originals in assets/chapters/
# (2048 px PNG, not bundled). Re-run after replacing an original.
#   assets/chapter_art/chNN.jpg                         1024 px, the app
#   ios/VerseWidgets/ListenCovers.xcassets/coverNN      400 px, iPhone widgets
#   android/.../res/drawable-nodpi/listen_cover_NN.jpg  400 px, Android widget
# macOS only (uses sips).
set -e
cd "$(dirname "$0")/.."
app=assets/chapter_art
ios=ios/VerseWidgets/ListenCovers.xcassets
android=android/app/src/main/res/drawable-nodpi
mkdir -p "$app" "$ios" "$android"
printf '{\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n' > "$ios/Contents.json"
for f in assets/chapters/ch[0-9][0-9]_*.png; do
  nn=$(basename "$f" | cut -c3-4)
  sips -Z 1024 -s format jpeg -s formatOptions 80 "$f" --out "$app/ch$nn.jpg" >/dev/null
  set="$ios/cover$nn.imageset"
  mkdir -p "$set"
  sips -Z 400 -s format jpeg -s formatOptions 75 "$f" --out "$set/cover$nn.jpg" >/dev/null
  cat > "$set/Contents.json" <<JSON
{
  "images" : [ { "filename" : "cover$nn.jpg", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
  cp "$set/cover$nn.jpg" "$android/listen_cover_$nn.jpg"
done
echo "app: $(ls $app | wc -l | xargs)  ios: $(ls -d $ios/*.imageset | wc -l | xargs)  android: $(ls $android/listen_cover_* | wc -l | xargs)"
