---
  title: OpenProject 8.3.2
  sidebar_navigation:
      title: 8.3.2
  release_version: 8.3.2
  release_date: 2019-04-30
---


# OpenProject 8.3.2

We released OpenProject 8.3.2.  
The release contains a security related fix and we urge updating to the
newest version.

 

## CVE-2019-11600

A SQL injection vulnerability in the activities API in OpenProject
before 8.3.2 allows a remote attacker to execute arbitrary SQL commands
via the id parameter. The attack can be performed unauthenticated if
OpenProject is configured not to require authentication for API access. 
This vulnerability has been assigned the CVE identifier CVE-2019-11600.

Versions Affected: 5.0.0 – 8.3.1  
Not affected: Versions \< 5.0.0  
Fixed Versions: 8.3.2, 9.0.0

For the full advisory and patches for older unsupported versions,
[please see this
post](https://groups.google.com/d/msg/openproject-security/XlucAJMxmzM/hESpOaFVAwAJ).
For our statement on security and further information on how to
responsible disclose security related issues to us, please see our
[statement on security](https://www.openproject.org/security/).

Thanks to Thanaphon Soo from the [SEC Consult Vulnerability
Lab](https://www.sec-consult.com) for identifying and responsibly
disclosing the identified issues.


