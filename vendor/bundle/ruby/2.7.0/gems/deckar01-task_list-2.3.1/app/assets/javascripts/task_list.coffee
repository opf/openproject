# TaskList Behavior
#
#= provides TaskList
#
# Enables Task List update behavior.
#
# ### Example Markup
#
#   <div class="js-task-list-container">
#     <ul class="task-list">
#       <li class="task-list-item">
#         <input type="checkbox" class="js-task-list-item-checkbox" disabled />
#         text
#       </li>
#     </ul>
#     <form>
#       <textarea class="js-task-list-field">- [ ] text</textarea>
#     </form>
#   </div>
#
# ### Specification
#
# TaskLists MUST be contained in a `(div).js-task-list-container`.
#
# TaskList Items SHOULD be an a list (`UL`/`OL`) element.
#
# Task list items MUST match `(input).task-list-item-checkbox` and MUST be
# `disabled` by default.
#
# TaskLists MUST have a `(textarea).js-task-list-field` form element whose
# `value` attribute is the source (Markdown) to be udpated. The source MUST
# follow the syntax guidelines.
#
# TaskList updates trigger `tasklist:change` events. If the change is
# successful, `tasklist:changed` is fired. The change can be canceled.
#
# ### Methods
#
# `.taskList('enable')` or `.taskList()`
#
# Enables TaskList updates for the container.
#
# `.taskList('disable')`
#
# Disables TaskList updates for the container.
#
## ### Events
#
# `tasklist:enabled`
#
# Fired when the TaskList is enabled.
#
# * **Synchronicity** Sync
# * **Bubbles** Yes
# * **Cancelable** No
# * **Target** `.js-task-list-container`
#
# `tasklist:disabled`
#
# Fired when the TaskList is disabled.
#
# * **Synchronicity** Sync
# * **Bubbles** Yes
# * **Cancelable** No
# * **Target** `.js-task-list-container`
#
# `tasklist:change`
#
# Fired before the TaskList item change takes affect.
#
# * **Synchronicity** Sync
# * **Bubbles** Yes
# * **Cancelable** Yes
# * **Target** `.js-task-list-field`
#
# `tasklist:changed`
#
# Fired once the TaskList item change has taken affect.
#
# * **Synchronicity** Sync
# * **Bubbles** Yes
# * **Cancelable** No
# * **Target** `.js-task-list-field`
#
# ### NOTE
#
# Task list checkboxes are rendered as disabled by default because rendered
# user content is cached without regard for the viewer.

NodeArray = (nodeList) -> Array.prototype.slice.apply(nodeList)

closest = (el, className) ->
  while el && !el.classList.contains className
    el = el.parentNode
  el

createEvent = (eventName, detail) ->
  if typeof Event == 'function'
    event = new Event eventName, {bubbles: true, cancelable: true}
    event.detail = detail
  else
    event = document.createEvent 'CustomEvent'
    event.initCustomEvent eventName, true, true, detail
  event

