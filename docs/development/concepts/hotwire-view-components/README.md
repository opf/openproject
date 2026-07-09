---
sidebar_navigation:
  title: Using Hotwire with ViewComponents
description: An introduction of how we use Hotwire alongside ViewComponents
keywords: Ruby on Rails, Hotwire, ViewComponents
---

# Using Hotwire with ViewComponents

OpenProject uses [Hotwire](https://hotwired.dev/) alongside [ViewComponents](https://viewcomponent.org/) to build dynamic user interfaces. This combination allows us to create interactive features while maintaining a component-based architecture.

The approach below is meant to be a thin abstraction layer on top of Hotwire's Turbo Streams to make them easier to use with a component based UI architecture built on ViewComponents.

## Key Concepts

**Component Setup**

- Components must include `OpTurbo::Streamable` module
- Requires `component_wrapper` in templates for turbo-stream updates
- Can specify insert targets for append/prepend operations

**Controller Integration**

- Controllers must include `OpTurbo::ComponentStream` module, which provides methods for turbo-stream operations:
  - `update_via_turbo_stream`
  - `replace_via_turbo_stream`
  - `remove_via_turbo_stream`
  - `modify_via_turbo_stream`
  - `append_via_turbo_stream`
  - `prepend_via_turbo_stream`
  - `add_before_via_turbo_stream`
  - `render_error_flash_message_via_turbo_stream`
  - `update_flash_message_via_turbo_stream`
  - `scroll_into_view_via_turbo_stream`
- Uses `respond_with_turbo_streams` to handle responses

## Example

Imagine we have a component that renders a list of journals for a work package.

This is the index component:

```ruby
class JournalIndexComponent < ApplicationComponent
  include OpTurbo::Streamable # include this module

  def initialize(work_package:)
    super

    @work_package = work_package
  end

  attr_reader :work_package

  # optional:

  # modifier to determine if the insert target should be modified
  # relevant for append or prepend operations
  def insert_target_modified?
    true
  end

  def insert_target_modifier_id
    "work-package-journals"
  end

  # ...
end
```

with the following template:

```ruby
<%=
  component_wrapper do # wrapper is required for turbo-stream updates!
    flex_layout do |journals_index_wrapper_container|
      journals_index_wrapper_container.with_row do
        flex_layout(id: insert_target_modifier_id) do |journals_index_container|
          work_package.journals.each do |journal|
            journals_index_container.with_row do
              render(JournalShowComponent.new(journal:))
            end
          end
        end
      end
      journals_index_wrapper_container.with_row do
        render(JournalNewComponent.new(work_package:))
      end
    end
  end
%>
```

And this is the show component:

```ruby
class JournalShowComponent < ApplicationComponent
  include OpTurbo::Streamable # include this module

  def initialize(journal:)
    super

    @journal = journal
  end

  attr_reader :journal

  # ...
end
```

with the following template:

```ruby
<%=
  component_wrapper do # wrapper is required for turbo-stream updates!
    render(border_box_container()) do |border_box_component|
      # ...
    end
  end
%>
```

With this setup, turbo-stream updates can be sent from a rails controller:

```ruby
class JournalController < ApplicationController
  include OpTurbo::ComponentStream # include this module!

  # ...

  def update
    journal = Journal.find(params[:id])

    journal.update(journal_params) # in real life this would be done through a service obviously ;)

    # update the journal show component
    update_via_turbo_stream(
      component: JournalShowComponent.new(journal: journal)
    )

    # respond with turbo streams which were collected in the @turbo_streams variable behind the scenes
    # handy if this method is just meant to respond to turbo-stream requests
    respond_with_turbo_streams
  end

  def create
    journal = Journal.create(journal_params) # in real life this is done through a service obviosuly ;)

    if journal.errors.empty?
      # append the new model to the index component
      # prepend is also possible
      append_via_turbo_stream(
        component: JournalShowComponent.new(journal: journal),
        target_component: JournalIndexComponent.new(work_package: @work_package)
      )
      # Note: the target_component does not get rendered
      # the instatiation is just required for the turbo-stream generation

      # you can use multiple turbo_stream methods in one controller action
      # e.g. update the new component to render an initial form
      update_via_turbo_stream(
        component: JournalNewComponent.new(work_package: journal.work_package)
      )
    else
      # optionally set a turbo status for the response
      @turbo_status = :bad_request

      # trigger a flash message via turbo-stream
      # more on this here lookbook/pages/patterns/flash_banner
      update_flash_message_via_turbo_stream(
        message: journal.errors.full_messages.join(", "),
        scheme: :danger
      )
    end

    # respond with turbo streams which were collected in the @turbo_streams variable behind the scenes
    # handy if this method is just meant to respond to turbo-stream requests
    respond_with_turbo_streams
  end

  # ...
end
```

## Mixing turbo-streams and other responses

TODO: Discuss the below example

```ruby
class JournalController < ApplicationController
  include OpTurbo::ComponentStream # include this module!

  # ...

  def update
    # ...

    respond_to do |format|
      format.html do
        # ...
      end
      format.turbo_stream do
        update_via_turbo_stream(
          component: JournalShowComponent.new(journal: journal)
        )

        render turbo_stream: turbo_streams, status: :ok
      end
    end
  end

  # ...
end
```

## Usage alongside Primer Forms/Buttons

TODO: is `turbo: true` required here?

```ruby
<%=
  component_wrapper do
    # ...  
    primer_form_with(
      model: journal,
      method: :put,
      data: { turbo: true, turbo_stream: true }, # add this!
      url: journal_path(id: journal.id)
    ) do |f|
      # ...
    end
    # ...
  end
%>
```

Rendering of a cancel button to remove the edition form. The button calls the `cancel_edit` action on the controller. The `cancel_edit` action sends a turbo stream `replace` to replace the journal edit form with the journal view.

```ruby
<%=
  component_wrapper do
    # ...  
    render(Primer::Beta::Button.new(
      href: cancel_edit_journal_path(journal.id),
      data: { turbo: true, turbo_stream: true } # add this!
    )) do
      t("button_cancel")
    end
    # ...
  end
%>
```

## Requesting turbo-streams within Stimulus controllers

If for some reason you need to request a turbo-stream programmatically from within a Stimulus controller, you can use the `TurboRequestsService` to do so.

TODO: Discuss the TurboRequestsService API

```typescript
import { Controller } from '@hotwired/stimulus';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

export default class IndexController extends Controller {

  private turboRequests:TurboRequestsService;

  async connect() {
    const context = await window.OpenProject.getPluginContext();
    this.turboRequests = context.services.turboRequests;
  }

  private async someMethod() {
    // this method will automatically handle the turbo-stream response and thus trigger the DOM updates
    const response = await this.turboRequests.request(someUrl, {
      method: 'GET',
    });

    // for optional further processing of the stream html and response headers:
    console.log(response.html, response.headers);
  }
}
```
