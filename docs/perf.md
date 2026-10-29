# Performance notes

## v2 bundled content sizes

| File | Size | Budget |
| --- | --- | --- |
| `assets/messages/messages.json` (564 messages, EN + HI) | 187,885 bytes (183 KB) | well under 300 KB. Larger than the ~100-150 KB estimate because Devanagari is 3 bytes per character in UTF-8. |
| `assets/summaries/summaries.json` (18, EN + HI) | 88,496 bytes | — |
| `assets/search/themes.json` (105 themes) | 43,741 bytes | — |
| `assets/search/aliases.json` | 1,950 bytes | — |

## v2 runtime notes (not yet measured on a device)

- Search index: built once in an isolate (`compute`) into its own SQLite file, rebuilt only when the dataset version changes. Queries are FTS5 with bm25 and a 250 ms typing debounce; result lists are lazy slivers.
- Schedule rebuild: cancels and schedules at most 28 notifications; runs serialised so open/resume bursts do not overlap.
- The streak popup is a single positioned card above the routes; it takes no pointer events outside itself, so swipes are not delayed.
