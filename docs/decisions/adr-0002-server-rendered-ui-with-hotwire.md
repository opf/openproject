---
status: "proposed"
date: 2026-10-01
decision-makers: { team leads }
consulted: { frontend developers, UX }
informed: All developers
---

# Build the UI server-rendered with Hotwire and ViewComponents; migrate Angular incrementally

## Context and Problem Statement

OpenProject is a hybrid application. Large parts of the UI — the work package table and full/split views, boards,
calendar, team planner, Gantt, BIM, My page — are an Angular application that talks to the API v3 (HAL+JSON). Since
2023, new UI has increasingly been built server-rendered with Rails, [ViewComponent](https://viewcomponent.org/), the
[Primer Design System](https://primer.style) and [Hotwire](https://hotwired.dev) (Turbo + Stimulus).

Today both stacks are actively extended. At the time of writing the frontend contains roughly 300 Angular components
next to about 170 Stimulus controllers, and about 60 Angular components are bridged into server-rendered pages as
`opce-*` custom elements. There is no written rule about which stack new UI belongs to, when existing Angular code
should be migrated, or how the two stacks integrate. As a result, the choice of stack is re-discussed for new UI work,
everything the Angular UI needs has to be exposed through API v3 endpoints, representers and schemas first, and every
developer has to be productive in two very different frontend architectures.

Which rendering approach is the default for OpenProject's UI, and how do we treat the existing Angular code?

## Decision Drivers

- Short path from business logic to UI: permissions, validations and schema live in Rails and should not need an API
  layer to reach the UI
- Developer productivity across teams: most features are built by full-stack developers working in Rails
- Accessibility and visual consistency via a single design system (Primer)
- Maintenance cost: Angular major upgrades, the size of the frontend bundle, two sets of patterns to review
- Highly interactive views (drag and drop, timelines, inline editing in large tables) must remain usable
- Migration must be incremental; a rewrite of the Angular application is not feasible

## Considered Options

- Server-rendered UI with Hotwire and ViewComponents; Angular is legacy and migrated incrementally
- Angular single-page application as the primary UI
- Hybrid without a policy (status quo)
- Rewrite the frontend as a React single-page application

## Decision Outcome

Chosen option: "**Server-rendered UI with Hotwire and ViewComponents; Angular is legacy and migrated incrementally**",
because it renders UI directly from the models and services that hold the business logic, lets the whole team build UI
in the stack it already uses for everything else, and aligns with Primer, which we use as our design system. It is the
only option that reduces the number of frontend architectures over time without requiring a rewrite.

The Angular SPA option would require every UI feature to go through API v3 endpoints, representers and schemas, which
is the opposite of where the codebase has been heading. The status quo keeps the cost of two stacks indefinitely. A
React rewrite would replace one SPA with another at a very high one-off cost and would keep the API layer as a
prerequisite for every UI feature.

The following rules apply from the moment this ADR is accepted:

1. **New UI is server-rendered.** New pages, dialogs, forms and components are built with ViewComponent and Primer.
   Dynamic updates use Turbo (frames, streams via `OpTurbo::ComponentStream` or full page morphing), client-side
   behaviour uses Stimulus controllers.
2. **No new Angular.** No new Angular components, modules, services or pages are added. New pages are not rendered with
   the `angular/angular` layout.
3. **Existing Angular is maintained, not extended.** Bug fixes and small changes to existing Angular code are fine.
   When a feature requires a significant extension or rework of an Angular component, the affected part is migrated to
   ViewComponent/Hotwire as part of that work — or a migration work package is created and linked, if the scope does
   not allow it. This applies in particular to displaying and editing work packages (full and split view, inline
   editing, the work package table), which is the largest and most frequently changed Angular area.
4. **Angular is embedded via custom elements.** Where a server-rendered page needs an existing Angular component, the
   component is exposed as an `opce-*` custom element (`registerCustomElement` in the frontend, `angular_component_tag`
   in Ruby) instead of rendering the page through the Angular application.
5. **The API v3 is not the data source for new UI.** It remains the public, documented API for integrations. New UI
   gets its data from Rails controllers rendering HTML.

Out of scope: the use of React for the BlockNote editor and the choice of frontend state management for the remaining
Angular code. Both are subject to separate ADRs.

### Confirmation

- Code review: reviewers reject pull requests that add new Angular components, modules or services, or new pages
  using the Angular layout.
- `docs/development/application-architecture/` and `docs/development/style-guide/frontend/` are updated to reference
  this ADR and to describe Angular as legacy.

## Pros and Cons of the Options

### Server-rendered UI with Hotwire and ViewComponents; Angular is legacy and migrated incrementally

```ruby
# Controller
class Projects::LabelsController < ApplicationController
  include OpTurbo::ComponentStream

  def create
    call = Labels::CreateService.new(user: current_user).call(label_params)

    replace_via_turbo_stream(component: Projects::Labels::ListComponent.new(project: @project))
    render_error_flash_message_via_turbo_stream(message: call.message) if call.failure?

    respond_with_turbo_streams
  end
end
```

```erb
<%# Embedding an existing Angular component while it is not migrated yet %>
<%= helpers.angular_component_tag "opce-project-autocompleter", inputs: { ... } %>
```

- Good, because UI is rendered directly from models, contracts and services without an intermediate API layer
- Good, because any Rails developer can build and review UI without Angular expertise
- Good, because Primer ViewComponents give accessible, consistent UI by default
- Good, because migration can happen page by page and component by component
- Neutral, because highly interactive widgets still need client-side code (Stimulus, or custom elements)
- Bad, because both stacks coexist for years, including the Angular bundle size and Angular upgrades
- Bad, because the most complex views (work package table, Gantt, boards, team planner) are expensive to migrate
- Bad, because every interaction that needs server data costs a round trip

### Angular single-page application as the primary UI

```typescript
@Component({
  selector: 'op-project-labels',
  templateUrl: './project-labels.component.html',
})
export class ProjectLabelsComponent {
  labels$ = this.apiV3Service.projects.id(this.projectId).labels.get();
}
```

- Good, because the most complex existing views already exist in Angular
- Good, because rich client-side interactions without round trips
- Bad, because every UI feature requires API v3 endpoints, representers, schemas and frontend resources
- Bad, because it requires specialised frontend expertise for most features
- Bad, because it reverses the direction of the last years of development

### Hybrid without a policy (status quo)

- Good, because no migration effort is required
- Good, because developers can pick the stack that fits the problem at hand
- Bad, because the same problem keeps being solved in two different ways
- Bad, because the Angular part keeps growing and becomes harder to migrate
- Bad, because reviewers have no basis to request one approach over the other

### Rewrite the frontend as a React single-page application

```tsx
export function ProjectLabels({ projectId }: { projectId:string }) {
  const { data: labels } = useQuery(['labels', projectId], () => fetchLabels(projectId));
  return <LabelList labels={labels} />;
}
```

- Good, because React has a large ecosystem and is already a dependency through BlockNote
- Bad, because it is a full rewrite with no value delivered until large parts are done
- Bad, because every UI feature still requires an API layer between Rails and the frontend
- Bad, because it adds a third paradigm while the migration is ongoing

## More Information

- [Using Hotwire with ViewComponents](../development/concepts/hotwire-view-components/README.md)
- [Stimulus](../development/concepts/stimulus/README.md)
- [Application architecture](../development/application-architecture/README.md)
- [Primer ViewComponents Lookbook](https://qa.openproject-edge.com/lookbook/)

Revisit this decision if Hotwire cannot deliver acceptable usability for one of the highly interactive views, or once
the remaining Angular code is small enough to set a removal date for Angular.
