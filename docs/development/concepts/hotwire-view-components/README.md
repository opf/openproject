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

- Components must include the [`OpTurbo::Streamable`](https://github.com/opf/openproject/blob/dev/app/components/concerns/op_turbo/streamable.rb) module
- Requires `component_wrapper` in templates for turbo-stream updates
- Can specify insert targets for append/prepend operations

**Controller Integration**

- Controllers must include the [`OpTurbo::ComponentStream`](https://github.com/opf/openproject/blob/dev/app/controllers/concerns/op_turbo/component_stream.rb) module, which provides methods for turbo-stream operations. The most common ones are:
  - Components: `update_via_turbo_stream`, `replace_via_turbo_stream`, `remove_via_turbo_stream`, `append_via_turbo_stream`, `prepend_via_turbo_stream`, `add_before_via_turbo_stream`, `add_after_via_turbo_stream`, and the generic `modify_via_turbo_stream`
  - Flash messages: `render_success_flash_message_via_turbo_stream`, `render_error_flash_message_via_turbo_stream`, and the generic `render_flash_message_via_turbo_stream`
  - Dialogs: `respond_with_dialog`, `dialog_via_turbo_stream`, `close_dialog_via_turbo_stream`, `update_dialog_title_via_turbo_stream`
  - Page and frames: `scroll_into_view_via_turbo_stream`, `set_page_title_via_turbo_stream`, `reload_page_via_turbo_stream`, `reload_frame_via_turbo_stream`, `set_frame_src_via_turbo_stream`, `dispatch_event_via_turbo_stream`

  See the module itself for the full list and their options.
- Uses `respond_with_turbo_streams(status:)` to handle responses. The status can be a symbol or a `ServiceResult`, which maps to `:ok` or `:unprocessable_entity`.
- [`OpTurbo::FlashStreamHelper`](https://github.com/opf/openproject/blob/dev/app/controllers/concerns/op_turbo/flash_stream_helper.rb) adds `respond_with_flash`, `respond_with_flash_error` and `respond_with_flash_success` for responses that only show a flash message.

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

  # ...
end
```

with the following template:

```erb
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

Appended or prepended components are inserted into the element with the id `insert_target_modifier_id`, which defaults to `"#{wrapper_key}-insert-target-modifier"` and can be overridden. Alternatively, `insert_target_container` renders such an element for you. For a real example, see [`WorkPackages::ActivitiesTab::Journals::LazyIndexComponent`](https://github.com/opf/openproject/blob/dev/app/components/work_packages/activities_tab/journals/lazy_index_component.rb).

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

```erb
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
    journal = Journal.create(journal_params) # in real life this is done through a service obviously ;)

    if journal.errors.empty?
      # append the new model to the index component
      # prepend is also possible
      append_via_turbo_stream(
        component: JournalShowComponent.new(journal: journal),
        target_component: JournalIndexComponent.new(work_package: @work_package)
      )
      # Note: the target_component does not get rendered
      # the instantiation is just required for the turbo-stream generation

      # you can use multiple turbo_stream methods in one controller action
      # e.g. update the new component to render an initial form
      update_via_turbo_stream(
        component: JournalNewComponent.new(work_package: journal.work_package)
      )
    else
      # trigger a flash message via turbo-stream
      # more on this in the flash banner pattern in Lookbook
      render_error_flash_message_via_turbo_stream(
        message: journal.errors.full_messages.join(", ")
      )
    end

    # respond with turbo streams which were collected in the @turbo_streams variable behind the scenes
    # the status is passed explicitly, as each turbo stream call above sets its own default status
    respond_with_turbo_streams(status: journal.errors.empty? ? :ok : :bad_request)
  end

  # ...
end
```

## Mixing turbo-streams and other responses

To respond to other formats as well, pass a block to `respond_with_turbo_streams`. It is called with the `respond_to` format object, so you can add an HTML response for requests that do not accept turbo streams:

```ruby
class JournalController < ApplicationController
  include OpTurbo::ComponentStream # include this module!

  # ...

  def update
    # ...

    update_via_turbo_stream(
      component: JournalShowComponent.new(journal: journal)
    )

    respond_with_turbo_streams do |format|
      format.html { redirect_to journal_path(journal) }
    end
  end

  # ...
end
```

## Usage alongside Primer Forms/Buttons

Turbo Drive is enabled globally, so forms and links only need `turbo_stream: true` to request a turbo-stream response:

```erb
<%=
  component_wrapper do
    # ...
    primer_form_with(
      model: journal,
      method: :put,
      data: { turbo_stream: true }, # add this!
      url: journal_path(id: journal.id)
    ) do |f|
      # ...
    end
    # ...
  end
%>
```

Rendering of a cancel button to remove the edit form. The button calls the `cancel_edit` action on the controller. The `cancel_edit` action sends a turbo stream `replace` to replace the journal edit form with the journal view.

```erb
<%=
  component_wrapper do
    # ...
    render(Primer::Beta::Button.new(
      tag: :a,
      href: cancel_edit_journal_path(journal.id),
      data: { turbo_stream: true } # add this!
    )) do
      t("button_cancel")
    end
    # ...
  end
%>
```

## Requesting turbo-streams within Stimulus controllers

If for some reason you need to request a turbo-stream programmatically from within a Stimulus controller, you can use the [`TurboRequestsService`](https://github.com/opf/openproject/blob/dev/frontend/src/app/core/turbo/turbo-requests.service.ts) to do so. Get hold of it with the [`useAngularServices`](https://github.com/opf/openproject/blob/dev/frontend/src/stimulus/mixins/use-angular-services.ts) mixin, which handles waiting for the Angular plugin context and controllers that disconnect in the meantime:

```typescript
import { Controller } from '@hotwired/stimulus';
import { ServiceKey, useAngularServices } from 'core-stimulus/mixins/use-angular-services';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

export default class IndexController extends Controller {
  static services:ServiceKey[] = ['turboRequests'];
  declare turboRequests:TurboRequestsService;

  initialize() {
    useAngularServices(this);
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

Besides `request(url, init)`, the service provides `requestStream(url)` for GET requests of turbo streams, `submitForm(form, params, url)` to submit a form and render its turbo-stream response, and `abortRequest(requestId)` to cancel a pending request.
