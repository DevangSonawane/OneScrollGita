# Gita App: v4 PRD (Shravan audio library)

Nov 19, 2026 · owner: @Devang

Extends `docs/PRD.md`, `docs/PRD_v2.md` and `docs/PRD_v3.md`. Where it
contradicts them, **this file wins** (section 1). Scripture-text rules in
`CLAUDE.md` still apply in full.

---

## 0. Instructions for Claude Code

1. Build in the stage order of section 9, one stage per session, with tests.
2. The owner supplies the recordings after approving the UI. Until then the
   player runs on a **pretend engine** (section 5) with placeholder timings.
   Placeholder data carries `isPlaceholder: true` and must never ship.
3. Stop at the end of each stage, run `flutter analyze` and `flutter test`,
   report, and tick the boxes here.

---

## 1. Overrides to v1, v2 and v3

| Earlier rule | v4 now |
| --- | --- |
| No network calls (v1); only store billing (v3) | The app may **stream and download audio files** from the one configured audio host (section 6). Nothing else goes online: no tracking, no analytics, no accounts. |
| Do not build audio (v2 section 13) | Audio is built as specified here. |
| Three tabs (v1) | A fourth destination, **Listen**, as a separate pill beside the main nav pill (section 3). |

Still true: no backend of our own beyond static file hosting, no analytics,
scripture text never generated or edited, nothing in the scripture paywalled
except **listening** to the recordings (reading stays free).

---

## 2. Decisions (owner, 2026-11-19)

| # | Decision | Value |
| --- | --- | --- |
| 1 | Name | Shravan (श्रवण, "listening"); a **separate** paid package, not part of Sadhak |
| 2 | Pricing | **Subscriptions** (owner, 2026-11-21; replaces the earlier one-time purchase): `shravan_monthly` and `shravan_yearly`, same ids on both stores. App Store: group "Shravan", ₹499 / month and ₹1,999 / year (India base; Apple has no ₹500 or ₹2,000 price point). The old `shravan_lifetime(_ios)` ids are still recognised but no longer sold. |
| 3 | What it unlocks | **The whole Listen section** (owner, 2026-11-19): recitations, player, downloads, narrations. Free users can browse the library |
| 4 | Languages | Sanskrit recitation + **English** translation narration. Hindi later |
| 5 | Hosting | Cloudflare R2 bucket, served by a small Cloudflare Worker on a free `workers.dev` address. URL in one config constant |
| 6 | Format | AAC `.m4a`; ~96 kbps mono recitation, ~64 kbps mono narration (tuned on samples). Raw ~4.2 GB → ~350–500 MB |
| 7 | Highlight | Whole-verse highlight now; optional line timings later (manifest supports them) |
| 8 | Lock screen / iOS | System media session: Android media notification; iOS Now Playing (lock screen, Control Center, Dynamic Island). No custom Live Activity |

---

## 3. Navigation: the Listen pill

- A separate rounded glass pill to the right of the main pill (Home, Gita,
  Profile), like a "mode switch". Idle: headphones icon + "Listen".
- While audio plays the pill turns saffron and shows a moving sound wave.
- Listen is a fourth `StatefulShellBranch` (`/listen`), so it keeps its own
  state. Main pill + Listen pill = 2 glass surfaces.
- A **mini player** floats above both pills on every tab while a queue is
  loaded: chapter number tile, "Chapter 2 · 2.47", the phase ("Sanskrit" /
  "Translation"), play/pause, and a thin progress line. Tap opens the full
  player; swipe down dismisses it (stops playback).
- Scrollables add the mini player's height to their bottom inset.

---

## 4. Screens

### Library (`/listen`)

- Hero in the Sadhak style: turning mandala, "श्रवण" with a light sweep,
  "SHRAVAN" beneath, one line of purpose.
- "Continue listening" card (last chapter and verse) when there is one.
- Chapters 1–18 as cards: number (Devanagari numerals tile), title, verse
  count, total duration, progress ring, and a state button: download (with
  size), downloading (ring), downloaded (check), or lock when not owned.
- Locked chapters open the Shravan paywall (stage V4-4).

### Chapter player (`/listen/chapter/:n`, full screen)

- Artwork: the mandala with the chapter number, gently breathing while
  playing (still under reduced motion).
- Now playing: verse label and the verse text from the dataset on a solid
  card. During the Sanskrit phase the Sanskrit and transliteration are lit;
  during the translation phase the translation is shown.
- Phase chip: "Sanskrit" → "Translation".
- Scrubber over the whole chapter with a tick per verse; drag to seek.
- Controls: previous verse, play/pause, next verse; speed (0.75, 1, 1.25,
  1.5×); sleep timer (end of verse, end of chapter, 15, 30, 60 min); mode
  (Sanskrit + translation, or Sanskrit only); repeat this verse.
- Order: verse 1 recitation → translation → verse 2 … → end of chapter →
  next chapter (stops after 18). A "Verses" sheet lists the chapter's verses
  to jump to.

### Summary audio

- The summary screen (reader top-right summary icon) gets a docked player:
  play/pause, progress, speed. The paragraph being read is highlighted
  (paragraph timings from the manifest; evenly spread in the pretend engine).
- Starting it pauses the chapter queue; when it ends the bar offers "Resume
  Chapter N".
- Summaries are written content: record them only after the owner reviews
  them (`docs/review-needed.md`).

---

## 5. Audio architecture

- **Domain (pure Dart):** `AudioTrack` (verse id, phase, duration),
  `buildChapterQueue(entries, mode)`, position math across the chapter,
  `SleepTimer` rules, `AudioManifest` parsing. Fully unit tested.
