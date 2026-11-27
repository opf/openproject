#!/bin/bash

set -euo pipefail

screen -dmS backend bundle exec rails server -u puma -b 0.0.0.0
screen -dmS frontend npm run serve

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

You can then open OpenProject in your browser:

    https://openproject.localhost

You will get a certificate warning on this host, that is normal.

If you need to see the backend or frontend logs, enter:

  screen -x backend
  screen -x frontend

You can exit the screen with Ctrl+A+D.

The frontend and backend builds may still need a few minutes, please be
patient.

Happy coding!
EOF
