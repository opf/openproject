# Browser drivers

Feature specs tagged with `:js` use Capybara to run tests in an actual browser. OpenProject supports two browser drivers:

- **Cuprite** is the default driver. It controls Chrome directly through the Chrome DevTools Protocol (CDP), using [Ferrum](https://github.com/rubycdp/ferrum).
- **Selenium** controls Chrome or Firefox through [WebDriver](https://www.selenium.dev/documentation/webdriver/).

The driver for each example is selected in `spec/support/cuprite_setup.rb`, based on its metadata:

1. If `driver:` is set, the example uses the specified driver, for example `driver: :firefox_de`.
2. Otherwise, examples tagged with `:selenium` use `:chrome_en`.
3. All remaining examples use `:better_cuprite_en`.

## Why Cuprite is the default

When choosing a browser driver, we prioritize the following, in this order:

1. **Stability**: Specs should produce consistent results across runs.
2. **Realistic browser interactions**: Specs should interact with the application as a user would.
3. **Speed**: Specs should run efficiently.

Cuprite has been the default driver since [#17587](https://github.com/opf/openproject/pull/17587). It supports these goals in several ways:

- Controlling Chrome without a separate WebDriver process reduces the time needed to run browser specs.
- Direct CDP access allows specs to wait for specific browser events, such as network idle or a particular request, and to use real keyboard and mouse input.
- Faster execution can expose race conditions that remain hidden with Selenium. These failures indicate a bug in the application or a missing wait in the spec and should be addressed there.

Cuprite and Ferrum rely on a single maintainer, while Selenium implements the W3C WebDriver standard and has several maintainers. To reduce this maintenance risk, we keep the Selenium drivers registered and support both drivers in shared helpers through `using_cuprite?`. This allows a spec to switch back to Selenium by adding a tag.

## When to use Selenium

Use Cuprite for new browser specs. Selenium should only be used when a spec requires one of the following:

1. **An interaction that Cuprite does not yet support through real browser input.** Currently, this applies to native HTML5 drag and drop, for example with [Pragmatic drag and drop](https://atlassian.design/components/pragmatic-drag-and-drop/). See AGILE-335.
2. **A browser configuration that is only available through a Selenium driver.** Examples include a German locale (`driver: :firefox_de`), a different browser time zone (`driver: :chrome_new_york_time_zone`), dark mode (`driver: :chrome_dark_mode`), a proxy (`driver: :chrome_billy`), or Firefox.

If a spec is flaky with Cuprite, investigate the race condition and fix the application or add an appropriate wait to the spec. Switching to Selenium does not resolve the underlying issue. See [Handling flaky tests](../handling-flaky-tests/) for guidance.

When adding a `:selenium` tag, include a short comment explaining why it is needed. Link to the relevant work package if one exists:

```ruby
# Native HTML5 drag and drop needs CDP drag interception on Cuprite (AGILE-335)
it "reorders types via drag and drop", :selenium do
```

Some existing `:selenium` tags do not have an explanation. When modifying one of these specs, check whether it can run with Cuprite.

## Use real browser input

Feature specs should interact with the page through the browser driver. Using JavaScript to perform an interaction can cause a spec to pass even when the feature does not work for users.

Follow these guidelines when writing browser interactions:

- Use `click_on`, `click`, `fill_in`, `check`, `choose`, `select` and `send_keys`.
- Do not click with `execute_script("arguments[0].click()")` or `trigger("click")`.
- Do not use the native value setter to change field values or `dispatchEvent` to dispatch synthetic events.
- Do not call `showPopover()`, `hidePopover()` or `requestSubmit()`.

You can use JavaScript to read page state, such as the scroll position or the focused element, or to wait until the page is ready, for example with `wait_for_stimulus_controller`.

## Cuprite pitfalls

| Symptom | Cause | Approach |
| --- | --- | --- |
| No options appear after entering text in an autocompleter or search field | `Node#set` fires `blur` after setting the value. Components that close on blur lose the input. | Click the field and type the text, for example with `ng_enter_query`. |
| A key press on an element other than an input has an unexpected effect | `Node#send_keys` clicks the element before typing. | Use `send_keys_without_click(element, :return)`. |
| A helper does not retry when an element becomes stale | Capybara only retries the outermost `synchronize`. Wrapping a helper in `synchronize` or `retry_block` prevents retries within the helper. | Avoid wrapping helpers that already handle synchronization, such as `select_autocomplete`. |
| A form or table row closes, or rows become stale, about 0.5 seconds after saving | The work package table refreshes after a debounce (`halEvents.aggregated$`). | Use `wait_for_request(%r{/queries/default\?}) { save }`. |
| A click after `page.go_back` has no effect | Chrome restores the page from the back/forward cache. The application then starts a Turbo visit that replaces the body. | After `page.go_back`, wait with `expect(page).to have_no_css("html[aria-busy]")`. |
| A spinner remains visible even though options are available | Angular renders some results only on the next browser event. | Wait for the expected option instead of waiting for the spinner to disappear. The `select_autocomplete` helper handles this. |
| Native HTML5 drag and drop has no effect | Chrome requires drag interception to start a native drag through CDP input. | Use Selenium for now (AGILE-335). |

For guidance on waiting for Turbo streams, frames and visits, see [Common feature-spec flake patterns and their fixes](../handling-flaky-tests/#common-feature-spec-flake-patterns-and-their-fixes).
