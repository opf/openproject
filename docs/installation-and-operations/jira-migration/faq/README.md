---
sidebar_navigation:
  title: FAQ
  priority: 1
description: Frequently asked questions about migrating from Jira Data Center to OpenProject with the Jira Migrator.
keywords: Jira migration FAQ, Jira Migrator, Jira Data Center, OpenProject migration, migration support
---

# Frequently asked questions about Jira migration

This page helps decision-makers assess how OpenProject can provide a sustainable alternative to Jira and how to approach a migration. OpenProject focuses on clear, integrated product and project management concepts in one platform instead of reproducing the full complexity of Jira and its app ecosystem.
The questions below provide a starting point for a detailed fit-gap analysis. Please [reach out to our experts](https://www.openproject.org/contact/) for personalized guidance on your Jira migration.

> [!IMPORTANT]
> Current product and migration capabilities on this page refer to OpenProject 17.6. The Jira Migrator is in beta and should only be used in test setups. Items on the [OpenProject roadmap](https://www.openproject.org/roadmap/) reflect our current development plans and priorities. While we are committed to delivering them, scope, status and target delivery dates may change.
> 
## Is OpenProject proven in large organizations?

Yes. Many large organizations have been using OpenProject successfully for years. References and major deployments include Deutsche Bahn, Mercedes-AMG, Samsung, 3M, Charité, the German Federal Ministry for Digital Transformation and Government Modernisation (BMDS), and the [International Criminal Court (ICC)](https://www.openproject.org/blog/digital-sovereignty-government-germany-opendesk/) through openDesk.

OpenProject is trusted by organizations across government and public administration, healthcare, transportation, manufacturing, automotive, research and higher education, energy, IT, and consulting. It is increasingly adopted by public sector organizations pursuing digital sovereignty, open standards, and vendor independence. The [OpenProject customer overview](https://www.openproject.org/customers/) provides further examples across industries and geographies.

OpenProject is also currently undergoing an extensive security assessment as part of openDesk for use in highly security-sensitive organizations. This work goes beyond a standard functional evaluation and examines the software and its operation against the requirements of such environments.

## Can OpenProject users be forced into a cloud migration?

No. Organizations using OpenProject are not facing the specific problem created by the [announced end of life of Jira Data Center on March 28, 2029](https://www.atlassian.com/licensing/data-center): they do not have to move to a proprietary cloud simply because the vendor discontinues its self-hosted product. With OpenProject, organizations can operate the open source software in infrastructure they control and decide how and when to update it. Enterprise subscriptions add professional support and service levels without taking away that control and operational independence.

OpenProject has a long-standing track record in demanding enterprise environments, enabling customers to retain control over their infrastructure and deployment instead of being forced into a cloud migration due to a single vendor's product end-of-life decision.

## Why should European organizations carefully reconsider a move to Atlassian Cloud?

Atlassian Cloud can be appropriate for many organizations, but an EU data location alone does not provide complete legal or operational sovereignty. Atlassian Corporation is incorporated in Delaware, has its principal executive offices in San Francisco and is listed on Nasdaq, as documented in its [SEC annual report](https://www.sec.gov/Archives/edgar/data/1650372/000165037225000036/team-20250630.htm). The stock-market listing demonstrates the company's strong US regulatory connection, but the more relevant issue for data access is that the provider is subject to US jurisdiction.

Under the [US CLOUD Act](https://www.justice.gov/criminal/media/999391/dl?inline=), a provider subject to US jurisdiction can be required through valid legal process to preserve or disclose data within its possession, custody or control, regardless of whether the data is stored inside or outside the United States. This is not unrestricted government access, and providers can scrutinize or challenge requests in defined circumstances. Nevertheless, storing data in an EU or German region does not by itself remove the legal access path. Atlassian offers [EU and German data-residency locations](https://www.atlassian.com/software/data-residency), while also noting that data residency is not available uniformly for every Marketplace app.

Some US legal processes can also restrict or delay customer notification. For example, [18 U.S.C. § 2709](https://www.law.cornell.edu/uscode/text/18/2709) permits nondisclosure requirements for certain National Security Letters when the statutory conditions are met, and [18 U.S.C. § 2705](https://www.law.cornell.edu/uscode/text/18/2705) provides for delayed or prohibited notice in specified investigations. Atlassian's own [transparency report](https://www.atlassian.com/trust/privacy/transparency-report) confirms that the company receives US government requests and, after legal review, has disclosed user or account data in response to some requests.

The practical risk depends on the organization and its data. For many ordinary business use cases, the likelihood of a relevant US access request may be low. For governments, critical infrastructure, financial institutions, healthcare organizations, and companies handling strategically sensitive information, however, the jurisdictional dependency itself can be material. The [European Commission's Cloud Sovereignty Framework](https://commission.europa.eu/news-and-media/news/sovereign-cloud-framework-explained-2026-06-01_en) therefore treats exposure to non-EU laws with cross-border reach, including the US CLOUD Act, as a distinct sovereignty criterion.

A self-hosted OpenProject deployment provides a different risk model: the organization chooses and controls the infrastructure, retains the software and the source code, and is not operationally dependent on a proprietary US SaaS provider. Each organization should still assess its complete infrastructure and supplier chain and obtain legal advice for its specific regulatory and threat model.

## Is OpenProject a one-to-one replacement for Jira?

OpenProject is not intended to be a one-to-one copy of Jira. This is an important advantage: organizations can replace a complex combination of Jira products and apps with a more consistent platform and simplify complex processes that have grown over time.

OpenProject combines [work packages](../../../user-guide/work-packages/), [agile boards](../../../user-guide/agile-boards/), [backlogs and sprints](../../../user-guide/backlogs-scrum/), [Gantt charts](../../../user-guide/gantt-chart/), [portfolios](../../../user-guide/portfolios/), [team planning](../../../user-guide/team-planner/), [time and cost tracking](../../../user-guide/time-and-costs/), [meetings](../../../user-guide/meetings/), [documents](../../../user-guide/documents/) and a [project wiki](../../../user-guide/wiki/). It is particularly attractive to organizations that value data sovereignty, self-hosting, open source, or EU-based cloud hosting.

A successful decision should be based on business processes and outcomes rather than identical screens or configuration objects. Organizations with many Jira workflows, schemes, marketplace apps or custom scripts should use a fit-gap analysis to identify where OpenProject can cover the underlying need with a simpler approach.

## What should we analyze before deciding to replace Jira?

Start with an inventory of the Jira environment and identify:

- Jira products, versions, projects, issue counts and attachment volumes
- Issue types, fields, workflows, permissions, security schemes, boards, filters and dashboards
- Marketplace apps, custom scripts, automations and integrations
- Regulatory, accessibility, hosting, data residency, support and availability requirements
- Reports and processes that are business-critical at go-live

For every requirement, distinguish between a legal or operational necessity, a valuable convenience and a historical configuration that is no longer needed. This analysis often reveals opportunities to reduce fields, workflows, schemes and apps. Classify each requirement as available, configurable, replaceable through another approach, planned, or currently a gap.

## Is the Jira Migrator ready for a production migration?

In OpenProject 17.6, the Jira Migrator is a beta feature intended for test setups. It already provides a practical way to analyze real Jira data, validate mappings and estimate the remaining migration work. A production cutover should follow only after a tested migration plan, backups, acceptance criteria and a rollback approach have been established.

Each import run enters a review mode and can be approved or reverted. After approval, the import can no longer be reverted. See the [Jira migration guide](../) for the current process and limitations.

## Which Jira versions can currently be imported?

OpenProject 17.6 supports Jira Data Center 10.x and 11.x. Jira Server and Jira Cloud are not supported yet. If Jira Cloud is part of the scope, treat migration as a separate workstream and verify the latest status on the [Jira Migrator stream](https://community.openproject.org/projects/JIM) and the [OpenProject roadmap](https://www.openproject.org/roadmap/). Jira Server might be supported in the near future. It is tracked by [this ticket](https://community.openproject.org/projects/JIM/work_packages/JIM-160/activity).

## Which data can OpenProject 17.6 import automatically?

The documented scope already includes the central foundation for a realistic migration test:

- Projects and project identifiers
- Issues and selected standard attributes, including subject, description, attachments, due date, estimated hours and remaining hours
- [Project-based issue identifiers](../../../system-admin-guide/manage-work-packages/work-package-identifiers/)
- Supported custom fields
- Users with names, email addresses and project memberships
- Statuses and types

Review the [Jira migration guide](../) and [custom fields migration guide](../custom-fields/) for the authoritative scope of the OpenProject version used for the migration. Test representative projects because data quality and Jira configuration can affect the result.

## Which Jira data is not yet migrated automatically?

The Jira Migrator is being expanded iteratively. OpenProject 17.6 does not yet migrate every Jira configuration object or all ecosystem data. Important areas requiring particular attention include relations between issues, sprint assignments, versions, components, project-level workflows, permissions, schemes, boards, filters, dashboards, time logs, and data owned by marketplace apps.

Several of these areas are represented by roadmap items, including:

- [Relations between work items](https://community.openproject.org/projects/JIM/work_packages/JIM-43/activity)
- [Sprint assignments](https://community.openproject.org/projects/JIM/work_packages/JIM-44/activity)
- [Affected and fix versions](https://community.openproject.org/projects/JIM/work_packages/JIM-154/activity)
- [Jira components](https://community.openproject.org/projects/JIM/work_packages/JIM-107/activity)
- [Preserving references after a separate Confluence-to-XWiki migration](https://community.openproject.org/projects/JIM/work_packages/JIM-129/activity). This does not include migrating Confluence content.

Roadmap inclusion does not mean that a capability is available in the version being evaluated. Verify the current status of each required item.

## Why should we not reproduce the Jira configuration exactly?

Jira environments often accumulate issue types, fields, workflows and schemes over many years. A migration provides an opportunity to simplify this configuration and improve the experience for administrators and end users.

OpenProject's product direction is to make important concepts easier to understand and configure instead of reproducing Jira's combination of workflow schemes, screen schemes and related configuration layers. The planned [type variants](https://community.openproject.org/projects/FND/work_packages/FND-25/activity) are a good example: they are intended to provide project-specific workflows and form configurations through a lighter model that is easier to manage.

Define a clear set of target processes first and then map Jira data into that design. Existing [OpenProject workflows](../../../system-admin-guide/manage-work-packages/work-package-workflows/) can be configured and validated independently of the migration. Type variants remain a roadmap item until they are released, but they illustrate the goal of achieving a better user experience through simpler concepts.

## How will automation and workflow configuration evolve?

Automation is a major development priority for OpenProject, and we are working intensively to expand it. The new automation capabilities will build on [custom actions](../../../system-admin-guide/manage-work-packages/custom-actions/), which already provide a structured way to apply defined changes to work packages. The planned [workflow automation](https://community.openproject.org/projects/FND/work_packages/FND-10/activity) will extend this foundation with automatically triggered actions.

We also plan to provide a [visual workflow editor](https://community.openproject.org/projects/stream-jira-exit/work_packages/36241/activity) that represents workflows and automations as nodes and edges. This will make complex processes easier to understand, configure and review. The [first UX improvements to the workflow administration](https://community.openproject.org/projects/FND/work_packages/FND-24/activity) have already been completed and provide the foundation for the next steps.

A major focus of this development will be the integration of agentic AI. The goal is to enable AI agents to use clearly defined workflow and automation capabilities to support multi-step processes while respecting OpenProject's roles, permissions and process rules. The planned expansion of the [OpenProject MCP server with write capabilities](https://community.openproject.org/projects/AI/work_packages/73261/activity) is an important building block for this direction.

## Are Jira issue keys and links preserved?

The Jira Migrator supports project-based semantic issue identifiers, allowing imported work packages to retain recognizable project keys and issue numbers where possible. This is important for references in source code, emails and documentation.

Nevertheless, test all link types. Raw URLs, app-specific links, links created by scripts, and references from Jira issues to Confluence pages may require additional migration or redirects. A separate [roadmap item](https://community.openproject.org/projects/JIM/work_packages/JIM-129/activity) concerns transforming these references after Confluence content has been migrated independently to XWiki; it does not migrate the Confluence content itself.

## How are Jira custom fields handled?

The Jira Migrator supports a broad set of commonly used Jira field types, including text, number, date, list, checkbox, URL, user, labels and cascading-select fields. It also handles several Jira field-context scenarios. This provides a good basis for testing real projects while avoiding the automatic transfer of unused configuration. Unused fields may be ignored, and unsupported field types are skipped.

Fields created by marketplace apps require special attention because their values and configuration may not be exposed like regular Jira custom fields. Build a field inventory, identify the owning app and test representative values. See [custom fields migration](../custom-fields/) for supported types and detailed mapping rules.

## How are users, groups, roles and permissions migrated?

The current import covers user names, email addresses and project memberships. Newly created users remain locked while the import is in review and are activated when the import is approved.

Jira roles, permission schemes, issue-security schemes and directory configuration are not reproduced automatically. This enables organizations to design a clearer target model using OpenProject's [roles and permissions](../../../system-admin-guide/users-permissions/roles-permissions/) and [groups](../../../system-admin-guide/users-permissions/groups/). Validate identity matching, inactive users, former employees, external users, groups, fallback ownership and access to sensitive issues before cutover.

## How should we approach a large or complex Jira instance?

Several measured test migrations provide a reliable basis for planning a large cutover. Migration duration can depend on Jira API performance, rate limits, OpenProject capacity, data inconsistencies and attachment volume. Old data may also violate today's Jira or OpenProject configuration rules.

Begin with a representative set of projects: one standard project, one highly customized project, one large project and one project using important marketplace apps. Record import duration, warnings, rejected objects, manual corrections and validation results. Use these results to estimate the full migration and decide which historical data should be archived rather than migrated.

See also our blog post on [Jira migration strategies](https://www.openproject.org/blog/jira-migration-strategies/).

## Can OpenProject replace Jira Software for Scrum, Kanban and SAFe?

Yes. OpenProject 17.6 provides [agile boards](../../../user-guide/agile-boards/) as well as [backlogs and sprints](../../../user-guide/backlogs-scrum/) with sprint planning and sprint boards. A particular strength is the combination of agile work with [work-package hierarchies and relations](../../../user-guide/work-packages/work-package-relations-hierarchies/), [Gantt charts](../../../user-guide/gantt-chart/) and [portfolio structures](../../../user-guide/portfolios/). This makes it possible to connect agile delivery with classic planning and governance in one system.

The roadmap includes further Jira-oriented capabilities such as work-in-progress limits, sprint reports, burndown and velocity charts, multiple active sprints, board swimlanes and cumulative-flow diagrams. Organizations using Advanced Roadmaps, extensive board automation or SAFe can use the documented [SAFe use case](../../../use-cases/safe-framework/) as a starting point and should model their real planning events, metrics, dependencies and cross-team views in a pilot.

## Can OpenProject replace Jira Service Management?

OpenProject already provides a solid foundation for modeling requests, incidents, changes and other service records through [work packages](../../../user-guide/work-packages/), [workflows](../../../system-admin-guide/manage-work-packages/work-package-workflows/), custom fields and [notifications](../../../user-guide/notifications/). OpenProject 17.6 does not yet cover the complete Jira Service Management feature set. Closing these gaps is part of the OpenProject product roadmap, and we will continue to expand our service management capabilities in future releases.

The roadmap includes incoming-email improvements, a [service portal](https://community.openproject.org/projects/SISMI/work_packages/71021/activity), [asset management](https://community.openproject.org/projects/SISMI/work_packages/67364/activity) and [service level agreements](https://community.openproject.org/projects/SISMI/work_packages/74193/activity). Evaluate customer portals, queues, SLAs, assets, knowledge articles, email processing, approvals and reporting separately. Planned features are not a substitute for a tested go-live requirement.

## What is the alternative to Xray or Zephyr test management?

Test management processes can already be modeled with work-package types, workflows, relations and views, as shown in the [OpenProject test management use case](../../../use-cases/test-management/). A dedicated [test management roadmap](https://www.openproject.org/roadmap/#xray-alternative) covers test cases, executions, results, traceability and reporting. Work on the [Squash TM integration](https://community.openproject.org/projects/SSOI/work_packages/SSOI-1/activity) has already started.

There is no generic migration of Xray or Zephyr data in OpenProject 17.6. Inventory test cases, steps, executions, plans, evidence, automation results and requirement links. Decide whether they should be modeled in OpenProject directly, moved to a specialized test management system, or retained in an archive.

## How does OpenProject support portfolio and program management?

OpenProject brings operational project work and strategic oversight together. [Portfolios and programs](../../../user-guide/portfolios/) organize projects in a hierarchy, while [work-package hierarchies and relations](../../../user-guide/work-packages/work-package-relations-hierarchies/) and [Gantt charts](../../../user-guide/gantt-chart/) make milestones, dependencies and schedules visible. This integrated model can reduce the need for separate hierarchy and roadmapping apps and gives decision-makers a consistent view from portfolio objectives to delivery work.

The [portfolio and program management roadmap](https://www.openproject.org/roadmap/#portfolio-management) extends this foundation with project intake, scoring, portfolio monitoring, governance and reporting. Organizations using Advanced Roadmaps, BigPicture or Structure should validate their representative hierarchies, prioritization criteria, dependencies, scenarios and management reports.

## How does OpenProject support resource and capacity management?

[Team planners](../../../user-guide/team-planner/) provide a visual view of assigned work and help teams coordinate workloads within projects. Resource planning remains connected to the underlying work packages, schedules and responsibilities instead of being maintained in a disconnected planning layer. OpenProject 17.7 will release a dedicated resource management module in OpenProject.

The [resource and capacity management roadmap](https://www.openproject.org/roadmap/#big-picture-alternative) includes cross-project resource planning, capacity visibility and workload balancing. [Multi-project resource management](https://community.openproject.org/projects/OP/work_packages/OP-6038/activity) is still a roadmap item. Organizations using Tempo Planner, BigPicture or similar apps should validate planning granularity, skills and roles, availability, allocations, scenarios and capacity reports against the current release and the roadmap.

## How does OpenProject support time and cost management?

OpenProject includes [time tracking, labor and unit costs, and cost reporting](../../../user-guide/time-and-costs/) as well as [project budgets](../../../user-guide/budgets/). Because time, cost, budget and work-package information share one data model, teams can compare effort and expenditure with the work that produced them without relying on a separate marketplace app.

Organizations using Tempo Timesheets or specialized financial extensions should validate approvals, locked periods, billable classifications, account structures, rates, exports and planned-versus-actual reporting. The built-in capabilities provide a strong foundation, while highly specialized accounting or payroll processes may still be better served by an integration with the relevant financial system.

## Does OpenProject include a wiki, and what should we use instead of Confluence?

Yes. The [OpenProject wiki](../../../user-guide/wiki/) is an integrated module that can be enabled for individual projects with just a few clicks. No separate wiki installation or additional service is required. Teams can create structured project documentation, maintain a page history, use macros and link project information directly from the wiki. The module is available in the Community edition and does not require an Enterprise subscription.

The integration between work packages and wiki pages is also included in the Community edition. Users can [link a work package to an existing wiki page or create a new wiki page](../../../user-guide/work-packages/edit-work-package/#link-to-or-create-a-wiki-page) directly from the work package. Wiki pages can also include dynamic work package tables and Gantt charts. This close integration is particularly useful when requirements, decisions or other project documentation need to remain connected to operational work.

OpenProject does not support migrating Confluence content, and a Confluence content migrator is not planned as part of the Jira Migrator. Organizations that want to replace both Jira and Confluence should evaluate the combination of OpenProject and XWiki. OpenProject provides a dedicated [XWiki integration](../../../system-admin-guide/integrations/xwiki/) that connects project management and knowledge management. Any migration of Confluence spaces, pages, permissions, macros, attachments and diagrams to XWiki needs to be planned separately.

## How are important Jira marketplace apps covered?

OpenProject includes many capabilities directly that Jira environments commonly add through marketplace apps. Examples include agile and classic project management, Gantt charts, portfolios, time and cost tracking, team planning, meetings, documents and the project wiki. Organizations can therefore reduce not only the subscription or license costs for Jira Core or Jira Data Center, but also the recurring costs of multiple marketplace apps. The actual savings depend on the Jira edition, app portfolio, number of users, hosting model and selected OpenProject Enterprise subscription.

Core integration provides another important advantage. These capabilities share OpenProject's data model, permissions, user experience and release cycle. This generally provides a more consistent experience and reduces compatibility issues, duplicated configuration and upgrade dependencies between the platform and multiple app vendors.

This creates an opportunity to consolidate the application landscape and reduce configuration dependencies. Jira apps are not migrated as installable units, so their business purpose, data and automation must still be assessed individually. The following table gives each important app or closely related Atlassian product its own row.

| Jira app or product | OpenProject approach | What to validate |
| ------------------- | -------------------- | ---------------- |
| ScriptRunner | OpenProject provides [workflows](../../../system-admin-guide/manage-work-packages/work-package-workflows/), [custom actions](../../../system-admin-guide/manage-work-packages/custom-actions/), an [API and webhooks](../../../system-admin-guide/api-and-webhooks/). ScriptRunner use cases have been [analyzed on the roadmap](https://community.openproject.org/projects/FND/work_packages/FND-51/activity), and [automatically triggered custom actions](https://community.openproject.org/projects/FND/work_packages/37473/activity) are planned. There is no source-compatible script migration. | Inventory scripts, listeners, validators, conditions, scheduled jobs, scripted fields and queries. Decide whether to configure, integrate, reimplement or retire each use case. |
| JMWE | Workflows, custom actions, the API and webhooks cover many workflow-extension use cases without reproducing Jira workflow schemes. | Validate every post function, condition, validator, scheduled action and cross-project automation. |
| JSU Automation Suite | Workflows, custom actions, the API and webhooks provide the foundation for workflow automation. | Identify triggered updates, linked-issue actions, calculations and app-specific data that need configuration or custom integration. |
| Jira Workflow Toolbox | OpenProject workflows and custom actions support structured process configuration; API-based extensions can cover additional logic. | Review calculated fields, expressions, validators, post functions and dependencies on Jira-specific context. |
| Tempo Timesheets | OpenProject includes [time tracking](../../../user-guide/time-and-costs/), labor and unit costs, cost reports and [budgets](../../../user-guide/budgets/). | Validate approvals, locked periods, billable classifications, accounts, rates, financial exports and planned-versus-actual reports. |
| Tempo Planner | [Team planners](../../../user-guide/team-planner/) support visual workload coordination. Broader cross-project resource and capacity management is on the roadmap. | Validate availability, allocation granularity, roles, skills, scenarios, calendar suggestions and capacity reports. |
| BigPicture | [Portfolios and programs](../../../user-guide/portfolios/), [Gantt charts](../../../user-guide/gantt-chart/), work-package relations and team planners cover integrated portfolio and delivery planning. | Rebuild representative programs, dependency networks, scenarios, program increments, capacity views and reports. |
| Structure | Portfolios, project hierarchies and [work-package hierarchies and relations](../../../user-guide/work-packages/work-package-relations-hierarchies/) provide structured views across projects and work. | Validate dynamic hierarchies, grouping rules, formulas, generators and structure-specific reports. |
| Advanced Roadmaps | Portfolios, Gantt charts, backlogs and work-package relations connect strategic planning with agile delivery. | Validate cross-team plans, scenarios, dependencies, capacity assumptions, releases and roadmap reports. |
| Xray | Tests can be modeled with work packages today, as described in the [test-management use case](../../../use-cases/test-management/). Dedicated test-management capabilities are on the roadmap, and work on the [Squash TM integration](https://community.openproject.org/projects/SSOI/work_packages/SSOI-1/activity) has started. | Validate test steps, executions, evidence, traceability, automation imports, coverage and audit reports. Xray-owned data is not migrated automatically. |
| Zephyr | OpenProject work packages can model test processes, while dedicated test-management capabilities and the Squash TM integration extend the future approach. | Validate test cases, cycles, executions, evidence, automation results and requirement links. Zephyr-owned data is not migrated automatically. |
| eazyBI | Configurable [work-package views](../../../user-guide/work-packages/work-package-views/), dashboards, [exports](../../../user-guide/work-packages/exporting/) and the API provide reporting data. Specialized analytics can be implemented in an external BI solution. | Inventory decision-critical metrics, calculations, cubes, data sources, refresh intervals and permission rules. |
| Rich Filters for Jira Dashboards | OpenProject offers configurable work-package views, filters and dashboards for operational reporting. | Recreate representative filters, dashboard controls, calculated metrics and audience-specific views. |
| Custom Charts for Jira | OpenProject dashboards and filtered work-package views cover many common visual reporting needs; specialized charts may require an external BI solution. | List every chart, aggregation, filter interaction and scheduled report that supports a decision. |
| Power BI Connector for Jira | OpenProject data can be provided to external analytics solutions through [exports](../../../user-guide/work-packages/exporting/) and the [API](../../../system-admin-guide/api-and-webhooks/). | Validate the data model, transformations, refresh process, incremental loading, permissions and existing Power BI reports. |
| Jira Service Management | Requests, incidents and changes can be modeled with work packages and workflows. A service portal, incoming-email improvements, asset management and SLAs are roadmap topics. | Test portal access, queues, email channels, approvals, knowledge management and customer reporting against the required service processes. |
| Assets | Assets can currently be represented through work packages, types, relations and custom fields. A dedicated asset-management module is on the roadmap. | Validate object schemas, relationships, discovery, imports, permissions, history and service-workflow integration. |
| Time to SLA | Service level agreements are a roadmap topic for OpenProject and should not yet be treated as an available equivalent. | Validate calendars, goals, start and pause rules, escalations, historical calculations and SLA reports. |
| Xporter | OpenProject supports [work-package and table exports](../../../user-guide/work-packages/exporting/), including PDF and common data formats, with configurable [PDF styling](../../../system-admin-guide/design/pdf-export-styles/report/) available through Enterprise subscriptions. | Compare templates, batch generation, scheduled delivery, conditional content, signatures and regulatory document requirements. |
| GitHub for Jira | OpenProject provides a documented [GitHub integration](../../../system-admin-guide/integrations/github-integration/) that connects pull requests to work packages. | Test links between commits, branches, pull requests and work packages, including permissions and automation. |
| GitLab for Jira | OpenProject provides a documented [GitLab integration](../../../system-admin-guide/integrations/gitlab-integration/) that connects merge requests to work packages. | Test links between commits, branches, merge requests and work packages, including permissions and automation. |
| Bitbucket integration | OpenProject provides an API and webhooks, but a Bitbucket-specific integration may require custom implementation. | Document required repository events, links, permissions, deployment information and automation before designing the integration. |
| draw.io Diagrams for Jira | Diagrams can be attached to or linked from work packages, documents and wiki pages, but app-specific diagram editing and data are not migrated automatically. | Select the target diagram format and editor, and test editing, previews, permissions, attachments and long-term maintainability. |
| Confluence | The integrated [OpenProject wiki](../../../user-guide/wiki/) supports project documentation. For replacing Confluence, OpenProject recommends combining OpenProject with [XWiki](../../../system-admin-guide/integrations/xwiki/). | Plan the Confluence-to-XWiki migration separately, including spaces, pages, permissions, macros, attachments, diagrams and references to Jira issues. |

OpenProject's integrated approach may cover a business need differently and more simply than the existing combination of Jira and apps. Use production examples and real data to confirm how well this approach delivers the required outcome.

## Can we develop our own plugins for OpenProject?

Yes. OpenProject is designed to be extended, and its open source architecture makes it straightforward for development teams to create their own plugins. Organizations have access to the complete source code and are not limited to the extension points of a closed platform. A [plugin development guide](../../../development/create-openproject-plugin/), an OpenProject plugin generator and the [OpenProject proto plugin](https://github.com/opf/openproject-proto_plugin) provide practical starting points for adding organization-specific functions and integrations.

Plugins can extend backend and frontend functionality and can be [installed as part of a self-hosted OpenProject deployment](../../configuration/plugins/). As with any extension that runs inside a business application, organizations should test it against the intended OpenProject version and plan ownership, security reviews, upgrades and maintenance.

We have also started planning a dedicated CI/CD infrastructure for OpenProject extensions. The goal is to standardize scaffolding, building, automated testing, packaging and deployment so that the first steps in developing and operating an extension become as simple and repeatable as possible. This infrastructure is planned and should not yet be treated as an available service.

## What are the advantages of OpenProject as an open source application?

OpenProject represents a paradigm shift: the software is not a closed product controlled exclusively by one vendor. The [Community edition is free and open source](https://www.openproject.org/download-and-installation/), and its [source code is publicly available](https://github.com/opf/openproject). In this practical sense, the software belongs in the hands of its users: organizations can inspect it, operate it in their own infrastructure, retain control of their data, adapt it and continue using it independently. This reduces vendor lock-in and creates long-term choice over hosting, operations and service providers.

OpenProject does not sell licenses for the open source application. Its commercial offering consists of Enterprise subscriptions that provide additional services and capabilities. The developers of OpenProject offer [individual consulting](https://www.openproject.org/training-and-consulting/#consulting) and Enterprise support with [guaranteed availability and resolution times based on an SLA](../../../enterprise-guide/support/). The Enterprise edition of OpenProject is also fully open source. Organizations can therefore combine software freedom and data sovereignty with professional support and defined service levels.

## How quickly is OpenProject evolving?

OpenProject delivers feature releases on a monthly cadence, complemented by maintenance releases when needed. The project does not ask decision-makers to rely on promises alone: the [public roadmap](https://www.openproject.org/roadmap/) exposes recently delivered, current and planned development down to individual work packages, while the [release notes](https://www.openproject.org/docs/release-notes/) document what was actually shipped and when.

Together, the regular releases and the ability to compare plans with delivered functionality provide a strong, verifiable track record of turning commitments into working software. Roadmap dates and scope can still change, so decisions that depend on a future capability should always use the current roadmap status and release notes as evidence.

## What is the best first step for evaluating OpenProject?

The following path provides a quick way to experience OpenProject and build evidence for a migration decision:

1. Start a [free OpenProject trial](https://start.openproject.com/) without setting up infrastructure.
2. Alternatively, install the free [Community edition in your own infrastructure](../../installation/) to evaluate self-hosting, operations and data control.
3. Perform a [test migration](../) with representative Jira projects and review the imported data, workflows and user experience with the future users.
4. Contact the [OpenProject consulting team](https://www.openproject.org/training-and-consulting/#consulting) for a personal discussion of requirements, target processes and migration options.

The Cloud trial and Community installation are two alternative starting environments; either can be followed by a test migration and a structured evaluation with the relevant stakeholders.
