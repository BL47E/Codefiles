# Codefiles

Private backup of my OpenCode configuration: skills, CLI settings, and skill
update tooling. Not for public use.

## What's in here

| Path | What it is |
| --- | --- |
| `skills/` | All global OpenCode skills (contents, not symlinks) + `.managed.txt` manifest |
| `cli.json` | OpenCode UI preferences — theme (`vesper`), session/tabs/diffs/prompt/attention settings |
| `update-skills.sh` | Refreshes global skills from upstream (anthropics/skills, mattpocock/skills) |
| `sync.sh` | Refresh this repo from the live config on this machine |
| `install.sh` | Restore this config onto a new machine |

## Deliberately excluded

- `service.json` — contains a **password**; must never be committed.
- `vendor/` — 18MB of shallow clones of public skill repos; re-fetch with
  `update-skills.sh` instead of storing them here.
- OpenCode databases / logs (`*.db`, `log/`) — runtime state, not config.

## Usage

```bash
# On this machine, after changing skills or settings:
./sync.sh && git add -A && git commit -m "update" && git push

# On a new machine:
git clone https://github.com/BL47E/Codefiles.git
cd Codefiles && ./install.sh
```

Note: on this Mac, `~/.config/opencode/skills/*` are symlinks into
`~/.t3/skills-sources/`. `install.sh` copies real files instead, which OpenCode
discovers the same way.
