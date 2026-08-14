---
sidebar_navigation:
  title: Risk management
  priority: 975
description: Learn how to configure and use OpenProject for transparent, repeatable project risk management based on work packages and PM² guidance.
keywords: risk management, risk register, risk log, PM², PM2

---

# Risk management with OpenProject

## Purpose

Risk management helps a project team identify uncertain events early, assess their possible effect on project objectives, agree on responses and review whether those responses work. A shared risk register makes ownership and decisions transparent and helps the team act before a risk becomes an issue.

OpenProject can support this process with existing features such as work package types, custom fields, workflows, saved work package views, relations and project templates. In this setup, each risk is a work package and the filtered work package table is the project's risk register.

This guide separates the one-time setup performed by an administrator from the recurring work performed by project members.

> [!NOTE]
>
> OpenProject does not yet provide a dedicated risk module with automatically calculated inherent and residual risk scores. The setup described here uses currently available configuration options. Planned product improvements are linked in [Planned product improvements](#planned-product-improvements).

## PM² context

[PM²](https://pm2.europa.eu/index_en) is a project management methodology developed by the European Commission and open to all. It treats risk management as a continuous activity throughout the project life cycle. Its artefacts include a **Risk Management Plan**, which defines the approach, and a **Risk Log**, which records and follows individual risks.

Use these official sources alongside this OpenProject configuration guide:

- [PM² resources and Project Management Guide](https://pm2.europa.eu/pm2-resources_en)
- [PM² artefacts, including the Risk Management Plan and Risk Log](https://pm2.europa.eu/pm2-artefacts_en)
- [PM² and PMflex project management with OpenProject](../project-management-pm2-pmflex/)

## Recommended structure

| Risk management concept | OpenProject entity |
| --- | --- |
| Risk register / Risk Log | A saved and shared [work package table](../../user-guide/work-packages/work-package-views/) filtered by type `Risk`; see the [demo Risk Log](https://pm2.openproject.com/projects/pm2-test/work_packages?query_id=91) |
| Individual risk | A [work package](../../user-guide/work-packages/) of type `Risk`; see an [example risk](https://pm2.openproject.com/projects/pm2-test/work_packages/517/activity?query_id=91) |
| Risk owner | Assignee or a user custom field |
| Response action | A child or related work package with an assignee and due date |
| Review trail | Work package activity, comments and status history |
| Standard setup | A reusable [project template](../../user-guide/projects/project-templates/) |

## 1. Administrator setup

The following configuration is normally created once and then reused across projects. Administrators should agree the terminology, scales and workflow with the organization's project management office before configuring them.

### 1.1 Create and activate the `Risk` work package type

Create a work package type named `Risk` under **Administration → Work packages → Types**. Add the fields needed for assessment, response and review to its form. See [work package types](../../system-admin-guide/manage-work-packages/work-package-types/) for configuration details.

Activate the type for the relevant projects under **Project settings → Work packages → Types**. The same project settings also control which custom fields are active in a project; see [project work package settings](../../user-guide/projects/project-settings/work-packages/).

### 1.2 Define risk fields

Create the required fields under **Administration → Custom fields → Work packages**. The following baseline works well for many teams:

| Field | Suggested type | Purpose |
| --- | --- | --- |
| Risk category | List | Groups risks such as schedule, cost, scope, quality, security or external dependency |
| Probability | List | Records likelihood on a shared scale, for example 1–5 |
| Impact | List | Records the effect on project objectives on the same 1–5 scale |
| Risk owner | User | Makes one person responsible for monitoring and coordinating the response |
| Response strategy | List | Records the chosen approach, for example avoid, reduce, transfer/share or accept |
| Response description | Long text | Describes the concrete preventive and contingency actions |
| Next review date | Date | Ensures that the risk is reconsidered at an agreed time |
| Residual probability | List | Records likelihood expected after the response |
| Residual impact | List | Records impact expected after the response |
| Escalation required | Boolean | Flags risks that require a governance decision |

See [custom fields](../../system-admin-guide/custom-fields/) for the available field types and configuration options.

Use one consistent scale across projects. If the organization uses a 1–5 scale, define in the Risk Management Plan what each probability and impact value means. Until calculated fields are available, record the score explicitly or group/filter the register by probability and impact; do not imply that OpenProject calculates `probability × impact` automatically.

### 1.3 Configure statuses and workflows

A small workflow is usually easier to maintain than a highly detailed one. For example:

1. `Identified` – the risk has been recorded but not fully assessed.
2. `Assessed` – probability, impact and owner are agreed.
3. `Response planned` – a response strategy and actions are defined.
4. `Monitoring` – the team is implementing and reviewing the response.
5. `Closed` – the risk no longer requires active monitoring.

Optionally add `Occurred` when a realized risk must be handed over to issue management. Configure statuses under [work package statuses](../../system-admin-guide/manage-work-packages/work-package-status/) and permitted transitions under [work package workflows](../../system-admin-guide/manage-work-packages/work-package-workflows/).

Restrict sensitive transitions where appropriate. For example, only the project manager or risk manager may accept a high risk or close an escalated risk. Configure the corresponding rights under [roles and permissions](../../system-admin-guide/users-permissions/roles-permissions/).

### 1.4 Prepare reusable views and a project template

Create and save at least these shared work package views:

- **Active risk register**: type is `Risk`; status is not closed; show owner, probability, impact, response strategy and next review date.
- **Risks requiring attention**: active risks with a high probability or impact, overdue review date or escalation flag.
- **Closed risks**: type is `Risk`; status is closed; use this view for lessons learned and audits.

The [work package table configuration](../../user-guide/work-packages/work-package-table-configuration/) explains how to add columns, filters, grouping and sorting. A [work package table widget](../../user-guide/projects/project-home/project-widgets/#work-package-table-widget) can also place the active risk register on the project overview.

Finally, include the type, fields, permissions and saved views in a [project template](../../user-guide/projects/project-templates/) so new projects start with the same risk management structure.

## 2. Project member workflow

### 2.1 Identify and record a risk

Create a work package of type `Risk`. Write the subject as a concise cause–event–effect statement, for example: “Because the supplier has not confirmed capacity, hardware delivery may be delayed, which could move the pilot date.”

In the description, record the context, assumptions and affected objectives. Select a category and assign a risk owner. The [create work package guide](../../user-guide/work-packages/create-work-package/) describes the available creation flows.

### 2.2 Assess the risk

The risk owner and relevant specialists agree on probability and impact using the scale defined in the Risk Management Plan. Add supporting evidence in the description or as an attachment, and move the risk to `Assessed` when the assessment is complete.

Prioritize risks consistently. A high score should trigger a timely response and, where defined by the organization's thresholds, escalation to the project manager, Project Owner or steering body.

### 2.3 Plan and assign the response

Select the response strategy and document the intended outcome. Turn concrete actions into child or related work packages, assign each action and give it a due date. Relations preserve traceability between the risk and the work needed to address it; see [work package relations and hierarchies](../../user-guide/work-packages/work-package-relations-hierarchies/).

Record both preventive actions and contingency actions where useful. Preventive actions reduce probability or impact before the event; contingency actions define what to do if it occurs.

### 2.4 Monitor and review

Review active risks regularly in a project meeting or dedicated risk review. For each risk:

1. Check whether probability, impact and assumptions have changed.
2. Review the progress and effectiveness of response actions.
3. Update the next review date.
4. Reassess residual probability and impact.
5. Escalate when a threshold is exceeded or a decision is required.
6. Close risks that no longer require active monitoring.

Use comments for decisions and concise review notes. The work package activity provides a chronological audit trail. See [edit work packages](../../user-guide/work-packages/edit-work-package/) for updating fields, status and comments.

### 2.5 Handle an occurred risk

When the uncertain event happens, it is no longer only a risk. Mark it as `Occurred` if that status is part of the workflow, create or link an issue or task, and carry over the relevant owner, impact, response and due dates. Keep the relation between the original risk and the resulting issue so the decision trail remains visible.

### 2.6 Report and learn

Use the active register and attention view for status reporting. At phase gates and project closure, review closed and occurred risks to identify recurring causes, effective responses and improvements for future project templates or the Risk Management Plan.

## 3. Governance checklist

### Administrator or project management office

- Define probability, impact and escalation scales.
- Configure the `Risk` type, fields, form, statuses and workflows.
- Configure roles and permissions.
- Provide shared views and project templates.
- Review the setup periodically and keep terminology consistent.

### Project manager and project members

- Record risks early and assign one owner.
- Assess risks using the agreed scale and evidence.
- Create assignable, dated response actions.
- Review active risks on a defined cadence.
- Escalate according to thresholds and document decisions.
- Convert occurred risks into traceable issues or tasks.
- Close risks deliberately and capture lessons learned.

## Planned product improvements

The configuration above uses existing OpenProject features. The following roadmap work packages describe possible future enhancements; scope and delivery dates may change:

| Roadmap topic | Work package |
| --- | --- |
| Dedicated risk management module, including inherent and residual assessment, treatments, visualization, workflow and auditability | [#38012 – Risk management](https://community.openproject.org/work_packages/38012) |
| Project-level risk dashboard | [#66721 – Dashboard for Risks](https://community.openproject.org/work_packages/66721) |
| Risk overview widget | [#66489 – Overview widget for Risk module](https://community.openproject.org/work_packages/66489) |
| Calculated custom fields as a basis for automatically calculated risk values | [#28704 – Calculated custom fields from existing fields](https://community.openproject.org/work_packages/28704) |
| Status-dependent required fields and validation rules | [#68886 – Dynamic validation](https://community.openproject.org/work_packages/68886) |
| Automatically triggered custom actions | [#37473 – Workflow automation](https://community.openproject.org/work_packages/37473) |
| Two-dimensional boards as a possible basis for matrix-style views | [#75445 – 2D boards](https://community.openproject.org/work_packages/75445) |

