---
sidebar_navigation:
  title: Installation support
  priority: 980
description: Installation support for OpenProject Enterprise on-premises.
keywords: installation support
---
# Installation support for Enterprise on-premises

Our Premium and Corporate Enterprise on-premises support plans include installation support. We will contact you to get the necessary information to set up your environment.

## Support Data Collector

Please run [our script](./script/op-support-data.sh) and send us the complete terminal output prior to the on-premise installation.

The script should run once on the OpenProject on-premises host with or without OpenProject installed
 It will ask you some questions that are needed to be answered interactively.
 Please copy the script to the host (either copy/paste to a new file in  your host systems editor or by copying the script e.g. via scp).
 Do not forget to make it executable and then you could run the data collector.
 Also please do not forget to log your complete terminal output.
 Please attach the log file of the terminal output to an email reply in your ticket at [support@openproject.com](mailto:support@openproject.com)

`sudo chmod +x op-support-data.sh`

` sudo ./op-support-data.sh`