- **Engine interface:** `AudioEngine` with play, pause, seek, setSpeed,
  load queue, and a state stream. Two implementations:
  - `PretendAudioEngine` (now): advances a clock through the queue using
    placeholder durations. Debug and tests only; never in release.
  - `JustAudioEngine` (V4-5): `just_audio` + `audio_service` for background
    playback and the system media session.
- **Application:** `audioControllerProvider` owns the queue, current track,
  position, mode, speed, sleep timer and the "last listened" place (saved in
  preferences).
- **Data:** `AudioCatalog` loads the manifest (placeholder asset now, the
  host's `manifest.json` later); `AudioDownloads` (V4-6) stores files on the
  phone.

### Manifest (`manifest.json`, one for the whole library)

```json
{
  "version": 1,
  "isPlaceholder": false,
  "baseUrl": "https://<worker>.workers.dev",
  "chapters": [
    {
      "chapter": 2,
      "tracks": [
        {"id": "bg-02-047", "phase": "sa", "file": "ch02/bg-02-047.sa.m4a",
         "ms": 21400, "bytes": 257000, "sha256": "…"},
        {"id": "bg-02-047", "phase": "en", "file": "ch02/bg-02-047.en.m4a",
         "ms": 18200, "bytes": 146000, "sha256": "…"}
      ],
      "summary": {"file": "ch02/summary-02.en.m4a", "ms": 95000,
                  "paragraphs": [0, 31000, 62000]}
    }
  ]
}
```

Verse ids are the dataset's ids (ranges stay one file: `bg-01-016-018`).

---

## 6. Hosting and downloads

- Files live in an R2 bucket; a Worker serves `GET /<path>` with long cache
  headers. Owner account: created 2026-11-19.
- The app streams a track the first time it plays and saves it; saved tracks
  play offline. A chapter can be downloaded whole (Wi-Fi only by default) and
  continues in the background. Profile → "Audio downloads": space used,
  delete per chapter or all.
- Locked chapters are never downloaded.
- Downloads are checked against the manifest `sha256`.
- Tooling: `tool/audio/compress.sh` (ffmpeg → m4a, loudness normalised),
  `tool/audio/build_manifest.dart`, `tool/audio/upload.sh` (wrangler), and
  `tool/audio/worker.js`.

---

## 7. Paid package

- Separate entitlement from Sadhak, same pattern: cache, restore, `canListen`
  in `domain/shravan.dart`. Screens never check products.
- Its own paywall in the Sadhak visual language, with listening benefits.
- When it lapses, downloaded files stay but locked chapters will not play.

---

## 8. Accessibility

48 dp targets, labels on every control, text scale 2.0, reduced motion (no
breathing, no wave animation), and the media session gives screen-reader and
headset control for free.

---

## 9. Staged TODO list

### Notes from V4-1 / V4-2
- Listen is **debug builds only** (`AudioConfig.enabled`) until real playback
  exists, so the pretend engine can never ship.
- Large text: the mini player's labels are capped at 1.3x (like the nav
  pills), the player's control labels at 1.5x, and at text scale above 1.3
  the player's controls scroll with the verse instead of being pinned.
- The summary player reads the English summary (English narration only).

### V4-0: Spec
- [x] This file; CLAUDE.md network rule updated.

### V4-1: Player UI on the pretend engine
- [x] Domain: tracks, queue (both modes), chapter position math, sleep timer.
- [x] `AudioEngine` interface and `PretendAudioEngine`; audio controller.
- [x] Listen pill (4th branch), mini player, library, chapter player
      (all controls), verses sheet, pretend chapter downloads.
- [x] Tests: domain, controller, widgets, text scale 2.0, reduced motion.

### V4-2: Summary audio UI
- [x] Docked summary player, paragraph highlight, pause/resume chapter.

### V4-3: Tooling (no app change)
- [x] Compression script, manifest builder, upload script, Worker
      (`tool/audio/`). Shlokas from Hugging Face JDhruv14/Bhagavad-Gita_Audio
      (Apache-2.0), matched to the app's verse ids by Sanskrit text
      (`match_hf.py`): 644 files, 4 multi-verse blocks where the editions
      split lines differently (1.26-29, 1.30-36, 4.29-31, 6.20-24). 127 MB.
      Chapter narrations (owner's files, Amala Bhakta dasa): 19 MP3s, 133 MB.
      Live at `https://one-scroll-gita-audio.officialaniketjha.workers.dev`
      (R2 bucket `one-scroll-gita`).

### V4-4: Shravan entitlement and paywall
- [x] Products (now subscriptions: `shravan_monthly`, `shravan_yearly`; see decision 2),
      cache, `canListen`, paywall variant (`PaywallOffer.shravan`, `/shravan`).
      The whole Listen section is locked behind Shravan; the library can be
      browsed. Debug: "Pretend Shravan" switch in Profile.

### V4-5: Real playback (needs recordings)
- [x] `just_audio` + `just_audio_background`, background play, media
      session, iOS background audio mode, Android foreground service.
      **Not yet heard on a real phone.** English translations: owner to send.
      Listen is on in store builds from build 9 (2026-11-21); chapter
      downloads stay hidden there until V4-6.

### V4-6: Streaming cache and downloads
- [ ] Stream-and-save, chapter downloads in the background, storage screen,
      checksum checks.

### V4-7: QA on real phones
- [ ] Screen off, Bluetooth, calls interrupting, Dynamic Island, low storage,
      airplane mode after download.
