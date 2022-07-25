---
sidebar_navigation:
  title: Installation support
  priority: 980
description: Installation support for OpenProject Enterprise on-premises.
keywords: installation support
---
# Installation support for Enterprise on-premises

 We deliver the confidence of a tested, supported and certified enterprise-class business application.  

If you want to work with OpenProject Enterprise on-premises but do not have a Community Edition running, you can order **installation support** during the [booking process of your Enterprise on-premises edition](../../activate-enterprise-on-premises).

The cost for the installation support of a Community version is 150 € (excluding VAT). In the price there is no migration included. If you need migration support, please [contact us](mailto:info@openproject.com) for a detailed quotation.



## Support Data Collector

Please run [our script](/script/op-support-data.sh) and send us the complete terminal output prior to the on-premise installation.

The script should run once on the OpenProject on-premises host with or without OpenProject installed
 It will ask you some questions that are needed to be answered interactively.
 Please copy the script to the host (either copy/paste to a new file in  your host systems editor or by copying the script e.g. via scp).
 Do not forget to make it executable and then you could run the data collector.
 Also please do not forget to log your complete terminal output.
 Please attach the log file of the terminal output to an email reply in your ticket at [support@openproject.com](mailto:support@openproject.com)

`sudo chmod +x op-support-data.sh`

` sudo ./op-support-data.sh`

