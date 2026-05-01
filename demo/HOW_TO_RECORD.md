# Demo recording cheat sheet

Goal: 60-90 second demo video for the BUIDL submission.
Demo runner: `demo/demo.ps1` (paced for screen recording, ~75 seconds end to end).

## Quickest path on Windows

1. **Tool**: Windows + `Win + G` to open Xbox Game Bar → Capture widget → click record.
   Alternative: [ScreenToGif](https://www.screentogif.com/) (free, outputs gif/mp4 directly, very small files).
2. **Window**: open Windows Terminal, full-screen it (F11) so background apps don't show.
3. **Font**: bump Terminal font size to ≥ 18pt so text is readable in compressed video.
4. **Theme**: use a dark theme (One Half Dark / Campbell). Colored diff lines look better on dark.
5. **Record**:
   - Start screen recorder.
   - Wait 1 second of empty terminal (clean opener).
   - Run: `powershell.exe -NoProfile -File .\demo\demo.ps1`
     (or `pwsh -File .\demo\demo.ps1` if you have PowerShell 7 installed)
   - Wait until script returns to prompt (~75s).
   - Wait 1 more second.
   - Stop recording.
6. **Trim** the head/tail in the recorder's built-in editor or with `ffmpeg -ss 0:01 -to 1:18 -c copy in.mp4 out.mp4`.

## What the demo shows (to remember during the pitch)

- 0:00–0:10 — title card, v6 source snippet
- 0:10–0:35 — codemod dry-run diff (the 5 categories of change)
- 0:35–0:55 — `npm test` showing 11 fixtures pass (6 positive + 5 negative)
- 0:55–1:15 — closing pitch with the headline numbers

## Upload

1. Upload to YouTube **Unlisted** (not Private — DoraHacks reviewers can't see Private). Title: "web3py-v6-to-v7 codemod — 75s demo".
2. Copy the share link.
3. Edit your DoraHacks BUIDL (https://dorahacks.io/buidl/43597) → add the YouTube link in the Demo Video section.
4. Also paste the link near the top of `README.md` if you want it to anchor the GitHub landing.

## If the demo runner errors out

The script intentionally calls `npx codemod` which downloads on first run (~10 MB). If you've never run it before, do one warm-up run **before** hitting record:

```powershell
npm test
```

Then the recorded run will be cache-hot and not pause to install.
