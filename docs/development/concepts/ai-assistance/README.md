---
sidebar_navigation:
  title: AI Assistance
description: How the AI Assistance menu, its assistants and skills, and the health check work, and how this change is split for review
keywords: AI, assistants, skills, health check, automations, LLM
---

# Development concept: AI Assistance

The "AI Assistance" menu on the work package page offers skills, for example "Check health". A skill finds problems in a work package. It can propose a change set, and the user applies the change set or dismisses it. Every run starts with a click, uses the permissions of the user who clicked, and writes nothing until that user applies a change set.

This document describes the design. It also shows how the first pull request is split into smaller pull requests for review.

## Terms

| Term | Meaning |
|---|---|
| **Assistant** | A record (`AI::Assistant`) that an admin configures: a name, an icon and an optional model. It is not a user. In the menu, its name is the label next to each of its skills, for example "QA assistance". |
| **Skill type** | Code that defines what a skill does: its rules, the message its AI review sends, and the answer schema. It is registered in `AI::AssistantSkills::Registry`. The first one is `health_check`. |
| **Skill** | A record (`AI::AssistantSkill`) that attaches a skill type to an assistant, with its label, its prompt (instructions and output rules) and its proposal scope. |
| **Run** | One execution of a skill on one work package for one user (`AI::AssistantRun`). Only that user sees it. |
| **Finding** | One problem that a run found (`AI::AssistantRunFinding`). It has a severity, an area, a text, evidence, and an optional fix. |
| **Change set** | A proposed change in the Automations action vocabulary: a target (only `self` for now) and a list of actions with values, for example `{"target": "self", "actions": [{"key": "description", "values": ["…"]}]}`. Which action keys a change set may use depends on the skill type and its proposal scope (see "Proposal scope and changeable attributes"). The user applies the change set through the Automations services. |

## Flow

```mermaid
flowchart LR
  U([User]) -->|click| M["AI Assistance menu<br/>(Primer ActionMenu, deferred)"]
  M -->|POST runs| RS["RunService"]
  RS -->|in the request| R["Rules<br/>(tree, relations, PRs, staleness)"]
  RS -->|LLM available| J["JudgementJob<br/>(as the user)"]
  J --> LLM["LlmConnection<br/>(structured output)"]
  R --> F[("Findings")]
  J --> F
  F --> D["Run dialog<br/>(polls while the job runs)"]
  D -->|Apply changes| A["ApplyProposalService"]
  A -->|strict, lockVersion| AU["Automations::UpdateWorkPackageService"]
  AU --> WP["Work package<br/>+ journal cause"]
```

1. The Angular toolbar (full view and split view) loads `WorkPackages::AIAssistance::MenusController#show` into a turbo frame. A user without the permission gets an empty frame.
2. The menu items are loaded when the menu opens (`#items`). There is one flat item for each active skill of each active assistant, and a "History" item at the end.
3. An item posts to `RunsController#create`. `AI::AssistantRuns::RunService` stores the run, runs the rules in the user's locale, and opens the run dialog.
4. If `LlmConnection.available?` and a model is set, the run gets the status `ai_running` and `AI::AssistantRuns::JudgementJob` starts. The dialog polls `#poll` until the run is finished.
5. The user applies a change set (`FindingsController#apply`) or dismisses a finding, with an optional reason.

## Decisions

- **Assistants are records, not users.** A run always acts with the permissions of the user who started it. The job runs in `User.execute_as(run.user)`.
- **Rules and AI are separate.** The rules are deterministic, need no LLM, and always run. The AI review is optional. If it is not available or fails, the run lists it under "Not checked", and the rule findings stay.
- **What the AI reads.** It reads only what the user can see: the work package, visible descendants and relations, and comments filtered by `journals.internal_visible`. Internal comments are included only when the user may see them. The prompt tells the model that this text is user data, not instructions.
- **Evidence is required.** An AI finding without evidence is dropped. Findings and evidence are shown as escaped text. Only `http(s)` URLs and work package ids become links.
- **Change sets are Automations actions.** `AI::AssistantRuns::ApplyProposalService` looks up each action key in `Automations::Register` and refuses keys that the skill type does not declare. For the health check, these are the new `Automations::Actions::Subject` and `Automations::Actions::Description`. It calls `Automations::UpdateWorkPackageService` with `strict: true`, so an invalid action fails the call instead of being dropped.
- **Conflicts use a strict `lockVersion`.** Each finding stores the work package version from which it was made (`base_lock_version`). If the work package changed after that, the apply fails and the user runs the check again. After a successful apply, the other open findings of the same run move to the new version, so a second change set from the same run can apply.
- **Content guard.** A description change that removes an attachment reference, a mention or a macro cannot be applied (`AI::AssistantRuns::ContentGuard`).
- **One AI job at a time** for each user, work package and skill. A second click opens the run that is in progress. An AI review that runs for more than 10 minutes is marked as timed out.
- **Journal cause.** Each applied change set writes `Journal::CausedByAssistantSkill`, with `source` and `depth` for the loop protection of a later trigger model. The activity tab shows "AI Assistance: proposed by … and applied by the user".
- **Automations stay the write layer.** Existing Automations do not change. The only change that admins can see is the two new action types.

