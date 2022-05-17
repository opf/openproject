---
sidebar_navigation:
  title: Cloud Status 
  priority: 002
description: Report of outages and degraded services for our cloud edition customers
robots: index, follow
keywords: cloud status, incidents
---

# OpenProject cloud status page

On this page, we will report any outages and reports of degraded services for our cloud edition customers.

* * *

## Current issues

–

* * *

## Past incidents

### June 25, 2020

We are currently seeing elevated response times and degraded performance. We are investigating the issue.

* * *

### September 11, 2018

(13:20 - 13:50 UTC) During the latest deployment of OpenProject 8.0. on our cloud infrastructure, a migration was added to rename a specific table used for the new application. This migration turned out to run through significantly longer.

* * *

### May 26 - 27th, 2018

(7:30 UTC) Services operating normally, root cause is being worked at.

(1:00 UTC) One of the Aurora databases in our PostgreSQL cluster failed in an autovacuum operation scheduled to execute at nights (UTC + 2). A failover to the reader database happened, but not all web workers of the OpenProject cloud services reconnected correctly, resulting in consistently dropped connections during that night.

* * *

### April 25th, 2018

(8:15 UTC) OpenProject email notifciation service has been restored.

(7:28 UTC) We are aware of degradede mail notifications on our OpenProject Cloud Edition service due to a technical issue with our mail notification provider and are actively working on resolving it.

* * *

### April 20th, 2018

(3:00 UTC) The OpenProject Cloud Edition is currently not available in Russia since the IP address is being blocked in connection with blocking Telegram ([more information](https://www.bbc.com/news/technology-43797176)).

(3:00 UTC) The OpenProject Cloud Edition service is currently not available in Russia.

* * *

### April 16th, 2018

(7:30 UTC) Services operating normally.

(7:20 UTC) One of the Aurora databases in our PostgreSQL cluster denied new client connections, resulting in timeouts whenever new web workers were restarted (this is scheduled randomly after a few thousand requests). The instance however reported normal operation and in turn did not automatically failover by itself. Once the failing database was took out of the cluster and restarted, access returned to normal.

(6:30 UTC) We're investigating page timeouts and incomplete responses returned to some of our cloud environment instances.

* * *

### March 14th, 2018

(14:25 UTC) Services operating normally.

(14:07 UTC) We're aware of occasional Gateway timeout responses from one of our load balancers.
