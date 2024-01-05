---
sidebar_navigation:
  title: Implementing Scaled Agile Framework (SAFe) with OpenProject
  priority: 990
description: Understand the principles of the Scaled Agile Framework (SAFe) to manage and organise work in your organisation and see how you can practically implement them in OpenProjet.
keywords: safe, scaled agile, release train, program increment, ART backlog, roadmap, portfolio backlog, solution train, script, scrum, roadmap
---

# Implementing SAFe (Scaled Agile Framework) with OpenProject

OpenProject is a powerful project management tool that can adapt to a number of different project management and organisational frameworks. Larger organisations who choose to implement the Scaled Agile Framework methodology can leverage the wide range of features and customisability of OpenProject to support the implementation of SAFe principles.

Here, we go through the ten fundamental principles of SAFe and how you can put them into practice with specific OpenProject features.

## **Take an economic view**

In SAFe, taking an economic view involves delivering early and often and applying a comprehensive economic framework that allows lean teams and Agile Release Trains to efficiently asses costs, benefits and risks associated with each decision, at each iteration. This ensures that effort at all levels aligns with larger business strategies. This alignment is facilitated by a prioritised backlog, which functions as a dynamic roadmap in delivering economically valuable increments during each iteration. Decision-making can then be grounded in factors such as development expense, lead time, product cost, value and potential risks and impacts on market share, which enables organisations to make informed choices that optimise value delivery and minimise cost of delay.

In OpenProject:

- Use **automatic one-click time tracking** to let team members effortless keep track of their effort
- Use **cost tracking and reporting** features and associate **budgets** with specific features, enablers and epics
- Use **time and budget reports** to keep an eye on costs and expenditures at all times: before, during and after PI planning
- Generate **reports** in OpenProject to make informed decisions

## **Apply systems thinking**

Systems thinking within SAFe necessitates a deep understanding of the interconnectedness of the different components within an organisation. Agile teams play a crucial role in addressing dependencies and bottlenecks. The backlog, a dynamic repository of prioritised features and enablers, serves as a central tool for systematic improvement. This holistic approach, supported by Kanban and Scrum practices, ensures that work flows seamlessly across the train, enhances collaboration and promotes efficient value delivery.

In OpenProject:

- \[planned\] Use the upcoming **project portfolio** feature to visualise the entire system, across projects down to individual user stories
- Use **project templates** and **workflows** to define efficient development value streams that minimise wait time
- Use the the **project hierarchy** feature in OpenProject to create parent-child relationships between projects or work packages, use **filters** to get exactly the right perspective on parallel value streams
- Leverage dependency tracking via **work package relations** to understand and manage interdependencies between epics, user stories and portfolios across projects

## **Assume variability; preserve options**

Acknowledging variability in SAFe is about recognising the inherent unpredictability of projects and the evolving nature of customer needs. The backlog, as a repository of features, enablers and potential solutions, is a critical tool for preserving options. This principle encourages organisations to avoid premature commitment to a single solution, allowing decisions to be deferred until the last responsible moment. This approach allows teams working within Agile Release Trains (ART) to minimise the risk of investing resources in features that may become obsolete and ensure the organisation remains agile and capable of meeting evolving requirements.

In OpenProject:

- Maintain flexibility by using **epics or work packages** to encapsulate themes or initiatives without defining all details upfront
- Use **work package templates** to define a clear structure to epics and user stories
- Use **Backlogs** to keep a list of potential features or user stories that can be prioritised based on changing needs at every program increment (PI)

## **Build incrementally with fast, integrated learning cycles**

Incremental development in SAFe is a key principle that involves breaking down complex projects into manageable Product Increments (PI). These are developed through short, time-boxed iterations, allowing for rapid feedback and learning. Agile teams within ARTs integrate these learning cycles for continuous improvement. The roadmap guides the train towards strategic objectives. This iterative approach not only allows for quick response to changing requirements but also promotes a culture of continuous learning and enhancement.

In OpenProject:

- Use **agile boards** and **versions** to plan and execute incremental development cycles
- Create **custom table views** to get an overview of user stories as prioritised by individual ARTs, along with estimated effort and value.
- Leverage the **wiki** feature to document lessons learned and insights gained during each iteration
- Create quality assurance tasks with **custom templates** and **workflows** to track and manage QA issues

## **Base milestones on objective evaluation of working systems**

Milestones with SAFe are based on an objective evaluation of tangible, working systems as a measure of progress. Milestones define key moments in the roadmap for the delivery of specific features or increments. This aligns with Scrum practices, where the emphasis is on delivering working solutions during each sprint. This approach provides transparency and accountability, reinforcing the commitment to delivering outcomes that have a measurable impact on the organisation&#39;s goals.