## Prompts

The prompt is data, not code. OpenProject ships no prompt text. Each skill stores:

- **Instructions** (`prompt`): what the model checks. Without instructions, the skill runs only its rules, and the run lists the AI review as "Not checked".
- **Output rules** (`output_rules`): how the model answers, for example the language, the changes, and what to do with user text. `{{locale}}` becomes the locale of the user who starts the run.
- **Template** (`template_ref`): the template in a separate prompt registry that the skill was created from. Nothing reads it yet. A later sync from the registry uses it.

The code keeps what is a contract between OpenProject and the model: the message (`HealthCheck::Judgement#user_message`), the answer schema, and the checks on the answer.

## Chat

The chat is a skill type (`AI::AssistantSkills::Chat::Skill`, key `chat`). An admin adds it to an assistant like any other skill, and the menu shows it among the skills. It opens a private conversation for each user, work package and skill (`ai_assistant_chats.skill_id`, `ai_assistant_chat_messages`), not a run. "New chat" starts an empty one.

- **Prompt:** the skill's instructions, output rules and proposal scope. The model is the assistant's model. Without instructions, the chat is not offered.
- **What the model gets:** the instructions and output rules, the same work package context as the health check (`AI::AssistantRuns::WorkPackageContext`) with `change_options`, and the last 20 turns.
- **Answer:** structured output with `answer` (Markdown, rendered with the normal text formatting) and `changes`. The changes become a proposal in the same shape as a finding's change set (`AI::Proposal`), shown with the same view and applied by the same `ApplyProposalService`. The journal cause is `Journal::CausedByAssistantChat`.
- **Execution:** `SendMessageService` stores the question and a pending answer; `AI::AssistantChats::ReplyJob` answers as the user. The dialog polls until the answer is done or failed. Each answer has its own Details timeline.

## Custom prompt presets

A **Custom prompt** skill (`AI::AssistantSkills::Prompt::Skill`, key `prompt`) is a preset with instructions only, for example "Generate test cases". One click starts a new conversation with the skill's label as the first question, and the answer uses the skill's instructions. The user can then ask follow-up questions. It uses the chat tables and `AI::AssistantChats::Reply`, so it has no findings. Without instructions, it is not offered.

## Proposal scope and changeable attributes

A skill's proposal scope (`ai_assistant_skills.proposal_scope`) is **Changes** (attribute changes and comments), **Comment only** or **Read-only** (nothing). A comment is the Automations action `Comment`, and it needs only the permission to comment. There is no list of attributes to maintain in the UI: with custom fields, such a list would grow without limit.

| Layer | Set by | Health check |
|---|---|---|
| What the skill type can change (`changeable_attributes`) | Code | `subject`, `description`, `status`, `priority`, `start_date`, `due_date`, `assigned_to`, `responsible` |
| The proposal scope | Admin, on the skill page | Changes |
| Which values are valid now (`AI::AssistantRuns::ChangeOptions`) | The workflow and the user's permissions | `assignable_statuses`, `assignable_priorities`, `assignable_assignees` of `WorkPackages::UpdateContract` |

The model gets the valid values as `change_options`, with names, not ids. `ChangeOptions#resolve` maps each answer to an id or an ISO date, and drops anything else. `ApplyProposalService` checks every action again with `ChangeOptions#allowed?` before it applies a proposal, so an admin who narrows a skill's scope after a run also blocks its open proposals.

When a skill may change assignee or accountable, the model gets the names of the users who can be assigned.

The dialog shows text changes as a diff, and other changes as "old → new".

An assistant can have several skills of the same type, for example "Check health" and "Check scope against comments", each with its own label and prompt.

## Prepared for an Automations trigger model

The code does not have triggers, but it uses the shapes that a trigger model needs:

- **Change set in the action vocabulary.** The same shape can serve an AI proposal, an automation step and the answer of an external service.
- **`Automations::Actions::Base#after_success`.** It is called after a successful save. It is the extension point for actions with an effect outside the work package: run a skill, call a webhook, create a work package.
- **A run records its trigger** (`menu` now; `automation` and `schedule` later) and an optional `automation_id`.
- **Run creation and execution are separate.** `RunService` creates and starts a run; `Execution` runs the rules and starts the AI review, so a job can execute a run without a request.
- **The run's user is the only actor.** Skills, rules, the AI review and apply never read `User.current`. A run that a schedule starts can act as a service account.
- **The journal cause carries `source` and `depth`.**

