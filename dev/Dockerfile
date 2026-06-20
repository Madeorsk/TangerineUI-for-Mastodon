# Overlay on Mastodon's own devcontainer image so Ruby/Node always match the checked-out Mastodon version.
# dev.sh builds that base from dev/mastodon/.devcontainer/Dockerfile first, then this layers the theme dev-loop tooling on top.
ARG BASE_IMAGE=tangerineui-mastodon-base:dev
FROM ${BASE_IMAGE}

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
# Quiet rvm (when present) instead of erroring on a .ruby-version it can't switch to.
ENV rvm_project_rvmrc=0

# Bind-mounted checkout is owned by the host user, so git would refuse it as root.
RUN git config --system --add safe.directory '*'

# yarn (via Corepack) for Vite, foreman for bin/dev.
RUN /bin/bash --login -i -c "corepack enable" && gem install foreman