class TaskList
  constructor: (@el) ->
    @container = closest @el, 'js-task-list-container'
    @field = @container.querySelector '.js-task-list-field'
    # When the task list item checkbox is updated, submit the change
    @container.addEventListener 'change', (event) =>
      if event.target.classList.contains 'task-list-item-checkbox'
        @updateTaskList(event.target)
    @.enable()

  enable: ->
    if @container.querySelectorAll('.js-task-list-field').length > 0
      NodeArray(@container.querySelectorAll('.task-list-item')).
      forEach (item) ->
        item.classList.add('enabled')
      NodeArray(@container.querySelectorAll('.task-list-item-checkbox')).
      forEach (checkbox) ->
        checkbox.disabled = false
      @container.classList.add 'is-task-list-enabled'
      event = createEvent 'tasklist:enabled'
      @container.dispatchEvent event

  disable: ->
    NodeArray(@container.querySelectorAll('.task-list-item')).
    forEach (item) ->
      item.classList.remove('enabled')
    NodeArray(@container.querySelectorAll('.task-list-item-checkbox')).
    forEach (checkbox) ->
      checkbox.disabled = true
    @container.classList.remove('is-task-list-enabled')
    event = createEvent 'tasklist:disabled'
    @container.dispatchEvent event

  # Updates the field value to reflect the state of item.
  # Triggers the `tasklist:change` event before the value has changed, and fires
  # a `tasklist:changed` event once the value has changed.
  updateTaskList: (item) ->
    checkboxes = @container.querySelectorAll('.task-list-item-checkbox')
    index = 1 + NodeArray(checkboxes).indexOf item

    changeEvent = createEvent 'tasklist:change',
      index: index
      checked: item.checked
    @field.dispatchEvent changeEvent

    unless changeEvent.defaultPrevented
      { result, lineNumber, lineSource } =
        TaskList.updateSource(@field.value, index, item.checked, item)

      @field.value = result
      changeEvent = createEvent 'change'
      @field.dispatchEvent changeEvent
      changedEvent = createEvent 'tasklist:changed', {
        index: index
        checked: item.checked
        lineNumber: lineNumber
        lineSource: lineSource
      }
      @field.dispatchEvent changedEvent

  # Static interface

  @incomplete: "[ ]"
  @complete: "[x]"

  # Escapes the String for regular expression matching.
  @escapePattern: (str) ->
    str.
      replace(/([\[\]])/g, "\\$1"). # escape square brackets
      replace(/\s/, "\\s").         # match all white space
      replace("x", "[xX]")          # match all cases

  @incompletePattern: ///
    #{@escapePattern(@incomplete)}
  ///
  @completePattern: ///
    #{@escapePattern(@complete)}
  ///

  # Pattern used to identify all task list items.
  # Useful when you need iterate over all items.
  @itemPattern: ///
    ^
    (?:                     # prefix, consisting of
      \s*                   # optional leading whitespace
      (?:>\s*)*             # zero or more blockquotes
      (?:[-+*]|(?:\d+\.))   # list item indicator
    )
    \s*                     # optional whitespace prefix
    (                       # checkbox
      #{@escapePattern(@complete)}|
      #{@escapePattern(@incomplete)}
    )
    \s                      # is followed by whitespace
  ///

  # Used to skip checkbox markup inside of code fences.
  # http://rubular.com/r/TfCDNsy8x4
  @startFencesPattern: /^`{3}.*$/
  @endFencesPattern: /^`{3}$/

  # Used to filter out potential mismatches (items not in lists).
  # http://rubular.com/r/OInl6CiePy
  @itemsInParasPattern: ///
    ^
    (
      #{@escapePattern(@complete)}|
      #{@escapePattern(@incomplete)}
    )
    .+
    $
  ///g

  # Given the source text, updates the appropriate task list item to match the
  # given checked value.
  #
  # Returns the updated String text.
  @updateSource: (source, itemIndex, checked, item) ->
    if item.parentElement.hasAttribute('data-sourcepos')
      @_updateSourcePosition(source, item, checked)
    else
      @_updateSourceRegex(source, itemIndex, checked)

  # If we have sourcepos information, that tells us which line the task
  # is on without the need for parsing
  @_updateSourcePosition: (source, item, checked) ->
    result = source.split("\n")
    sourcepos = item.parentElement.getAttribute('data-sourcepos')
    lineNumber = parseInt(sourcepos.split(":")[0])
    lineSource = result[lineNumber - 1]

    line =
      if checked
        lineSource.replace(@incompletePattern, @complete)
      else
        lineSource.replace(@completePattern, @incomplete)

    result[lineNumber - 1] = line

    return {
      result: result.join("\n")
      lineNumber: lineNumber
      lineSource: lineSource
    }

  @_updateSourceRegex: (source, itemIndex, checked) ->
    split_source = source.split("\n")
    lineNumber
    lineSource

    clean = source.replace(/\r/g, '').
      replace(@itemsInParasPattern, '').
      split("\n")
    index = 0
    inCodeBlock = false

    result = for line, i in split_source
      if inCodeBlock
        # Lines inside of a code block are ignored.
        if line.match(@endFencesPattern)
          # Stop ignoring lines once the code block is closed.
          inCodeBlock = false
      else if line.match(@startFencesPattern)
        # Start ignoring lines inside a code block.
        inCodeBlock = true
      else if line in clean && line.trim().match(@itemPattern)
        index += 1
        if index == itemIndex
          lineNumber = i + 1
          lineSource = line
          line =
            if checked
              line.replace(@incompletePattern, @complete)
            else
              line.replace(@completePattern, @incomplete)
      line

    return {
      result: result.join("\n")
      lineNumber: lineNumber
      lineSource: lineSource
    }

if typeof jQuery != 'undefined'
  jQuery.fn.taskList = (method) ->
    this.each (index, el) ->
      taskList = jQuery(el).data('task-list')
      if !taskList
        taskList = new TaskList el
        jQuery(el).data 'task-list', taskList
        if !method || method == 'enable'
          return

      taskList[method || 'enable']()

module.exports = TaskList
