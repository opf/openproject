---
sidebar_navigation:
  title: Product Development
  priority: 100
description: Learn about OpenProject's product development process
robots: index, follow
keywords: product development, requirement process
---

<h1>OpenProject Product Development Handbook</h1>



## 1. Overview & Objectives

OpenProject aims to connect distributed teams and organizations and make project management intuitive and fun. The open source software supports classical project management and team collaboration as well as agile project management methodologies. OpenProject is continuously developed and maintained by an active international community to provide a powerful feature set and yet intuitive user interface. The overall purpose is to create customer benefit. To achieve this, OpenProject follows a requirements and product development process that empathizes identifying and building the functionality which most aligns with OpenProject’s product vision and delivers customer value.

This guide is an evolving description of the steps taken from collecting requirements all the way to implementation and release. The goal is to provide a single source of truth and provide a guideline for team members, community contributors and interested customers. As such this document will continuously be updated.

## 2. Process overview

The product development process involves various roles during the different phases. The following picture gives an overview of the responsible parties during the different phases as well as the respective output for each phase.

[tbd]

## 3. Requirements collection and specification phase

The phase for requirements collection and specification aims to get the best possible understanding of new requirements and enables to prioritize the development in an objective manner.

For new ideas and requirements which are not clearly understood yet and require specification, Product Managers (PM), User Experience Experts / designers (UX) should work together to validate the idea before moving to the build phase.

