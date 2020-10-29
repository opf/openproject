# Task Lists

[![Build Status](http://img.shields.io/travis/deckar01/task_list.svg)][travis]

[travis]: https://travis-ci.org/deckar01/task_list

This is a community fork of GitHub's archived [`task_list`][task_list] gem.

[task_list]: https://github.com/github-archive/task_list

```md
- [x] Get
- [x] More
- [ ] Done
```

> - [x] Get
> - [x] More
> - [ ] Done

## Components

The Task List feature is made of several different components:

* Markdown Ruby Filter
* Summary Ruby Model: summarizes task list items
* JavaScript: frontend task list update behavior
* CSS: styles Markdown task list items

## Usage & Integration

The backend components are designed for rendering the Task List item checkboxes, and the frontend components handle updating the Markdown source (embedded in the markup).

### Backend: Markdown pipeline filter

Rendering Task List item checkboxes from source Markdown depends on the `TaskList::Filter`, designed to integrate with the [`html-pipeline`](https://github.com/jch/html-pipeline) gem. For example:

``` ruby
require 'html/pipeline'
require 'task_list/filter'

pipeline = HTML::Pipeline.new [
  HTML::Pipeline::MarkdownFilter,
  TaskList::Filter
]

pipeline.call "- [ ] task list item"
```

### Frontend: Markdown Updates

Task List updates on the frontend require specific HTML markup structure, and must be enabled with JavaScript.

Rendered HTML (the `<ul>` element below) should be contained in a `js-task-list-container` container element and include a sibling `textarea.js-task-list-field` element that is updated when checkboxes are changed.

``` markdown
- [ ] text
```

``` html
<div class="js-task-list-container">
  <ul class="task-list">
    <li class="task-list-item">
      <input type="checkbox" class="js-task-list-item-checkbox" disabled />
      text
    </li>
  </ul>
  <form>
    <textarea class="js-task-list-field">- [ ] text</textarea>
  </form>
</div>
```

Enable Task List updates with:

``` javascript
// Vanilla JS API
var container = document.querySelector('.js-task-list-container')
new TaskList(container)
// or jQuery API
$('.js-task-list-container').taskList('enable')
```

NOTE: Updates are not persisted to the server automatically. Persistence is the responsibility of the integrating application, accomplished by hooking into the `tasklist:change` JavaScript event. For instance, we use AJAX to submit a hidden form on update.

Read through the documented behaviors and samples [in the source][frontend_behaviors] for more detail, including documented events.

[frontend_behaviors]: https://github.com/deckar01/task_list/blob/master/app/assets/javascripts/task_list.coffee

## Installation

Task Lists are packaged as both a RubyGem with both backend and frontend behavior, and a Bower package with just the frontend behavior.

### Backend: RubyGem

For the backend Ruby components, add this line to your application's Gemfile:

    gem 'deckar01-task_list'

And then execute:

    $ bundle

### Frontend: NPM / Yarn

For the frontend components, add `deckar01-task_list` to your npm dependencies config.

This is the preferred method for including the frontend assets in your application.

### Frontend: Bower

For the frontend components, add `deckar01-task_list` to your Bower dependencies config.

### Frontend: Rails 3+ Railtie method

``` ruby
# config/application.rb
require 'task_list/railtie'
```

### Frontend: Rails 2.3 Manual method

Wherever you have your Sprockets setup:

``` ruby
Sprockets::Environment.new(Rails.root) do |env|
  # Load TaskList assets
  require 'task_list/railtie'
  TaskList.asset_paths.each do |path|
    env.append_path path
  end
end
```

If you're not using Sprockets, you're on your own but it's pretty straight
forward. `deckar01-task_list/railtie` defines `TaskList.asset_paths` which you can use
to manage building your asset bundles.

### Dependencies

 - Ruby >= 2.1.0

At a high level, the Ruby components integrate with the [`html-pipeline`](https://github.com/jch/html-pipeline) library. The frontend components are vanilla JavaScript and include a thin jQuery wrapper that supports the original plugin interface. The frontend components are written in CoffeeScript and need to be preprocessed for production use.

[A polyfill for custom events](https://github.com/krambuhl/custom-event-polyfill) must be included to support IE10 and below.

### Known issues

The markdown parser used on the front end produces false positives when looking for checkboxes
in some complex nesting situations. To combat this issue, you can enable the `sourcepos` option
in your markdown parser. This will avoid parsing the markdown on the front end, because the line
numbers will be provided as attributes on the HTML elements. `task_list` checks for the source
position attribute and falls back to manually parsing the markown when needed.

### Upgrading

#### 1.x to 2.x

The event interface no longer passes data directly to the callbacks arguments
list. Instead the CustomEvent API is used, which adds data to the
`event.detail` object.

```js
// 1.x interface
el.on('tasklist:changed', function(event, index, checked) {
  console.log(index, checked)
})

// 2.x interface
el.on('tasklist:changed', function(event) {
  console.log(event.detail.index, event.detail.checked)
})
```

## Testing and Development

JavaScript unit tests can be run with `script/testsuite`.

Ruby unit tests can be run with `rake test`.

Functional tests are useful for manual testing in the browser. To run, install
the necessary components with `script/bootstrap` then run the server:

```
rackup -p 4011
```

Navigate to http://localhost:4011/test/functional/test_task_lists_behavior.html

## Community Integration
- [Waffle.io](http://waffle.io)
- [HuBoard](https://huboard.com/)
