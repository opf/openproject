---
sidebar_navigation:
  title: Safe AI usage
description: Guidelines for safely using AI coding assistants in OpenProject development
keywords: AI, sandbox, safe AI, coding assistant, development, Docker
---

# Safe AI usage

This page explains how to constrain what an AI agent can do using sandboxing and isolated Docker environments, so you can work productively without exposing your system to unnecessary risk.

## Why sandboxing matters

When an AI agent runs bash commands on your machine, it operates with your full user permissions by default. In a project like OpenProject this means it could:

- Read credentials from `config/database.yml` or `.env` files
- Make unintended network requests to external services
- Modify files outside the project directory

Sandboxing creates a defined boundary around what the agent can access — both on the filesystem and on the network — without requiring you to approve every single command individually.

## Sandboxing approach 1

## Sandboxing approach 2




