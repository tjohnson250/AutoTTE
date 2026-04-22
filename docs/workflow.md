# Working with the public (GitHub) + private (GitLab) split

The AutoTTE public repo lives on GitHub. Institution-specific DB configs
(YAMLs, schema dumps, profiles, conventions) live in a private GitLab
companion repo, mounted as a git submodule at `databases/local/`. This
doc covers the day-to-day workflow for keeping both in sync without
leaking private content into the public repo.

## Which repo does a change belong in?

| Change type | Repo |
|---|---|
| Code, docs, tests, generic configs | **GitHub** (public `AutoTTE`) |
| `databases/local/*.yaml`, schemas, profiles, conventions for your CDW | **GitLab** (private `AutoTTE-local`) |
| New institution-specific DB | **GitLab** — add YAML + supporting files under `databases/local/` |
| Bug fix to discovery code that happens to affect how `local/` is scanned | **GitHub** — generic behavior even if the motivation is private |

Rule of thumb: would you want a stranger cloning the public repo to have
it? If no → GitLab.

## Day-to-day: public-only change (most common)

```bash
# edit files in AutoTTE/
git add <files>
git commit
git push                # pushes to GitHub
```

No submodule interaction needed. The submodule pointer stays at whatever
SHA it was at.

## Day-to-day: private-only change

```bash
cd databases/local
# edit the private files
git add <files>
git commit
git push                # pushes to GitLab
cd ../..
# Now update the pointer in the parent repo
git add databases/local
git commit -m "Bump local submodule to <short message>"
git push                # pushes the gitlink bump to GitHub
```

Two commits, two remotes. The second commit is the "gitlink bump" — it's
how the public repo records which version of the private repo goes with
this code. Skip it and collaborators who pull your public commits will
be on a stale submodule SHA.

## Pulling others' work

```bash
git pull                                # GitHub changes
git submodule update --recursive        # Sync submodule to whatever SHA
                                        # the parent repo says it should
                                        # be at
```

Or in one command:

```bash
git pull --recurse-submodules
```

You can also set this as default:

```bash
git config --global submodule.recurse true
```

## Fresh clone on a new machine

```bash
git clone --recursive git@github.com:tjohnson250/AutoTTE.git
# or, if you forgot --recursive:
cd AutoTTE && git submodule update --init --recursive
```

The new machine also needs:

- SSH access to **both** remotes (GitHub key + GitLab key, or one key
  uploaded to both)
- Anaconda Python with `mcp httpx lxml pyyaml` (the `run.sh` preflight
  catches this)

## Inspecting state

```bash
# What's the submodule pointing at?
git submodule status                    # ±SHA followed by "(branch/tag)"
#   "-<sha>" = not checked out
#   " <sha>" = clean
#   "+<sha>" = working tree modified or pointer out of sync

# What's uncommitted, in either repo?
git status                              # parent
git -C databases/local status           # submodule

# What's unpushed?
git log @{u}..                          # parent
git -C databases/local log @{u}..       # submodule
```

## Common mistakes to avoid

1. **Committing private files to GitHub.** The un-ignore lines in
   `.gitignore` are gone and the files no longer exist under
   `databases/`, so git won't let you track them there anymore. But if
   someone copies `secure_pcornet_cdw.yaml` to `databases/foo.yaml` by
   accident and commits, that'd leak it. The check:
   `git ls-files databases/ | grep -v local` should only list
   generic/public configs.

2. **Forgetting the gitlink bump.** Changes inside `databases/local/`
   pushed to GitLab but no parent commit → the public repo still points
   at the old submodule SHA, and collaborators see stale private data
   even after a fresh pull. Always do the "two commits" dance.

3. **Detached-HEAD inside the submodule.** `git submodule update` checks
   out the recorded SHA, not the branch. If you `cd databases/local` and
   immediately edit, you're on detached HEAD. Fix: `git checkout main`
   before editing. (Or configure
   `submodule.databases/local.update = merge` — but detached-HEAD +
   explicit checkout is clearer.)

4. **Force-pushing the submodule.** Anyone who's checked out the old SHA
   in the parent now has a dangling pointer. Avoid unless you're the
   only user.

5. **Leaking the private URL.** `.gitmodules` is public and contains
   `git@gitpapl1.uth.tmc.edu:big-arc/research/autotte-local.git`. That
   URL is useless without SSH access but reveals the GitLab host, repo
   path, and group name. Acceptable for most orgs; if you later want to
   hide it, move to a shorter / less revealing URL or use a per-host
   `insteadOf` rewrite.

## Quick-reference cheat sheet

```bash
# Public change
git add . && git commit && git push

# Private change
(cd databases/local && git add . && git commit && git push) \
  && git add databases/local && git commit -m "Bump local submodule" && git push

# Pull everything
git pull --recurse-submodules

# See what's unpushed anywhere
git log @{u}.. ; git -C databases/local log @{u}..
```
