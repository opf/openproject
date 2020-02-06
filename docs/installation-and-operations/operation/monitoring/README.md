---
sidebar_navigation:
  title: Monitoring & Logs
  priority: 6
---

# Monitoring your OpenProject installation

## Show logs

In a package-based installation, the `openproject` command line tool can be
used to see the log information. The most typically use case is to show/follow
all current log entries. This can be accomplished using the the `–tail` flag.
See example below:

```bash
sudo openproject logs --tail
```

Note:

* On distributions that are based on systemd, all the logs are sent to journald, so you can also display them via `journalctl`.
* On older distributions that use either sysvinit or upstart, all the logs are stored in `/var/log/openproject/`.
