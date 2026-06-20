#!/usr/bin/env bash
# Tangerine UI local dev environment.
# Runs Mastodon (dev/mastodon submodule) in Docker with the theme with HMR through Vite.
set -euo pipefail
cd "$(dirname "$0")"

DC="docker compose -f compose.yaml"
SUB="mastodon"
VARIANTS="tangerineui tangerineui-purple tangerineui-cherry tangerineui-lagoon"

# Derive the base image and Node version from the checked-out Mastodon so the Docker image matches whatever version the submodule points at.
if [ -f "$SUB/.devcontainer/Dockerfile" ]; then
  from_line="$(grep -m1 '^FROM ' "$SUB/.devcontainer/Dockerfile")"
  export MASTODON_BASE_IMAGE="${from_line#FROM }"
fi
[ -f "$SUB/.nvmrc" ] && export MASTODON_NODE_VERSION="$(cat "$SUB/.nvmrc")"

# Symlink the theme sources from this repo into the Mastodon checkout, register the variants in themes.yml, and add the localized theme names.
# Relative links resolve identically on the host and inside the /workspace bind mount.
link() {
  # Theme sources (styles + locale) are bind-mounted into the checkout by compose.yaml.
  for p in ../mastodon/app/javascript/styles/tangerineui*; do
    rm -rf "$SUB/app/javascript/styles/$(basename "$p")"
  done
  rm -f "$SUB/config/locales/tangerineui.yml"

  local themes="$SUB/config/themes.yml"
  for v in $VARIANTS; do
    grep -q "^$v:" "$themes" || printf '%s: styles/%s.scss\n' "$v" "$v" >> "$themes"
  done
  echo "Theme registered in themes.yml (styles + locale bind-mounted via compose.yaml)."
}

case "${1:-}" in
  link) link ;;
  init)
    link
    # Mastodon 4.5 only:
    # Build the base from Mastodon's own devcontainer Dockerfile, but patch the stale base image (its yarn apt key has expired) to the one from PR #37857.
    # Done on a copy so the submodule stays clean.
    patched="$(mktemp)"
    while IFS= read -r line; do
      if [ "$line" = "FROM mcr.microsoft.com/devcontainers/ruby:1-3.3-bookworm" ]; then
        echo "FROM mcr.microsoft.com/devcontainers/ruby:3.4-trixie"
      else
        echo "$line"
      fi
    done < mastodon/.devcontainer/Dockerfile > "$patched"
    docker build -t tangerineui-mastodon-base:dev -f "$patched" mastodon
    rm -f "$patched"
    $DC build
    $DC run --rm app bash -lc "yarn install && bundle install && bundle exec rails db:setup"
    echo "Init done. Run './dev.sh up' then open http://localhost:3000 (admin@localhost / mastodonadmin)."
    ;;
  seed)
    $DC run --rm app bash -lc "bundle exec rails runner /workspace/dev/seed.rb"
    ;;
  up)    $DC up app ;;
  down)  $DC down ;;
  logs)  $DC logs -f app ;;
  sh)    $DC exec app bash ;;
  *)
    echo "Usage: ./dev.sh {init|up|seed|link|logs|sh|down}"
    echo "  init  build image, install deps, set up the database (run once)"
    echo "  up    start Mastodon with Vite HMR on http://localhost:3000"
    echo "  seed  add sample posts, DM, boost, notifications, custom emoji"
    echo "  link  re-link the theme into the Mastodon checkout"
    echo "  logs  follow app logs"
    echo "  sh    shell into the app container"
    echo "  down  stop everything"
    ;;
esac
