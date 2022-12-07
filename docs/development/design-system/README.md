---
sidebar_navigation:
  title: Design system
  priority: 998
description: OpenProject Design System
keywords: Design system, styles, design, components
---
# Design System

> **Note**: The initial version of the OpenProject design system is designed, developed and documented in Figma. We will move this documentation to the docs in a later stage.

## Foundation library

| Style definition (Figma)                                     | Status                         |
| ------------------------------------------------------------ | ------------------------------ |
| [Colours](https://www.figma.com/file/vOw6PEVIyzaQOIgf02VZFW/Foundations-Styles?node-id=0%3A1) | Working draft, designed, docs in progress |
| [Shadows](https://www.figma.com/file/vOw6PEVIyzaQOIgf02VZFW/Foundations-Styles?node-id=228%3A3) | Working draft, designed, docs in progress |
| [Typography](https://www.figma.com/file/vOw6PEVIyzaQOIgf02VZFW/Foundations-Styles?node-id=445%3A155) | Working draft, designed, docs in progress |
| [Spacings](https://www.figma.com/file/vOw6PEVIyzaQOIgf02VZFW/Foundations-Styles?node-id=228%3A2) | Working draft, designed |
| [Iconography](https://www.figma.com/file/vOw6PEVIyzaQOIgf02VZFW/Foundations-Styles?node-id=123%3A1076) | Working draft, designed |
| [Illustrations](https://www.figma.com/file/vOw6PEVIyzaQOIgf02VZFW/Foundations-Styles?node-id=220%3A2) | Working draft, designed |

## Components

| Style definitions (Figma)                                    | Status                         | Implementation examples                                      |
| ------------------------------------------------------------ | ------------------------------ | ------------------------------ |
| [Action bar](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/Components-Library?node-id=501%3A3578) | Working draft, designed, documented | [Include projects multi-select modal](https://community.openproject.org/work_packages) |
| [Badges](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/Components-Library?node-id=384%3A3249) | Working draft, designed, no documentation yet |  |
| [Buttons and Toggles](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/Components-Library?node-id=384%3A3399) | Working draft, designed, partial documentation | [Include projects multi-select modal](https://community.openproject.org/work_packages) |
| [Calendar](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/Components-Library?node-id=832%3A5342) | Working draft, designed, no documentation yet | [Calendar module](https://community.openproject.org/projects/openproject/calendars/3182?cdate=2022-04-01&cview=dayGridMonth) and Team Planner |
| [Chips](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/Components-Library?node-id=510%3A3564) | Working draft, designed, documented |  |
| [Dividers](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=397%3A4114) | Working draft, designed, no documentation yet |  |
| [Dropdowns](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=397%3A3910) | Working draft, designed, no documentation yet |  |
| [Drop modal](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=502%3A3417) | Working draft, designed, documented | [Include projects multi-select modal](https://community.openproject.org/work_packages) |
| [Search field](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=384%3A3315) | Working draft, designed, documented | [Include projects multi-select modal](https://community.openproject.org/work_packages) |
| [Selection controls](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=400%3A3260) | Working draft, designed, partial documentation |  |
| [Tab bar](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=384%3A3321) | Working draft, designed, no documentation yet |  |
| [Tables](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=0%3A1) | Working draft, designed, no documentation yet |  |
| [Text fields](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=400%3A3640) | Working draft, designed, documented | [Include projects multi-select modal](https://community.openproject.org/work_packages) |
| [Toast](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=391%3A3910) | Working draft, designed, no documentation yet |  |
| [Tooltip](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=391%3A3910) | Working draft, designed, no documentation yet |  |

### Search field

| Places where we use this style         | Current implementation | Migration to design system                              |
| -------------------------------------- | ---------------------- | ------------------------------------------------------- |
| Work packages -> Include projects      | Angular                | [12.1](https://community.openproject.org/versions/1493) |
| Sidebar                                | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Header main navigation                 | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Single select project                  | Angular                |                                                         |
| Team planner -> Add existing           | Angular                |                                                         |
| Team planner -> Add assignee           | Angular                |                                                         |
| Work packages -> Create relation       | Angular                |                                                         |
| Work packages -> Set parent            | Angular                |                                                         |
| Work packages -> Add child             | Angular                |                                                         |
| Work packages -> Add watcher           | Angular                |                                                         |
| Work packages -> All details           |                        |                                                         |
| Work package list -> Columns           | Angular                |                                                         |
| Work package list -> Highlighting      | Angular                |                                                         |
| Boards -> Add existing card            | Angular                |                                                         |
| Time and costs -> Report project       |                        |                                                         |
| Members -> Add new member              | Rails                  |                                                         |
| Work package filters -> All searchable | Angular                |                                                         |
| Work package filters -> Filter by text | Angular                |                                                         |
| Project settings -> Information        | Angular                |                                                         |
| My profile -> Notification settings    | Angular                |                                                         |
| Administration -> User                 | Rails                  |                                                         |
| Administration -> Placeholder user     | Rails                  |                                                         |
| Administration -> Groups               | Rails                  |                                                         |
| Administration -> Custom actions       | Rails                  |                                                         |

## Patterns

| Style definitions (Figma)                                    | Status                         | Implementation examples                                      |
| ------------------------------------------------------------ | ------------------------------ | ------------------------------ |
| [Action modal](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=861%3A10487) | Working draft, designed, documented |  |
| [Dialogues](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=384%3A3400) | Working draft, designed, no documentation yet |  |
| [Headers](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=861%3A10487) | Working draft, designed, no documentation yet | In all pages |
| [List and List Primitives](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=386%3A3606) | Working draft, designed, documented |  |
| [Main sidebar](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=384%3A3262) | Working draft, designed, no documentation yet | In almost all pages |
| [Notifications](https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/?node-id=384%3A3362) | Working draft, designed, no documentation yet | [Notification Center](https://community.openproject.org/notifications) |

## Functions

### Project selector list

| Places where we use this style                               | Current implementation | Migration to design system                              |
| ------------------------------------------------------------ | ---------------------- | ------------------------------------------------------- |
| Select parent project on create new project                  | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Select parent project on copying a project                   | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Change the parent project information on the project settings | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Change project of a work package on split screen             | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Change project of a work package on full view                | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Change project of a work package on work package list column | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Project filter on the boards (as include project is not implemented yet) | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Create a new work package from outside of any project        | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Notification settings                                        | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Invite user modal                                            | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| *Administration > Users > Specific User > Projects*: New project selection | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| *Administration > Placeholder users > Specific placeholder users > Projects*: New project selection | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| *Administration > Groups > Specific groups > Projects*: New project selection | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| *Administration > Custom actions* > New custom action        | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Add a project filter into a new cost report                  | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Edit the project filters from the work package table configuration | Angular                | [12.2](https://community.openproject.org/versions/1494) |
| Navigation bar project selector                              | Angular                | [12.2](https://community.openproject.org/versions/1494) |

## Contribute

The OpenProject product team is very interested in your feedback. So if you want to contribute or comment on the style definitions, components or documentation currently created in Figma please contact us by email to [info@openproject.com](mailto:info@openproject.com). Alternatively you can create a work package in the [OpenProject community platform](https://community.openproject.org).
