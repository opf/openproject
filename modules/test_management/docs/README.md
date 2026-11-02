# Test management – user guide

Test management adds test cases, test runs, milestones, CI results and an AI Test Assistant to an
OpenProject project. This guide describes the current state of the module (proof of concept).

| Section | Contents |
|---|---|
| [Overview](#overview) | Concepts, navigation, permissions |
| [Test cases](cases.md) | Folders, cases, steps, labels, linked work packages, the work package *Testing* tab, exports |
| [Test runs](runs.md) | Case selection, statuses, iterations, attachments, completing a run, exports |
| [Configurations](configurations.md) | Optional browser/OS/device values in Project settings |
| [Test plans](plans.md) | Optional campaigns, entries, configuration matrices, complete/rerun |
| [Milestones](milestones.md) | Grouping runs by release, sprint, regression cycle, UAT … |
| [Test Assistant 🪄](assistant/README.md) | Generate draft cases, chat about the project, confirm actions |
| [CI and automation](ci/README.md) | Uploading results, CI connections, *Run in CI*, self-hosted Git, repo-qualified references |
| [API](api.md) | The APIv3 endpoints of the module |
| [Keyboard shortcuts](hotkeys/README.md) | `g t c`, `n t c`, `u`, `g t h` …, hints and tips, switching them off |
| [Settings](settings.md) | Project settings and administration (AI provider, shortcuts) |
| [AI providers reference](assistant/ai-providers.md) | Endpoints, authentication and model lists per provider (administrators) |

## Overview

### Concepts

| Term | Meaning |
|---|---|
| **Test case** | A test to perform: title, preconditions, steps with expected results, status, priority, labels, linked work packages. Lives in a **folder**. |
| **Folder** | A tree of folders per project that structures the cases. |
| **Test run** | One execution of a set of cases. Each case in the run gets a result (passed, failed, blocked, retest, in progress, skipped, untested). |
| **Iteration** | A re-execution of the same run (e.g. the *Smoke* run on every build). Earlier iterations stay in the history. |
| **Configuration** | Optional project-level value (e.g. Chrome) used to tag a run or to explode a plan matrix. |
| **Test plan** | Optional campaign that groups/spawns related runs (including a configuration matrix). |
| **Milestone** | Groups runs (and optionally plans) towards a goal (a release, a sprint, UAT) and shows their combined progress. |
| **CI connection** | A repository / CI job that uploads results to the project and can be started from OpenProject (*Run in CI*). |
| **Automation reference** | The link between an automated test and a case, e.g. `tests/login.spec.ts#login › signs in`. |

There is no separate "execution" object: a run **is** the execution, and each re-execution is an
iteration of it.

### Optional layering

Every layer is independently optional:

| You can… | Without needing… |
|---|---|
| Author **cases** | Runs, plans, milestones, configs, CI |
| Create and execute a **test run** | Plan, milestone, configurations |
| **Repeat** a run via **iterations** | Plan or milestone |
| Tag a run with **configurations** | Plan |
| Build a **plan** (campaign + matrix) | Milestone |
| Let **CI create, fill and close** a run | UI; plan; milestone (milestone is optional on create) |
| Upload CI results into an **existing run id** | Completing the whole run; only matched cases update |

### Navigation

Enable **Test management** in Project settings → Modules. The project menu then has a
**Test management** entry with a "→" arrow. It opens the module's submenu (like Work packages,
Documents or Meetings), with a "← Test management" link back to the project menu:

**Cases · Test Assistant · Runs · Plans · Milestones · CI**

- An entry is only shown with the permission for its page. Test Assistant, Plans and Milestones also
  follow their project switches.
- **CI** remains a placeholder section in this PoC. CI connections are set up in Project settings →
  Test management (see [CI and automation](ci/README.md)). Requirements and Reports are not in the
  navigation for this cut.

- With the folder tree layout **sidebar** (Project settings → Test management), the folder tree is
  shown in the submenu below the list on the Cases pages; by default it is a split pane in the page.
- Every page can also be reached with [keyboard shortcuts](hotkeys/README.md).

### Permissions

| Permission | Allows |
|---|---|
| View test cases (`view_test_cases`) | See folders and cases; needed for everything else |
| Add / Edit / Delete test cases, Change test case status | Create, change and delete cases (`add_test_cases`, `edit_test_cases`, `delete_test_cases`, `change_test_case_status`) |
| Manage test suites (`manage_test_suites`) | Create, rename, move and delete folders |
| Link test cases to work packages | Change a case's linked work packages |
| View test runs (`view_test_runs`) | See runs, iterations, results and milestones |
| Manage test runs (`add_test_runs`) | Create, edit, complete, cancel and reopen runs; start iterations; assign runs to milestones |
| Delete test runs (`delete_test_runs`) | Permanently delete a run |
| Execute test runs (`execute_test_runs`) | Set results and attach files in runs |
| View test plans (`view_test_plans`) | See plans and their runs |
| Manage test plans (`manage_test_plans`) | Create, edit, complete, reopen, rerun and delete plans; manage entries |
| Manage milestones (`manage_test_milestones`) | Create, edit, start, complete, reopen and delete milestones |
| Upload automated test results (`upload_test_results`) | Send CI reports through the API |
| Manage test CI (`manage_test_ci`) | CI connections in Project settings and the API |
| Trigger test automation (`trigger_test_automation`) | *Run in CI* |
| Use test assistant (`use_test_assistant`) | Open the Test Assistant (saving and confirming also need the permission of the action) |
| Show Testing tab (`show_testing_content`) | The *Testing* tab of work packages |
| Manage test management (`manage_test_management`) | Project settings → Test management, labels |
