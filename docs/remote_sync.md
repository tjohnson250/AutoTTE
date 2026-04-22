# Updating a remote clone after the submodule migration

This doc is for a second machine (e.g. your secure MSSQL host) whose
local checkout predates the GitHub → GitHub+GitLab submodule migration.
After the one-time upgrade here, use `docs/workflow.md` for day-to-day
updates.

## 1. Check for uncommitted local changes first

```bash
cd /path/to/AutoTTE
git status
```

If `git status` shows anything modified or staged that you want to keep,
commit or stash it before proceeding. Untracked working-tree files
(e.g. test output, `.rds` checkpoints under `results/`) are safe — `git
pull` won't touch them.

## 2. Fetch and inspect what's coming

```bash
git fetch origin
git log --oneline HEAD..origin/master    # commits you'll receive
git diff --stat HEAD..origin/master      # file-level summary
```

In the diff summary, expect to see these **deleted**:

- `databases/secure_pcornet_cdw.yaml`
- `databases/schemas/secure_pcornet_cdw_schema.txt`
- `databases/schemas/secure_pcornet_cdw_mpi_schema.txt`
- `databases/profiles/secure_pcornet_cdw_profile.md`
- `databases/conventions/secure_pcornet_cdw_conventions.md`

And these **added**:

- `.gitmodules`
- `databases/local` (as a submodule gitlink, not a directory tree)

That's the migration.

## 3. Pull

```bash
git pull
```

After this, the five institution-specific files are gone from your
working tree, `.gitmodules` exists, and `databases/local/` is an empty
directory (gitlink placeholder).

## 4. Initialize the submodule (first-time clone from GitLab)

```bash
git submodule update --init --recursive
```

This clones `git@gitpapl1.uth.tmc.edu:big-arc/research/autotte-local.git`
into `databases/local/` and checks out the SHA recorded in the parent
repo. Your existing SSH setup on the secure machine (Git Bash with
`~/.ssh/id_rsa` registered on GitLab) already authenticates.

If it fails with a GitLab auth error, diagnose with:

```bash
ssh -T git@gitpapl1.uth.tmc.edu      # should say: Welcome to GitLab, @<user>!
```

## 5. Verify

```bash
ls databases/local
#   expect: README.md  conventions/  profiles/  schemas/  secure_pcornet_cdw.yaml

git submodule status
#   expect: " 5ee5bced... databases/local (heads/main)"
```

And a discovery check through Python:

```bash
python -m tools.db_triage show secure_pcornet_cdw --project-root .
```

All three paths (`schema_dump`, `data_profile`, `conventions`) should
resolve under `databases/local/...` and show `[present]`.

## 6. Optional one-time convenience setting

```bash
git config submodule.recurse true
```

Now plain `git pull` auto-updates both the parent repo and the submodule
on subsequent pulls.

## Notes for the secure-machine workflow

- **Rendering `CDW_DB_Profiler.qmd`** — the default `db_config` param
  now points at `databases/local/secure_pcornet_cdw.yaml`. Update any
  wrapper/bookmark that referenced the old path.
- **R analysis scripts** — unaffected; they read schema/profile via the
  YAML and the YAML now points into `databases/local/`.
- **`run.sh` preflight** — a new preflight at the top of `run.sh`
  requires `python` to have `mcp httpx lxml pyyaml`. If you only run R
  scripts on this host (not the pipeline), this doesn't matter. If you
  ever invoke `run.sh` here, install the deps with
  `python -m pip install mcp httpx lxml pyyaml`.

## Ongoing workflow

Once the migration is applied, use `docs/workflow.md` for the day-to-day
cheat sheet covering public-only changes, private-only changes (with the
two-commit gitlink bump), pulling, and common mistakes.
