---
sidebar_navigation:
  title: Bug Process
  priority: 150
description: Learn about OpenProject's bug process
robots: index, follow
keywords: bug process, bug documentation
---

<h1>OpenProject Bug Process Guideline</h1>

[toc]

## Introduction / Context

This document describes the whole of how bugs are handled within OpenProject - from reporting to fixing bugs. [“A software bug is an error or flaw in a computer program or system that causes it to produce an incorrect or unexpected result, or to behave in unintended ways”](https://en.wikipedia.org/wiki/Software_bug).

## Bug process

### 1. Reporting bugs

<u>Involved teams:</u>

- Quality Assurance
- Community Management
- Everyone in touch with customers (e.g. customer support, sales, developers)

<u>Summary</u>:

Bugs reported by users through various channels are collected and reported as bug work packages on community.openproject.org.

<u>Steps:</u>

- Users outside of the OpenProject team report their own bugs in OpenProject (following the [bug reporting guideline](https://docs.openproject.org/development/report-a-bug/)). These bugs are in status “new”.
  - The [Community work package view](https://community.openproject.org/projects/openproject/work_packages?query_id=202) includes all work packages (including bugs) reported by the community
- Bugs reported by users / customers (e.g. by email, phone, forum) as well as bugs found internally (e.g. by QA) are tracked using the [bug reporting guideline](https://docs.openproject.org/development/report-a-bug/) as a guideline. These bugs are directly set to status “confirmed”.
- Bugs are generally created in the “OpenProject” project.
  - Exceptions: 
    - Security-related bugs are tracked in the project “Security (confidential)”
    - Customers who have the Premier Support (or higher) have their own project and can report bugs in those projects
    - Bugs that are internal to OpenProject and are confidential or not relevant to the open source community are tracked in a separate project (e.g. “OpenProject GmbH”, “Saas”, etc.)
      

Bugs reported by external users are generally in status “new”.
Bugs reported by the OpenProject team (which have been tested and can be reproduced) are directly changed to status “confirmed”. If bugs are e.g. reported on behalf of customers and cannot be reproduced or require input from a developer they should be set to “needs clarification” (see section “2. Confirming / clarifying bugs” for details).



### 2. Confirming / clarifying bugs

<u>Involved teams:</u>

- Quality Assurance
- Community Management
- Software Development (if technical input required)

<u>Summary</u>:

Reported bugs are confirmed, clarified (by collecting feedback from the bug creators (e.g. customers) or by requesting a technical clarification by the development team) and moved to a separate project if necessary.

<u>Steps:</u>

- The newly reported bugs are scanned in regular intervals by Quality Assurance and Community Management.
- If a bug can be confirmed by QA the status is changed from “new” to “confirmed”.
- If a bug has insufficient information, its status is changed to “needs clarification” and a comment is added to the bug to ask for additional information (e.g. reproduction steps, screenshots, etc.). If possible the bug’s creator is tagged in the comment (via “@”) and assigned.
- If additional technical clarification is needed (e.g. since it is a very technical topic), the status is changed to “needs clarification” and assigned to a developer to ask for assistance.
  - To determine who to assign the [technical topic list](https://docs.google.com/spreadsheets/d/16KWZKOH4u3t-BaQsXWo3VEmCsuNAFmiIt6DxiPwQ-8E/edit?usp=sharing) can be used.
  - If a topic 
    - is time critical / urgent, a comment should be added to communicate this. This should be the exception.
    - is not time critical / urgent, the developer does not have to stop her/his current task as it might require a time consuming analysis. Instead, the developer can decide on when would be a fitting time to assess the bug. 
- If a bug is in the wrong project (e.g. a security or otherwise sensitive topic) it should be moved to the appropriate project (e.g. “Security (confidential)”).



The development team can take a look at the “[Evaluation developers required](https://community.openproject.com/projects/openproject/work_packages?query_id=2727)“ query for an overview of the topics where input is needed.


<u>Notes:</u>

- When a developer is asked for assistance, it is understood that a reply may take several days.
- If a topic is urgent it should be mentioned in the comment and (if very urgent) additional communication channels (e.g. Slack) are being used.





### 3. Prioritizing bugs

<u>Involved teams:</u>

- Quality Assurance

<u>Summary</u>:

Out of the list of confirmed bugs, the most important / urgent bugs are prioritized to be addressed in the next version. For this, there is a status “prioritized” which means that these are the bugs that the development team looks at to fix in the upcoming versions.

<u>Steps:</u>

- Out of the list of confirmed bugs, the most important bugs are moved from status “confirmed” to “prioritized”.
  - Ideally, not every bug that could be worked on is moved to the “prioritized” status as it will complicate the actual prioritization, i.e. weighing the importance of fixing one bug against all of the others in the next step.
- The list of prioritized bugs is sorted based on importance: The most important bug is at the top of the list, the least important bug at the bottom of the list.
- The prioritized list contains the bugs that the development team can look at next and take bugs from to fix them (see step 4.Assigning bugs to version & fixing bugs).
  - The bugs at the top of the list are being looked at first (note: due to technical affinity, complexity, dependencies, etc. this does not mean that these bugs are necessarily fixed in that order)


There is a work package view that reflects those prioritized bugs:https://community.openproject.org/projects/openproject/work_packages?query_id=2865

![img](https://lh5.googleusercontent.com/bnpy8Rjej_Zu5LQ17x8Xj4GoxTJKwaPuF0na7GekyikQ4l9EdJ2D7OA08UNCu0zvLMb_5c0dpLUUpgF8yIdod9KP4iNjIVu49rXuBl3y1oQB9mKrWzCQCT2ZGafx-dNBGWAvh7ux)



The bugs are assessed and prioritized mostly according to their severity. The effort required to fix them may also be a factor but as no thorough technical analysis will take place up until after the prioritization has already taken place, there will not be a dependable estimate on the effort.  

Bugs can only be set to “prioritized” by OpenProject team members. When assigning bugs to “prioritized”, they should be prioritized against all other bugs. Therefore, team members who assign bugs to “prioritized” should have an overview of the other bugs to evaluate how critical the issue really is. Ideally, the assignment to “prioritized'' should be done by team members who have a good overview of existing bugs. Most of the time, this should be carried out by QA/ Community Management.

QA, Community Management scans the “prioritized” list in regular intervals to adjust the order and add additional bugs. 

Other team members can add bugs as well. (Example: There may be bugs which are more technical and may hinder development while not directly affecting users. This may not be clear to QA but only to Software Development.) Ideally, the necessity to prioritize a bug fix is talked through with QA/Community Management, to ensure that the “prioritized” list includes the most important bugs.

The work package view with the prioritized bugs does not include bugs that are outside the scope of an OpenProject version (e.g. changes to the website, changes to SaaS, etc.)



### 4. Assigning bugs to version & fixing bugs

<u>Involved teams:</u>

- Software Development

<u>Summary</u>:

Out of the list of prioritized bugs the development team looks at the bugs starting from the top of the list and decides on the bugs to assign to the next OpenProject version (using a Kanban approach).

<u>Steps:</u>

- At the start of every patch level release (typically right after the preceding patch/minor/major release has been published), Software Development and Quality Assurance evaluate a time frame for the release of the next patch release. We aim for 2 weeks cycles. During this consultation, the desired amount of bug fixes is also discussed. The list of prioritized bugs should ideally be longer than the list of bugs to be fixed for the upcoming release in case an opportunity to fix more bugs reveals itself. 
- The development team takes a look at the prioritized list of bugs (starting from the top) and - out of that list of bugs - moves bugs to the current version (“Kanban style”) when development on the bugfix starts.
  - The layer of the code that is involved (Angular, Ruby, CSS, …) vs the affinity of the developer might lead to the developer skipping bugs.
- The developer analyzes the bug. 
  - If fixing the bug will take a lengthy amount of time the developer gets in contact with QA to discuss whether the effort is worthwhile at the current time (prioritized against bugs potentially more easy to fix). If it is deemed not to be, fixing the bug is halted, and the bug is moved out of the version again.  
  - This step will also take place for bugs originating from changes in the current version which might also be moved out of the version.
  - If fixing the bug will take an adequate amount of time, the developer will start fixing the bug without further involvement of QA.
- The developer fixes the bug.



<u>Notes:</u>

- Bugs are only assigned by the development team to a version, not by anyone else.
  - Exception: For releases that contain new features (minor / major releases), QA directly assigns bugs that are related to a new feature to the version the feature is in. That means that fixing them also has a higher precedence than fixing bugs that exist in already released versions. But if such a bug is deemed to be of lesser severity, it can be moved out of the version. It will then be prioritized just like any bug. 
- On a general basis, new bugs will not be fixed between the time QA finishes and the release is published. (Generally, requires a re-test by QA.) Otherwise, untested and untried code might be published. Bugfixed deemed inadequate might also not be improved again. This is a risk vs gain assessment that has to be decided on case by case. The same is true for critical bugs discovered after QA. 



### 5. Testing bug fixes

<u>Involved teams:</u>

- Quality Assurance

<u>Summary</u>:

The quality assurance team tests the fixed bugs on a test environment and performs a regression test covering the most important functionalities.

<u>Steps:</u>

- When a bug has been fixed (Status “merged”) and deployed on a test environment, it is ready to be tested by the quality assurance (QA) team.
- The bug fix can either be tested on an edge environment (e.g. qa.openproject-edge.com) which reflects the current state of the dev branch or on a stage environment (e.g. qa.openproject-stage.com) which contains the current state of the release branch.
  - Patch-level release candidates should be tested on the stage environment (since the edge environment (running dev) may include other changes).
  - Check in administration > Information if a deployment has been made after merging a bug fix
- Aside from testing the bug fix (in various browsers) itself, adjacent functionalities should be tested as well.
  - If a bug fix has been implemented and passed testing, the status is updated to “closed” (if the bug has been reported by a customer and needs to be verified on their environment change it to “tested” instead)
  - If a bug fix fails the test, the status is to be changed to “test failed” and a comment is to be added explaining which part of the test failed (with a screenshot / gif if applicable). The bug should then be reassigned to the developer who worked on the bug fix.
- When a release candidate enters the “bug freeze” (patch level release) or “feature freeze” (minor / major release) phase, a regression test can be started.
  - As part of a regression test, the main functionalities of OpenProject are tested.
  - If bugs are identified, bug reports are created.
    - Bugs which already existed prior to the release candidate are assigned to the list of bugs (without assigning a version)
    - Bugs which are a regression (did not exist prior to the release) can be directly assigned to the current version (to be evaluated and possibly moved out of the version by the development team)

<u>Notes:</u>

- Ideally, QA takes place continuously. It will have to be completed on a date agreed upon by both QA and development. That date is determined when the upcoming release is planned. It has to take into account the time it requires for the release to be tried out on the community shard which typically amounts to 3 days.
- Bug fixes that are deemed inadequate are set to “Test failed” and remain in the version. Development will pick those up and attempt to fix them before the release. If the time expected is too long, because the release is looming, the fix might be placed back in the “prioritized” list. The code written for the bugfix so far can remain in the codebase if it has no visible effect or already improves the situation in part. In other situations, it might have to be reverted. Ideally, a bug fixed in part should be reflected in an extra ticket to be visible in the release notes.