In OpenProject:

- Use **milestones** in to mark significant achievements and sprint/PI delivery dates
- Attach **progress values to work package status** so that indicators properly reflect reality and allow for objective evaluation against set milestones
- **Generate reports** with **progress** **and aggregate progress tracking** to objectively evaluate completed work against predefined milestones

## **Reduce batch sizes, and manage queue lengths**

Limiting Work in Progress (WIP), reducing batch sizes, and managing queue lengths are key practices that optimise workflow. The Kanban board, which allows teams to visualise user stories and features in the the backlog and on-going planning intervals, becomes a valuable tool for teams within the Agile Release Train. It allows members at each level get a concrete sense of progress and enables efficient pre- and post-PI (Program Increment) planning. By limiting WIP and reducing batch sizes, teams can respond quickly to changing priorities and adapt their work as needed.

In OpenProject:

- Use **Agile boards** and visualisations to track and limit work in progress.
- Set up work packages or tasks with manageable batch sizes and use **priority indications** to manage queue lengths effectively
- Use the **Backlogs** module or **filtered work package tables** to navigate user stories by priority or any number of custom fields unique to your team or project

## **Apply cadence, synchronise with cross-domain planning**

Cadence in SAFe involves establishing a regular rhythm for planning, executing, and delivering work. Agile teams, operating on a predictable cadence, synchronise during Program Increment (PI) planning sessions. These cross-domain planning sessions ensure alignment not only within teams but also with Solution Trains and the overall portfolio backlog, which rovides strategic direction for all levels of the organisation. This synchronisation enhances collaboration, minimises delays, and ensures that the efforts of Agile Release Trains are directed towards achieving overarching business objectives.

In OpenProject:

- Use **time-tracking** features to establish fixed time-boxes (cadence) for iterations
- Leverage **live one-click tracking** allows team members to be confident about time-boxing tasks and planning sessions
- Facilitate cross-domain planning using the **cross-project timeline or Gantt chart**

## **Unlock the intrinsic motivation of knowledge workers**

Unlocking the intrinsic motivation of knowledge workers in SAFe involves creating an environment that fosters autonomy, competence and purpose. Autonomous teams within the ART make decisions about features based on their expertise, contributing to a sense of ownership and responsibility. Opportunities for skill development and continuous learning create an engaging work environment. A clear sense of purpose ensures that teams are motivated to deliver high-quality solutions that align with the organisation&#39;s strategic goals. This allows allows organisations to cultivate a culture of innovation and excellence.

In OpenProject:

- Encourage autonomy by providing team members with access to self-organising **Agile boards**
- Use the **Team planner** module for a clear overview of tasks and responsibilities across projects for each team member
- Encourage team collaboration using **discussion forums**, **document sharing (using Nextcloud or Sharepoint/OneDrive)**, and **wiki** features within OpenProject.
- \[planned\] Use the upcoming **integration with Matrix-based client Element** to facilitate clear communication through integrated messaging features and notifications.

## **Decentralise decision-making**

Secision-making in SAFe is decentralised to empower individual teams to make decisions at the level closest to the work. This principle, supported by Scrum and Kanban practices, recognises that individuals who are closest to the work are often best equipped to make informed choices. This decentralisation of decision-making authority reduces delays compared to a centralised decision-making processes and helps create a culture of trust and accountability. Teams within the Agile Release Train can also respond quicker to changing circumstances, making the process even more agile.

In OpenProject:

- Leverage **user role management** in OpenProject to define roles such as Release Train Engineers, Product Owners, Scrum Masters, etc.
- Assign **specific permissions and responsibilities to each role** to delegate decision-making authority to appropriate levels within the organisation
- Use **dynamic meetings** to schedule regular Inspect and Adapt workshops within OpenProject and link them to relevant epics, features or user stories.
- Use the **discussion forums**, **@mentions** and collaboration features (like **integration with file storage services** like Nextcloud or Microsoft SharePoint/OneDrive) for decentralised communication and decision-making

## **Organise around value**

Organising around value in SAFe involves creating teams that align with value streams. The backlog guides teams in delivering value to the customer and the Solution Train ensures alignment with business goals. The portfolio backlog, prioritised based on value to the end customer or end user, provides strategic direction.

In OpenProject:

- Organise work packages or epics around customer value by quantifying and tracking value per user story or epic (using **custom fields**), focusing on delivering features that provide the most value
- Use **prioritisation features** in OpenProject to ensure that teams are working on items that align with the organisation&#39;s value stream