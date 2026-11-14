# Codefiles

Private backup of my OpenCode configuration: skills, CLI settings, and a
provenance manifest tracking exactly where every skill comes from. Not for
public use.

## What's in here

| Path | What it is |
| --- | --- |
| `skills/` | All global OpenCode skills (contents, not symlinks) + `.managed.txt` manifest |
| `sources.json` | **Provenance**: every skill → upstream repo, path, and pinned commit |
| `cli.json` | OpenCode UI preferences — theme (`vesper`), session/tabs/diffs/prompt/attention settings |
| `sync.sh` | Refresh this repo from the live config on this machine (regenerates `sources.json`) |
| `install.sh` | Restore this config onto a new machine |

## Where the skills come from

All skills originate from two public upstream repos, installed via T3's
symlink installer (`~/.t3/skills-sources/update-skills.js`), which pulls both
repos and symlinks every skill into `~/.config/opencode/skills/`:

| Source | Repo | Notes |
| --- | --- | --- |
| anthropics-skills | https://github.com/anthropics/skills | Anthropic's official skills |
| mattpocock-skills | https://github.com/mattpocock/skills | Matt Pocock's skills (`engineering`, `productivity`, `misc`, and experimental `in-progress` sets) |

`sources.json` records the exact commit of each repo that is snapshotted
here, plus the path of every skill inside its repo. A copy also lives at
`~/.config/opencode/skills/.sources.json` so any AI session can find the
provenance locally.

## Usage

```bash
# Update skills on this machine (pulls upstream + relinks), then snapshot:
node ~/.t3/skills-sources/update-skills.js
cd ~/Codefiles && ./sync.sh && git add -A && git commit -m "sync skills" && git push

# On a new machine:
git clone https://github.com/BL47E/Codefiles.git
cd Codefiles && ./install.sh
```

`install.sh` restores the snapshot at the pinned commits in `sources.json`.
To instead track upstream on the new machine, follow `sources.json` ->
`how_to_update`.

## Deliberately excluded

- `service.json` — contains a **password**; must never be committed.
- `vendor/` — stale clones from a previous installer; re-fetchable.
- `~/.config/opencode/update-skills.sh` — **legacy installer, do not run.**
  It predates the T3 symlink layout and would rsync `--delete` vendor copies
  *through* the skill symlinks into the clean git clones, corrupting them.
  The T3 script above is the real updater; this repo intentionally does not
  ship the legacy one.
- OpenCode databases / logs (`*.db`, `log/`) — runtime state, not config.
