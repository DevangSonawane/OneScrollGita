# v2 status

All v2 stages except audio are written. Testing, debugging and the APK build
were deferred on the owner's instruction, so **`flutter test` and the
integration run have not been run yet**. `flutter analyze` passes.

| Stage | State |
| --- | --- |
| V2-0 Setup | Done: CLAUDE.md rules, packages (`flutter_local_notifications`, `timezone`, `flutter_timezone`, `share_plus` already present, plus `url_launcher` for the helpline call line), drift schema v2 + migration, v2 settings, Android permissions and boot receiver, iOS notification delegate. Migration test written, not run. |
| V2-1 Streak and popup | Done: `ReadRule`, qualifying-read detection on reader, purport and Home, `domain/streak.dart`, `read_days` / `read_day_verses`, popup (once a day, milestones, comeback), Profile streak card, reset / clear-history rules. |
| V2-2 Notifications | Done: pure scheduler (`domain/notification_plan.dart`), plugin wrapper, channels, permission on opt-in with denied state, rebuild on open / resume / settings change, cancel today's when today counts, random verse notifications, Reminders page. Real-device check pending. |
| V2-3 Message bank | Done: 564 messages, Hindi for all, validator passes. |
| V2-4 Share card | Done: 1080 x 1350 card, popup and Profile entry points, widget tests written. |
| V2-5 Keyword search | Done: FTS5 index in an isolate, aliases, Hindi, prefix, search page with recent searches and chips, Home and reader entry points, Clear search history. |
| V2-6 Summaries | Done: 18 summaries, validator, summary page, chapter-sheet button, reader "i" button. |
| V2-7 Situation search | Done: 105 themes via the FTS process, `docs/theme-review.csv`, matcher, sensitive-query care message (helpline left empty for the owner). |
| V2-8 Polish and QA | About / privacy note updated, docs written. Accessibility pass on device, performance check and the full integration run are still to do. |
| H Audio | Not started, by design. |
