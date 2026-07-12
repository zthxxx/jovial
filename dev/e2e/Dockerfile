# Slim image for the isolated test suite: zsh + python3 + go-task only.
# Unlike the visual-preview image (dev/preview/Dockerfile), this one carries
# no vhs / ttyd / fonts / language runtimes -- it exists to run the whole
# `task test` pipeline (lint + unit + integration) in a clean Linux
# environment fully isolated from the host shell setup.
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        zsh python3 git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# go-task (https://taskfile.dev): the container runs the SAME Taskfile entry
# points as the local shell and CI, so all three stay isomorphic
RUN sh -c "$(curl -fsSL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

ENV LANG=C.UTF-8
WORKDIR /repo
