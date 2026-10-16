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

               OpenProject Dev Container with KeyCloak
==========================================================================

You can then open OpenProject in your browser:

    https://openproject.localhost

You will get a certificate warning, that is to be expected.

If you need to access KeyCloak, you can do so at https://keycloak.localhost

Please note that OIDC login is an enterprise feature in OpenProject and
you will need to use an enterprise token for it to work properly.

If you need to see the backend or frontend logs, enter:

  screen -x backend
  screen -x frontend

You can exit the screen with Ctrl+A+D.

The frontend and backend builds may still need a few minutes, please be
patient.

Happy coding!
EOF
