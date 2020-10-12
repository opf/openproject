---
title: OpenProject 10.0.2
sidebar_navigation:
    title: 10.0.2
release_version: 10.0.2
release_date: 2019-10-02
---

# OpenProject 10.0.2

We released [OpenProject 10.0.2](https://community.openproject.com/versions/1395).
The release contains a security related fix and we urge updating to the newest version.



## [CVE-2019-17092] XSS injection vulnerability in projects listing in versions before 9.0.4, 10.0.2

An XSS vulnerability in project list in OpenProject before 9.0.4 and 10.x before 10.0.2 allows remote attackers to inject arbitrary web script or HTML via the sortBy parameter because error messages are mishandled.

This vulnerability has been assigned the CVE identifier CVE-2019-17092.

Versions Affected: Versions <= 9.0.3, 10.0.1
Fixed Versions: 9.0.4, 10.0.2

Credits
Thanks to David Haintz from the SEC Consult Vulnerability Lab (https://www.sec-consult.com) for identifying and responsibly disclosing the identified issues.

####  

#### Incorrect setting results in slow application and RAM usage

The environment variable *WEB_CONCURRENCY* has been used by OpenProject for some time to control the number of web workers to be spawned by the Unicorn application server. It is defaulting to 4 workers which should account to around 1 - 1.2GB of RAM usage.

In the upgrade to OpenProject 10, a buildpack from Heroku was updated to control the packaging of the frontend and its assets (our Angular frontend), which appears to be using the same variable for setting internal workers that are unrelated to our setup. This has resulted in the *WEB_CONCURRENCY* value to be set to a number that would exhaust many servers being set up for OpenProject and in turn resulting in bad performance of OpenProject and any other service.

This has been fixed in this release. We now use the environment variable *OPENPROJECT_WEB_WORKERS* to control the same setting. If you previously set *WEB_CONCURRENCY* in your application to a lower or higher number, please also set the *OPENPROJECT_WEB_WORKERS* variable to the same value.

####  

#### OtherBug fixes and changes

- Fixed: Inconsistent row heights when resizing widgets [[#31048](https://community.openproject.com/wp/31048)]
- Fixed: In Budgets projected unit costs and labor cost is not shown [[#31247](https://community.openproject.com/wp/31247)]
- Fixed: Restart puma workers to cope with potential memory leaks [[#31262](https://community.openproject.com/wp/31262)]
- Fixed: "Enterprise Edition" blue bar would be nicer horizontally [[#31265](https://community.openproject.com/wp/31265)]

####  

#### Contributions

Thanks to David Haintz from [SEC Consult Vulnerability Lab](https://www.sec-consult.com/) for identifying and responsibly disclosing the identified issues.

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to Andrea Pistai
