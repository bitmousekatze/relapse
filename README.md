# relapse

Tiny two-script setup for turning a git repo's history into a captioned
timelapse video. Born out of the [HART](https://github.com/) project but
works on any git repo.

**Site:** https://bitmousekatze.github.io/relapse/

Two steps:

1. **`timelapse.sh`** — runs [Gource](https://gource.io/) over your repo and
   pipes the frames to ffmpeg, producing an mp4 of the commit history.
2. **`overlay.sh`** — burns captions onto the video at the right moments,
   driven by a plain-text `captions.txt` file you edit by hand.

If you only want the animation, stop after step 1.

## Requirements

- `gource` — [install](https://github.com/acaudwell/Gource/wiki)
- `ffmpeg` — [install](https://ffmpeg.org/download.html)
- `bash` (git-bash on Windows works fine)

Quick check:

```bash
gource --help >/dev/null && ffmpeg -version >/dev/null && echo OK
```

## Usage

```bash
git clone https://github.com/bitmousekatze/relapse.git
cd relapse
chmod +x timelapse.sh overlay.sh

# 1. render the gource animation
./timelapse.sh /path/to/your/repo my_project.mp4

# 2. (optional) edit captions.txt, then burn them in
./overlay.sh my_project.mp4 captions.txt my_project_final.mp4
```

## Captions

`captions.txt` is one caption per line:

```
unix_timestamp|caption text
```

Lines starting with `#` and blank lines are ignored. The first timestamp
anchors t=0 in the video — later captions appear at the matching moment in
the gource animation (scaled by `SECONDS_PER_DAY`).

Easy way to get a timestamp for a specific commit:

```bash
git log --format="%ct|%s" <hash> -1
```

So a typical workflow is: `git log --format='%ct|%s'` → pick the commits you
want to call out → paste them into `captions.txt` → rewrite the messages to
read like a story.

## Tuning

Both scripts read environment variables for tweaks. Defaults are sensible.

**`timelapse.sh`**

| var | default | what it does |
| --- | --- | --- |
| `WIDTH` / `HEIGHT` | `1920` / `1080` | output resolution |
| `SECONDS_PER_DAY` | `1` | how fast time moves — bump up for short histories |
| `FPS` | `60` | output framerate |
| `HIDE` | `filenames,mouse,progress` | gource `--hide` values |
| `TITLE` | repo folder name | shown in the gource header |

**`overlay.sh`**

| var | default | what it does |
| --- | --- | --- |
| `SECONDS_PER_DAY` | `1` | **must match** what `timelapse.sh` used |
| `HOLD` | `4` | seconds each caption stays on screen |
| `FONT_SIZE` | `42` | |
| `BOX_OPACITY` | `0.55` | background box opacity behind text (0 = off) |

Example — short history, fast animation, longer captions:

```bash
SECONDS_PER_DAY=3 ./timelapse.sh ~/code/myrepo out.mp4
SECONDS_PER_DAY=3 HOLD=6 ./overlay.sh out.mp4 captions.txt final.mp4
```

## Windows note

Use git-bash. The Edge/Chrome path stuff that older HART timelapse scripts
needed is **not** required here — Gource and ffmpeg are the only deps.

## What's not included (yet)

The full HART timelapse also produced per-commit page screenshots (checkout
each milestone commit → render the static site with headless Edge → splice
into the video). That part is project-specific (it assumes a static HTML
site and needs a sanitization pass for secrets), so it's left out of this
template. If there's interest, open an issue and it can land as a `shots/`
add-on.

## License

MIT — see [LICENSE](LICENSE).