## Gating

- The feature flag `ai_assistance` (off by default in production). The AI part also needs the `llm_connection` flag, the `llm_features_enabled` setting and a configured connection.
- The project permission `use_ai_assistance` (view level). The seeded Member role gets it. Applying a change set also needs `edit_work_packages`.
- There is no enterprise gate yet. See "Follow-ups".

## Data model

| Table | Holds |
|---|---|
| `ai_assistants` | name, description, icon, `model_id` (a string: syncing models replaces `llm_models` rows), position, active |
| `ai_assistant_skills` | `assistant_id`, `skill_key`, `prompt`, position, active |
| `ai_assistant_runs` | skill, user, work package, `work_package_lock_version`, `trigger`, `automation_id`, status, locale, `not_checked`, error |
| `ai_assistant_run_findings` | run, source (`rule`/`ai`), `rule_key`, severity, area, text, `evidence`, `change_set`, `base_lock_version`, state, `dismiss_reason` |

Runs and findings are deleted with their user, their work package or their skill (foreign keys with `on_delete: :cascade`). The basic data seeder creates the "QA assistance" assistant with the `health_check` skill when the table is empty, also on an upgrade.

## How to try it

1. Enable `ai_assistance` at `/admin/settings/experimental`.
2. Give "Use AI assistance" to a role, or use the seeded Member role.
3. Open a closed work package with an open child, and use **AI Assistance → Check health**.
4. For the AI part, configure an LLM connection with a default chat model, then run the check again. To see a change set, add a comment that changes the scope.
5. Configure assistants at **Administration → Artificial Intelligence (AI) → Assistants**.

## Split for review

This change comes as one pull request so that it can be tried end to end. Each commit is one review step. The steps can be cut into separate pull requests in this order, each one stacked on the one before it:

| # | Commit | Contents | Depends on |
|---|---|---|---|
| 1 | Add Subject and Description automation actions and a strict mode | Three Automations action types (Subject, Description, Comment), a text area for text actions, `strict:` and the `after_success` hook in `Automations::UpdateWorkPackageService` | – |
| 2 | Add the ai_assistance flag, permission and journal cause | Feature flag, `use_ai_assistance`, seeded role, `Journal::CausedByAssistantSkill` | – |
| 3 | Add AI assistant, skill, run and finding models | Migration, four models, seeder, factories | 2 |
| 4 | Add the skill registry and the health check tree rules | Registry, `HealthCheck::Context`, four tree rules | 3 |
| 5 | Add the health check relation and staleness rules | Three rules | 4 |
| 6 | Add the health check rules for linked pull requests | GitHub and GitLab rules, "Not checked" entries | 4 |
| 7 | Add the run service, the run controllers and the run dialog | `RunService`, runs and findings controllers, dismiss, Primer dialog and history | 4 |
| 8 | Add the AI Assistance menu to the work package toolbars | Angular slot, menu button, deferred menu items | 7 |
| 9 | Add the AI review to the health check | Job, judgement, model choice, single-job guard, polling | 7 |
| 10 | Apply proposed changes from AI findings | `ApplyProposalService`, content guard, diff view, toolbar refresh | 1, 9 |
| 11 | Add admin pages for AI assistants and their skills | Admin controllers, Primer forms, menu entry | 3 |
| 12 | Add the AI Assistance chat on work packages | Chat tables and models, reply job, chat skill type, chat dialog, `Journal::CausedByAssistantChat` | 10, 11 |
| 13 | Add custom prompt presets, a comment-only scope and a copy button | Custom prompt skill type, `ChatsController#start`, `proposal_scope`, copy button | 12 |
| 14 | Use "AI review" in the interface | Wording | 9 |

Steps 1 and 2 are useful on their own and can merge first. After step 8, the feature works end to end with rules only.

## Follow-ups

- **Enterprise gate.** Gate the menu, the runs and the admin pages behind the existing `custom_actions` enterprise feature, as the last step.
- **Specs.** The model, rule, service, request and component specs cover steps 1–9. Steps 10 and 11 need specs, and the toolbar needs browser specs (full view and split view).
- **Automations can run a skill.** A "Run assistant skill" action type that uses `after_success` and starts a run with `trigger: "automation"`. It gives skills the conditions of Automations, and a path to triggers. The result is still a proposal.
- **Edit before apply.** Open a proposed description in the description editor.
- **Retention.** Runs are kept without a limit. A cleanup job can come when usage shows the need.
