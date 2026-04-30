# CLAUDE.md — instructions for Claude Code

This repo is **hartlapse**: two bash scripts that turn a git repo's history
into a captioned timelapse video. When a user runs Claude Code in a clone of
this repo, your job is to help them produce a finished video with minimum
friction.

## What this repo is (and isn't)

- It IS: `timelapse.sh` (Gource → ffmpeg) and `overlay.sh` (burn captions
  from `captions.txt`). Plus a sample `captions.txt`.
- It is NOT a generic video tool. Don't suggest editing the scripts to add
  music, transitions, intros, etc. unless the user asks — point them to
  ffmpeg directly if they do.
- The scripts are intentionally small. Resist the urge to refactor them
  into a framework.

## The default workflow you should drive

When a user says something like "make a timelapse of this repo" or just
"help me use this," walk them through these steps. Do as much as you can
without asking — only stop for input where marked **ASK**.

1. **Verify deps**. Run `gource --help >/dev/null 2>&1 && ffmpeg -version >/dev/null 2>&1 && echo OK`.
   If either is missing, point them at the install links in README.md and stop.

2. **Identify the target repo**. If the user is running Claude inside a
   clone of hartlapse itself, **ASK** which repo they want to timelapse.
   If they're running Claude inside the target repo and just have hartlapse
   alongside, use the current working directory.

3. **Pick a sensible `SECONDS_PER_DAY`**. Get the history span:
   ```bash
   git -C <repo> log --format=%ct | sort -n | awk 'NR==1{a=$1} END{print (($1-a)/86400)}'
   ```
   Aim for a final video of 30–90 seconds. Rule of thumb:
   - <30 days of history → `SECONDS_PER_DAY=3` or higher
   - 30–180 days → `SECONDS_PER_DAY=1`
   - 180+ days → `SECONDS_PER_DAY=0.3` or use `--auto-skip-seconds`
   Tell the user the value you picked and why.

4. **Render the animation**:
   ```bash
   SECONDS_PER_DAY=<value> ./timelapse.sh <repo-path> <name>.mp4
   ```
   This can take a few minutes. Don't poll — let it run, then report the
   output file size and duration.

5. **Generate caption candidates**. Pull commits the user is likely to want
   to call out:
   ```bash
   git -C <repo> log --format='%ct|%s' --no-merges
   ```
   Then **propose** a captions.txt with 5–15 entries, picking commits that
   look like milestones (first commit, version bumps, "feat:" / "release:"
   commits, large diffs, the most recent commit). Show the proposal to the
   user before writing the file. **ASK** them to edit the captions to read
   like a story rather than raw commit subjects — commit messages are for
   developers, captions are for viewers.

6. **Burn the captions** — use the SAME `SECONDS_PER_DAY`:
   ```bash
   SECONDS_PER_DAY=<value> ./overlay.sh <name>.mp4 captions.txt <name>_final.mp4
   ```

7. **Report**: final filename, size, duration, and a one-line "open it"
   hint for the user's OS (`start` on Windows, `open` on macOS, `xdg-open`
   on Linux).

## Things that commonly go wrong

- **`SECONDS_PER_DAY` mismatch between the two scripts** → captions appear
  at the wrong moments. Always pass the same value to both, or set it as
  a shell variable for the session.
- **Captions don't show up at all** → check the first timestamp in
  `captions.txt` is at or before the repo's first commit. The first line
  anchors t=0; entries earlier than that get clipped to the start.
- **ffmpeg subtitles filter fails on Windows paths** → `overlay.sh`
  already escapes the colon in `C:`, but if a user has put captions in a
  path with spaces or unusual characters, move it to a simpler path.
- **Gource shows nothing / blank video** → almost always means the path
  isn't a git repo or is a shallow clone. Run `git -C <repo> log` to
  confirm there's history to render.
- **Output mp4 won't play in some browsers** → make sure `-pix_fmt yuv420p`
  is in the ffmpeg command (it is, by default). Don't remove it.

## What to NOT do

- Don't `git init` or commit anything in the user's target repo. You're
  reading its history, not modifying it.
- Don't edit `timelapse.sh` or `overlay.sh` for one-off tuning — use env
  vars (`WIDTH`, `HEIGHT`, `FPS`, `HIDE`, `HOLD`, `FONT_SIZE`,
  `BOX_OPACITY`). The scripts are meant to stay tiny.
- Don't auto-generate captions and write the file without showing the user
  first. Captions are the part that makes the video feel personal — the
  user has to own them.
- Don't suggest adding the per-commit-screenshot reel from the original
  HART timelapse. It's intentionally out of scope here. If the user asks,
  point at the "What's not included (yet)" section of README.md.

## Quick reference

| File | Purpose |
| --- | --- |
| `timelapse.sh` | Gource → ffmpeg, produces the animation mp4 |
| `overlay.sh` | Reads `captions.txt`, builds an SRT, burns subtitles |
| `captions.txt` | One caption per line: `unix_timestamp\|caption text` |
| `README.md` | User-facing docs, env var tables |

Get a commit's timestamp:

```bash
git log --format="%ct|%s" <hash> -1
```

That's it. Be terse, drive the workflow, hand the user a finished video.
