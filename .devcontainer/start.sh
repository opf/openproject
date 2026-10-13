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
==========================================================================

Please add the following entries to your /etc/hosts file:

    127.0.0.1 openproject.local openproject-assets.local

You can then open OpenProject in your browser:

    https://openproject.local

You will get a certificate warning, and you may also have to open
https://openproject-assets.local in your browser for everything to work.

If you need to see the backend or frontend logs, enter:

  screen -x backend
  screen -x frontend

You can exit the screen with Ctrl+A+D.

The frontend and backend builds may still need a few minutes, please be
patient.

Happy coding!
EOF
