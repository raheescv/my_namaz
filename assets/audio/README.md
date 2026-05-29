# Adhan audio files

Place adhan MP3 files in this folder. The app references them by filename in
`lib/services/adhan_player_service.dart` (see `availableAdhans`).

Recommended sources for royalty-free adhan recordings:
- https://archive.org/details/azan_3 — Mecca / Madinah classic
- https://islamcan.com/adhan/ — many high-quality recitations

Add files like:
- `adhan_makkah.mp3`
- `adhan_madinah.mp3`
- `adhan_mishary.mp3`

Then update the `availableAdhans` constant in
`lib/services/adhan_player_service.dart` to surface them in the picker.

> **Note**: keep file sizes small (<2 MB) — they're bundled into the app
> binary. For iOS background playback as a notification sound, files must
> be <30s; for in-app playback during foreground the full adhan is fine.
