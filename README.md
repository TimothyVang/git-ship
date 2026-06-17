# git-ship

**A free, platform-agnostic `push + release` helper.** One command pushes your branch and cuts a
release — on **GitHub, GitLab, or any git host** — using plain `git` plus the platform CLI
(`gh` / `glab`) when present, or the platform's REST API over `curl` as a fallback. **No paid CI
runners, no service, no lock-in.**

```bash
# 1. install — drops git-ship on your PATH (also enables the `git ship` subcommand)
curl -fsSL https://raw.githubusercontent.com/TimothyVang/git-ship/main/install.sh | bash

# 2. ship
git ship                 # push the current branch to origin
git ship --tag v1.2.0    # push + cut a v1.2.0 release
```

> On **Windows**, use the PowerShell one-liner instead — see [Install](#install). git-ship runs as a
> `git ship` subcommand there too (Git for Windows bundles the Bash that runs it).

It's a single ~190-line Bash script with no dependencies beyond `git`, `curl`, and `python3` (the
last only for JSON-encoding release notes on the API fallback path). Drop it on your `PATH` and it
also works as a native `git` subcommand (`git ship …`).

---

## Why

Most "push and release" flows are tied to one host's CLI or burn billed CI minutes. `git-ship`:

- **Is free** — plain `git` + `gh`/`glab` if installed, else the REST API via `curl`. Never a billed runner.
- **Is platform-agnostic** — auto-detects the host from your remote URL and dispatches to GitHub,
  GitLab, or a generic host (Gitea, Codeberg, Bitbucket, self-hosted), where it pushes the branch and
  tag and leaves the tag as the portable release unit.
- **Is CI/CD-friendly** — fully non-interactive, reads credentials from environment tokens, returns
  clear exit codes. Works the same locally and inside a pipeline step.

## Install

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/TimothyVang/git-ship/main/install.sh | bash
```

Drops `git-ship` on your PATH and — if that location isn't already on PATH — adds it to your shell
profile (open a new terminal afterward), so `git ship …` works even if you've never set up a CLI
before. Flags: `bash -s -- --dir=/usr/local/bin`, `--ref=v1.0.0`, `--no-modify-path`. It's a short,
dependency-free shell script — inspect it first if you like.

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/TimothyVang/git-ship/main/install.ps1 | iex
```

To pass options or read it before running:

```powershell
iwr https://raw.githubusercontent.com/TimothyVang/git-ship/main/install.ps1 -OutFile install.ps1
powershell -ExecutionPolicy Bypass -File .\install.ps1     # add -Dir / -NoModifyPath as needed
```

git-ship is a Bash script, and **Git for Windows bundles the Bash that runs it**, so `git ship …`
works as a git subcommand from PowerShell, cmd, or Git Bash. Install
**[GitHub CLI](https://cli.github.com)** and run `gh auth login` so releases work without git-ship's
`python3` fallback (Git Bash doesn't bundle python3). On **WSL**, use the macOS/Linux one-liner.

### Manual (any OS) — it's a single file

```bash
curl -fsSL https://raw.githubusercontent.com/TimothyVang/git-ship/main/git-ship -o ~/.local/bin/git-ship
chmod +x ~/.local/bin/git-ship
```

### Vendor into a repo so CI can call it without a network fetch

```bash
cp git-ship scripts/git-ship && chmod +x scripts/git-ship
```

## Usage

```
git ship [options]

  --remote NAME       Git remote to push to (default: origin)
  --platform NAME     Force github|gitlab|gitea|generic (default: auto-detect)
  --branch NAME       Branch to push (default: current branch)
  --tag vX.Y.Z        Create + push this tag and a release for it
  --notes TEXT        Release notes text (default: auto-generate where supported)
  --notes-file FILE   Read release notes from FILE
  --create-repo       Create the remote repo if missing (github/gitlab CLI)
  --visibility V      public|private when creating a repo (default: private)
  --slug OWNER/NAME   Repo slug for --create-repo (default: <gh/glab user>/<dir>)
  --no-push           Skip the branch push (release only)
  --dry-run           Print every action, change nothing
  -h, --help          Show this help
```

### Examples

```bash
git ship                                     # push current branch to origin
git ship --tag v1.2.0                         # push + cut a v1.2.0 release
git ship --remote release --tag v1.0.0        # push + release to a dedicated 'release' remote
git ship --create-repo --visibility public    # create the repo (gh/glab), then push
git ship --dry-run --tag v1.0.0               # print every command, change nothing
```

> **Tip:** try `--dry-run` first whenever the target or visibility is uncertain. Safe defaults:
> `--create-repo` defaults to **private**; there is no force-push and no `--no-verify`.

## Tokens

Non-interactive auth reads from the environment:

| Platform | CLI used if present | REST fallback token |
|---|---|---|
| GitHub | `gh` | `GH_TOKEN` or `GITHUB_TOKEN` |
| GitLab | `glab` | `GITLAB_TOKEN` or `CI_JOB_TOKEN` |
| Generic host | — (plain `git`) | branch + tag pushed; release-object creation skipped with a note |

## Use it in CI/CD

### GitHub Action (this repo doubles as a composite action)

```yaml
# .github/workflows/release.yml
on:
  push:
    tags: ["v*"]
permissions:
  contents: write          # required: git-ship creates a release object
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }   # full history for auto-generated notes
      - uses: TimothyVang/git-ship@main   # or pin a tag once you cut one, e.g. @v1.0.0
        with:
          tag: ${{ github.ref_name }}
```

`GH_TOKEN` defaults to the workflow token; pass any other input shown in [`action.yml`](action.yml).
A full consumer example lives in [`examples/use-as-action.yml`](examples/use-as-action.yml).

### Drop-in workflow / template

If you'd rather vendor the script and run it directly, ready-made pipelines are included:

- GitHub Actions — [`.github/workflows/release-on-tag.yml`](.github/workflows/release-on-tag.yml)
- GitLab CI/CD — [`ci/gitlab-release-on-tag.yml`](ci/gitlab-release-on-tag.yml) (copy to `.gitlab-ci.yml` or `include:` it)

## How it works

1. Resolve the remote (or create it with `--create-repo`) and detect the platform from its URL.
2. Push the branch (unless `--no-push`).
3. If `--tag` is given: create the annotated tag if missing, push it, then create the release object
   via the platform CLI, or the REST API if the CLI isn't installed. On a generic host the pushed tag
   *is* the release.

## License

[MIT](LICENSE). Contributions welcome — it's one small script; keep it dependency-light and
non-interactive.
