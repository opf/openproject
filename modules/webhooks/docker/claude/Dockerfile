# Container image for Kubernetes scripts whose body is a natural-language prompt for Claude Code.
#
# Script settings in OpenProject:
#   Image:    the pushed tag of this image
#   Command:  op-claude
#   Script:   the prompt, e.g. "Summarize the comments of this work package and post the summary as a comment."
#   Environment variables: CLAUDE_CODE_OAUTH_TOKEN (from `claude setup-token`) or ANTHROPIC_API_KEY,
#                          optionally CLAUDE_MODEL
#
# Build: docker build -t <registry>/openproject-claude-script:latest modules/webhooks/docker/claude
FROM node:22-bookworm-slim

ARG CLAUDE_CODE_VERSION=2.1.326

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    && npm cache clean --force

COPY --chmod=0755 op-claude op-api /usr/local/bin/

ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Claude Code refuses to run tools as root and needs a writable home directory for its state.
USER node
WORKDIR /home/node/work

CMD ["claude", "--version"]