Product Managers and UX should work together at least one version (~ 2 months) ahead, so that the development team in the build track has always well-defined and validated requirements ready to start. Especially requirements with a level of confidence lower 80% (see [RICE Score](# 3.4-RICE-Score)) should be clearly validated.

The specification phase may not be necessary for bug fixes, minor design changes, minor improvements of smaller code maintenance topics.



### 3.1 Evaluation phase 1: Requirement collection

| Who is involved?                                             | Steps               | Output                                                       |
| ------------------------------------------------------------ | ----- | :----------------------------------------------------------- |
| - Entire team (incl. PMs, UXers, developers, etc.)    | 1. Collect requirements in Wish List | Feature request in Wish List |
| - Customers |                                      |                              |
| - Community |                                      |                              |
| - Other stakeholders |                                      |                              |

The [OpenProject Wish List](https://community.openproject.com/projects/openproject/work_packages?query_id=180) is used to collect a backlog of potential validation opportunities. Requirements may come from customers, internal usage, support messages, community forums or through other communication channels.

Requirements should be captured as a **Feature** or **Epic** (for larger features which we can be broken down into smaller features) and focus on describing the customer’s problem rather than jumping ahead to a solution.
For a guideline on how to report feature requests, refer to the [Feature request guideline](https://docs.openproject.org/development/submit-feature-idea/). Technical maintenance issues and refactorings can be tracked as **Code Maintenance**.

**Bugs** should be reported separately and be assigned to the [Bug backlog](https://docs.openproject.org/development/report-a-bug/).



### 3.2 Evaluation phase 2: Requirement evaluation / Problem validation

| Who is involved?  | Steps                                         | Output                               |
| ----------------- | --------------------------------------------- | :----------------------------------- |
| - Product Manager | 1. Structure requirements / remove duplicates | Evaluated feature in Product Backlog |
| - UX Researcher   | 2. Set RICE values                            |                                      |
|                   | 3. Create Opportunity Canvas                  |                                      |
|                   | 4. Assign to product backlog                  |                                      |

In regular intervals (e.g. once a week), PMs screen the requirements added to the Wish List and evaluate them:

1. PM adjusts feature requests to a common format (see [Feature Request guideline](https://docs.openproject.org/development/submit-feature-idea/)). 
2. PM rejects duplicated feature requests with a reference to the original feature requests.
3. PM sets RICE values and a RICE score for feature requests.
4. PM creates an Opportunity Canvas for requirements with a moderate to high level of uncertainty (> 80%) or for large requirements (effort > 1 week).
5. PM assigns features to the product backlog (only features with RICE values are allowed in the [product backlog](https://community.openproject.com/projects/openproject/work_packages?query_id=2261)).
6. For requirements which require an Opportunity Canvas: PM and UX Researcher meet to discuss appropriate research methodology to collect user feedback.
   1. PM and UX Researcher schedule interviews with relevant users.
   2. PM and UX Researcher document interview results in opportunity canvas.
7. PM changes feature status from “New” to “In Specification”.



For internal or customer requirements requirements may directly be created, evaluated based on the [RICE framework](# 3.4-RICE-Score) and assigned to the product backlog.



### 3.3 Evaluation phase 3: Requirement specification



| Who is involved?  | Steps                                    | Output                                                   |
| ----------------- | ---------------------------------------- | :------------------------------------------------------- |
| - Product Manager | 1. Create mockup                         | Specified feature (status “Specified”) inProduct Backlog |
| - Developer       | 2. Validate & add effort / cost estimate |                                                          |
| - UX Researcher   | 3. Assign to next product version        |                                                          |
| - Designer        |                                          |                                                          |

Based on the validated and prioritized features in the product backlog (status: “In specification”) the requirements with the highest RICE score are specified in more detail:

1. PM specifies the solution and creates mockups (e.g. PowerPoint, Google Docs, …).
2. PM updates the Opportunity Canvas (especially “Solution” section).
3. PM and Developer validate solution (technical feasibility / solution).
4. PM / UX Researcher validates the solution through user interviews.
5. PM / UX Researcher iterates through possible solutions based on user interviews and updates the Opportunity canvas.
6. PM / Developer adds more detailed effort and cost estimates.
7. Designer creates visuals based on mockups (if necessary).
8. PM validates design with users (user interviews) (optional)
9. PM in coordination with Developer assigns feature to upcoming product version.
10. PM hands over features to the Developer.

The features in a product version need to be specified at least one iteration prior to development start.



### 3.4 RICE Score

The RICE scoring model is an evaluation method used to evaluate and compare requirements with each other and decide which products or features to prioritize on the roadmap - in an as objective manner as possible.

Using the RICE scoring model has three main benefits:

1. Minimize personal bias in decision making.
2. Enable product managers to make better decisions.
3. Help defend priorities to other stakeholders such as executives or customers.

The RICE scoring model was developed by [Intercom](https://www.intercom.com/) to improve its own decision making process. 
A helpful guideline with further information on the RICE framework is provided by [ProductPlan](https://www.productplan.com/glossary/rice-scoring-model/).

The RICE scoring model aims to objectively evaluate requirements (new products, features, add-ons, …) based on four different criteria to determine the RICE Score:



> RICE Score = **R**each x **I**mpact x **C**onfidence / **E**ffort



**Reach**

The first factor when determining the RICE score is the number of users reached by the feature.
For OpenProject, Reach refers to the number of users and customers who will benefit from a new requirement in the first quarter after its launch.

The reach ranges from 0.5 for minimal reach (less than 5% of users) to 10.0 for requirements that impact the vast majority of users (80% or more).

Data sources to estimate this may include queries and user data of an associated feature (e.g. number of users using the “Work packages” module on community.openproject.com to determine the value for a new work package requirement), qualitative customer interviews, customer requests, comments on work packages, surveys, etc..



**Impact**

The second numerator is Impact which refers to the benefits for users and customers Impact can refer to quantitative measures, such as conversion improvements, increased revenue, decreased risk or decreased cost or to qualitative measures, such as increasing customer delight.
This makes it possible to compare revenue generating opportunities to non-revenue generating opportunities.

Impact ranges from “Minimal” (0.25) to “Massive” (3.0).

The higher the impact, the higher the RICE score.



**Confidence**

Especially for more complex requirements it may be unclear what the reach, impact or effort is. The team may rely more on intuition for a factor. To account for this uncertainty, the confidence component is used.

For instance, if the reach is backed up by data but the impact is more of a gut feeling, the confidence score should account for this.

The confidence score ranges from 50% for low confidence to 100% for high confidence.

If you arrive at a confidence level below 50%, consider this requirement a “Moonshot” and focus your energy on other requirements.



**Effort**

The three aforementioned factors (Reach, Impact, Confidence) represent the numerators of the RICE score. The effort score refers to the estimated resources (product, design, engineering, quality assurance, etc.) in person-months needed to implement a feature.

The effort estimate is an approximate measure which uses shirt sizing.

The effort score ranges from 0.03 (XS = less than a day of effort) to 20 (XXXL = more than 12 months of effort).



Based on the RICE score calculated from the four aforementioned factors, features can be evaluated to each other in an objective way.

The RICE framework is used especially in the early phases of evaluating requirements and provides an easy and fast way to prioritize feature requests. 
For complex requirements with a low level of confidence (80% or lower) and / or high effort (more than 1 week), an opportunity canvas should be used in addition to the RICE score.



### 3.5 Opportunity Canvas

One of the main artifacts used in the evaluation phase is the Opportunity Canvas. The Opportunity Canvas - [slightly adapted from GitLab](https://about.gitlab.com/handbook/product-development-flow) - provides a quick overview of a requirement and includes four main sections as well as two supplemental sections:



**<u>Main sections:</u>**



**1. Problem** 

States the problem that the feature request is addressing.This includes the **Customer** information (the affected persona or persona segment that experiences the problem most acutely), a **Problem** description and a description of the customer **Pain**.



**2. Business Case**

The business case is closely aligned with the RICE score. The business case section includes information on the **Reach** (number of affected customers), **Impact** (how much value do customers get from the feature) and **Confidence** (what are the top risk factors that could prevent the delivery of the solution).

Additionally, the **Urgency and Priority** section provides information about the relative importance of the requirement compared to other opportunities, deadlines and other time-related information.



**3. Solution**
The solution to the problem can be laid out in this section. Define the **Minimal Viable Change** in a first version, what is **Out of scope** and the **Differentiation** from the current experience and competing solutions.
As an outlook, also provide some information on the **Next iteration**.



**4. Launch and Growth**
To get a complete picture of the requirement and its impact, it is essential to consider its marketing message early on.Define how you **Measure** if you solved the problem by specifying important metrics. Additionally, you can formulate a marketing **message** to identify the value proposition as early as possible.
Last but not least, briefly outline the **Go to Market** strategy.



**<u>Supplemental sections:</u>**



**1. Learnings**

The Opportunity Canvas is an iterative work document. As such it is often helpful to collect some assumptions early on and validate them when conducting customer interviews and learning more about the problem and solution.

The Learning section provides space to collect assumptions and validate them over time.



**2. Learning Goals**

The Learning Goals space is closely related to the Learning section. It includes assumptions and ways to validate or invalidate assumptions.

The Opportunity Canvas is intended to quickly validate or invalidate ideas and to identify possible issues early on. As such invalidating an idea through the opportunity canvas is just as valuable as validating an idea (if not even more so).

An Opportunity Canvas may not always be required - especially when a problem is well understood or small in scope.



**References:**

- [Opportunity Canvas Template](https://docs.google.com/document/d/1sgNrEx_PRCwewI9-46mN0qnyzz2AWq_SwFc6gLOcrbI/edit)



## 4. Building phase

During the building phase we develop, improve and test the validated solutions.



### 4.1 Building phase 1: Development

| Who is involved? | Steps                         | Output                                                  |
| ---------------- | ----------------------------- | :------------------------------------------------------ |
| - Developer      | 1. Develop features           | Developed features on test environment (feature freeze) |
| - DevOps         | 2. Deploy on test environment |                                                         |

Prior to working on a new product version, the development team analyzes the features from a technical viewpoint and breaks them down into technical work packages:

1. Developer breaks feature / Epics into technical work packages.
2. Developer adds technical specifications (on GitHub).
3. Developer starts developing features (status: “In development”).
4. Developer hands over feature for review (status: “In review”).
5. Developer merges feature (status: “merged”).
6. Developer highlights features that require change in documentation (custom field “Requires doc change”).
7. DevOps deploys features on a test environment.

Only in rare exceptions and under consultation of developers can additional features be added to a version (feature freeze).



### 4.2 Building phase 2: Quality Assurance

| Who is involved?  | Steps                                  | Output                        |
| ----------------- | -------------------------------------- | :---------------------------- |
| - Tester          | 1. Test features                       | Tested stable product vresion |
| - Product Manager | 2. Report bugs                         |                               |
| - Developer       | 3. Deploy on community.openproject.com |                               |
| - DevOps          |                                        |                               |

Building phase 1 (Development) and phase 2 (Quality Assurance) run partly in parallel / may loop since tested features may need to be adjusted.

1. Tester tests features and bugs for functionality (based on acceptance criteria) 
   1. Tester adjusts status when no errors in features (status: “tested”).
   2. Tester changes status when bug has been resolved (status: “closed”).
   3. Tester adjusts status when errors occur (status: “test failed”) and notifies developer (move back to phase 1 - Development)
2. PM tests features to see if requirements are met, discusses necessary changes with developer (acceptance test) (status: “closed”).
3. Tester performs regression test for most important functionality
4. DevOps deploys release on community environment for further testing.
5. Product Manager updates documentation based on feature changes.



When all features, bugs have been tested successfully, regression testing was performed successfully and no critical errors are reported on community.openproject.com OpenProject environment, new product version is prepared for release.



## 5. Release phase

During the release phase, the new OpenProject version is rolled out, release notes are published and lessons learned are documented.



### 5.1 Release phase 1: Rollout

| Who is involved?  | Steps                                       | Output                        |
| ----------------- | ------------------------------------------- | :---------------------------- |
| - DevOps          | 1. Create news / release notes              | Rolled out / released version |
| - Marketing       | 2. Release for Cloud / on-premise customers |                               |
| - Product Manager |                                             |                               |

Once tested and stabilized, a new OpenProject version is rolled out in stages:

1. DevOps creates release branch for new version.
2. Marketing / PM creates news and release notes.
3. DevOps deploys new release on Cloud Edition trials.
4. DevOps deploys new release on Cloud Edition production.
5. DevOps releases new OpenProject version for on-premise installations (Packager, Docker, notify UCS).
6. DevOps / Marketing update documentation for new release (technical, marketing information).



Phase 1 “Rollout” and phase 2 “Go to market” partially overlap / follow in short succession.



### 5.2 Release phase 2: Go to market

| Who is involved?  | Steps                            | Output                       |
| ----------------- | -------------------------------- | :--------------------------- |
| - Marketing       | 1. Publish news / release notes  | Announced / marketed release |
| - Product Manager | 2. Post newsletter, social media |                              |

In parallel or shortly after the rollout, marketing release notes and announcements are published.

1. Marketing publishes news.
2. PM publishes release notes.
3. Marketing reaches out to news organizations for external posts.
4. Marketing posts on social media.
5. Marketing releases newsletter.



### 5.3 Release phase 3: Evaluation / Lessons learned

After launch, the PM should pay close attention to product usage and customer feedback to guide further improvements, until the defined success metrics are met or the product has been sufficiently improved.

The metrics defined in the Opportunity Canvas are referenced to evaluate this.

The entire team documents possible improvements for the next release.