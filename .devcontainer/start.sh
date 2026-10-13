#!/bin/bash

set -euo pipefail

"${HOME}/openproject/.devcontainer/start-base.sh"

cat <<EOF
             ╭──────────╮
             │          │
             │  ╭────╮  │
             │  │    │  │
             │  │    │  │
 ╭───────────┘  └────╯  │
 │                      │
 │  ╭───────────────────╯
 │  │   ┌──┐ ┌──┐
 │  │   │  │ │  │
 │  │   │  │ ╰──╯
 │  ╰───╯  │
 │         │
 ╰─────────╯

 OpenProject Dev Container
===========================

The backend is now running
on localhost:3000 and the
frontend on localhost:4200.

Visit the following link
in your browser:

  http://localhost:3000

If you need to see the
backend or frontend logs,
enter:

  screen -x backend
  screen -x frontend

You can exit the screen
with Ctrl+A+D.

The frontend and backend
builds may still need a
few minutes, please be
patient.

Happy coding!
EOF
