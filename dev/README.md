# Local dev environment

Run Tangerine UI on a local Mastodon instance with Vite hot-reload, so editing the theme SCSS in this repo updates the browser live.

Mastodon itself lives in the `mastodon/` git submodule (pinned to a stable tag). The theme files from `../mastodon/` are bind-mounted into the container, so we can edit them in this repo and see the changes reflected in the running Mastodon instance.

The Docker image is built from the submodule's own `.devcontainer/Dockerfile`, so the Ruby and Node versions always match whatever Mastodon tag you check out. To test another version, check out a different tag in `mastodon/` and re-run `./dev.sh init` (see below).

## Requirements

- Docker + Docker Compose
- The submodule checked out: `git submodule update --init dev/mastodon`

## Usage

```sh
cd dev
./dev.sh init    # build image, install deps, set up the DB (run once, slow)
./dev.sh up      # start Mastodon at http://localhost:3000
./dev.sh seed    # optional: sample posts, DM, boost, notifications, emoji
```

Log in with **admin@localhost / mastodonadmin**, then pick a Tangerine UI variant under Preferences > Appearance > Site theme.

## Visual regression tests

Playwright screenshots the core surfaces (home, notifications, DMs, explore, local timeline, profile) for every variant in light and dark, and diffs them against committed baselines. Runs on the host against the instance from `./dev.sh up`.

```sh
./dev.sh up                          # instance must be running and seeded
./dev.sh visual                      # run the diff
./dev.sh visual --update-snapshots   # accept current rendering as baseline
```

Baselines live in `visual/__screenshots__`. After an intentional theme change, review the diff in `visual/playwright-report/`, then re-run with `--update-snapshots`.

## Other commands

| Command         | Description                          |
| --------------- | ------------------------------------ |
| `./dev.sh logs` | follow app logs                      |
| `./dev.sh sh`   | shell into the app container         |
| `./dev.sh down` | stop everything                      |

## Bumping the Mastodon version

```sh
# Starting from repository root.
cd dev/mastodon
git fetch --tags
git checkout vX.Y.Z
cd ../..
git add dev/mastodon
```

Then re-run `./dev.sh init` (rebuilds deps and migrates).
