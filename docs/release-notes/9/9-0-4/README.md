---
title: OpenProject 9.0.4
sidebar_navigation:
    title: 9.0.4
release_version: 9.0.4
release_date: 2019-07-23
---

# [CVE-2019-17092] XSS injection vulnerability in projects listing in versions before 9.0.4, 10.0.2

An XSS vulnerability in project list in OpenProject before 9.0.4 and 10.x before 10.0.2 allows remote attackers to inject arbitrary web script or HTML via the sortBy parameter because error messages are mishandled.

This vulnerability has been assigned the CVE identifier CVE-2019-17092.

Versions Affected: Versions <= 9.0.3, 10.0.1
Fixed Versions: 9.0.4, 10.0.2

## Credits
Thanks to David Haintz from the SEC Consult Vulnerability Lab (https://www.sec-consult.com) for identifying and responsibly disclosing the identified issues.

#### Contributions

Thanks to David Haintz from [SEC Consult Vulnerability Lab](https://www.sec-consult.com/) for identifying and responsibly disclosing the identified issues.
