# Audio vs app translation check

Updated 2026-11-24. App text: vedabase.io import (datasetVersion vedabase-io-2026-11-23).

- 657 of 657 entries have an English recording (`~/versescroll_audio/out/chNN/<id>.en.m4a`).
- 638 match the app text word for word; 19 differ only in punctuation or capitals.
- 0 differ in wording.

## How it was checked

- 630 original clips: the owner's verification reports confirm each clip reads its
  .txt (speech recognition); each .txt was compared with the app text.
- 27 re-voiced clips (1.1 plus the 26 listed in docs/re-voice-list.txt), recorded
  from the app text in one narration on 2026-11-23 and split with
  tool/audio/split_by_text.py and tool/audio/check_starts.py. Every cut was
  confirmed by matching the start and end of the earlier recording of the same
  verse (same voice). Two cuts had almost no pause (4.34/5.8-9 at 155.43 s,
  8.9/8.11 at 318.54 s) and were placed at the digital silence there.
- Not covered: whether the narrator spoke every word correctly in the 27
  re-voiced clips. No speech recognition ran on them; listen once.
- Replaced clips are kept in `~/versescroll_audio/translations_src/_replaced/`.
