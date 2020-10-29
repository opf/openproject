window.$ = window.jQuery = require('jquery')
window.TaskList = require('../../app/assets/javascripts/task_list')

QUnit.module "TaskList updates",
  beforeEach: ->
    @container = $ '<div>', class: 'js-task-list-container'

    @list = $ '<ul>', class: 'task-list'

    @completeItem = $ '<li>', class: 'task-list-item'
    @completeCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: true

    @incompleteItem = $ '<li>', class: 'task-list-item'
    @incompleteCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: false

    # non-breaking space. See: https://github.com/github/task-lists/pull/14
    @nbsp = String.fromCharCode(160)
    @incompleteNBSPItem = $ '<li>', class: 'task-list-item'
    @incompleteNBSPCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: false

    @blockquote = $ '<blockquote>'

    @quotedList = $ '<ul>', class: 'task-list'

    @quotedCompleteItem = $ '<li>', class: 'task-list-item'
    @quotedCompleteCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: true

    @quotedIncompleteItem = $ '<li>', class: 'task-list-item'
    @quotedIncompleteCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: false

    @innerBlockquote = $ '<blockquote>'

    @innerList = $ '<ul>', class: 'task-list'

    @innerCompleteItem = $ '<li>', class: 'task-list-item'
    @innerCompleteCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: true

    @innerIncompleteItem = $ '<li>', class: 'task-list-item'
    @innerIncompleteCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: false

    @orderedList = $ '<ol>', class: 'task-list'

    @orderedCompleteItem = $ '<li>', class: 'task-list-item'
    @orderedCompleteCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: true

    @orderedIncompleteItem = $ '<li>', class: 'task-list-item'
    @orderedIncompleteCheckbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: false

    @field = $ '<textarea>', class: 'js-task-list-field', text: """
      - [x] complete
      - [ ] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [x] quoted complete
      > - [ ] quoted incomplete
      >> - [x] inner complete
      > > - [ ] inner incomplete
      > 0. [x] ordered complete
      > 0. [ ] ordered incomplete
    """

    @changes =
      toComplete: """
      - [ ] complete
      - [ ] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [x] quoted complete
      > - [ ] quoted incomplete
      >> - [x] inner complete
      > > - [ ] inner incomplete
      > 0. [x] ordered complete
      > 0. [ ] ordered incomplete
      """
      toQuotedComplete: """
      - [x] complete
      - [ ] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [ ] quoted complete
      > - [ ] quoted incomplete
      >> - [x] inner complete
      > > - [ ] inner incomplete
      > 0. [x] ordered complete
      > 0. [ ] ordered incomplete
      """
      toInnerComplete: """
      - [x] complete
      - [ ] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [x] quoted complete
      > - [ ] quoted incomplete
      >> - [ ] inner complete
      > > - [ ] inner incomplete
      > 0. [x] ordered complete
      > 0. [ ] ordered incomplete
      """
      toOrderedComplete: """
      - [x] complete
      - [ ] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [x] quoted complete
      > - [ ] quoted incomplete
      >> - [x] inner complete
      > > - [ ] inner incomplete
      > 0. [ ] ordered complete
      > 0. [ ] ordered incomplete
      """
      toIncomplete: """
      - [x] complete
      - [x] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [x] quoted complete
      > - [ ] quoted incomplete
      >> - [x] inner complete
      > > - [ ] inner incomplete
      > 0. [x] ordered complete
      > 0. [ ] ordered incomplete
      """
      toQuotedIncomplete: """
      - [x] complete
      - [ ] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [x] quoted complete
      > - [x] quoted incomplete
      >> - [x] inner complete
      > > - [ ] inner incomplete
      > 0. [x] ordered complete
      > 0. [ ] ordered incomplete
      """
      toInnerIncomplete: """
      - [x] complete
      - [ ] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [x] quoted complete
      > - [ ] quoted incomplete
      >> - [x] inner complete
      > > - [x] inner incomplete
      > 0. [x] ordered complete
      > 0. [ ] ordered incomplete
      """
      toOrderedIncomplete: """
      - [x] complete
      - [ ] incomplete
      - [#{@nbsp}] incompleteNBSP
      > - [x] quoted complete
      > - [ ] quoted incomplete
      >> - [x] inner complete
      > > - [ ] inner incomplete
      > 0. [x] ordered complete
      > 0. [x] ordered incomplete
      """
      toIncompleteNBSP: """
      - [x] complete
      - [ ] incomplete
      - [x] incompleteNBSP
      > - [x] quoted complete
      > - [ ] quoted incomplete
      >> - [x] inner complete
      > > - [ ] inner incomplete
      > 0. [x] ordered complete
      > 0. [ ] ordered incomplete
      """

    @completeItem.append @completeCheckbox
    @list.append @completeItem
    @completeItem.expectedIndex = 1

    @incompleteItem.append @incompleteCheckbox
    @list.append @incompleteItem
    @incompleteItem.expectedIndex = 2

    @incompleteNBSPItem.append @incompleteNBSPCheckbox
    @list.append @incompleteNBSPItem
    @incompleteNBSPItem.expectedIndex = 3

    @container.append @list
    @container.append @field

    @quotedCompleteItem.append @quotedCompleteCheckbox
    @quotedList.append @quotedCompleteItem
    @quotedCompleteItem.expectedIndex = 4

    @quotedIncompleteItem.append @quotedIncompleteCheckbox
    @quotedList.append @quotedIncompleteItem
    @quotedIncompleteItem.expectedIndex = 5

    @blockquote.append @quotedList

    @innerCompleteItem.append @innerCompleteCheckbox
    @innerList.append @innerCompleteItem
    @innerCompleteItem.expectedIndex = 6

    @innerIncompleteItem.append @innerIncompleteCheckbox
    @innerList.append @innerIncompleteItem
    @innerIncompleteItem.expectedIndex = 7

    @innerBlockquote.append @innerList
    @innerBlockquote.append @innerField

    @blockquote.append @innerBlockquote

    @container.append @blockquote

    @orderedCompleteItem.append @orderedCompleteCheckbox
    @orderedList.append @orderedCompleteItem
    @orderedCompleteItem.expectedIndex = 8

    @orderedIncompleteItem.append @orderedIncompleteCheckbox
    @orderedList.append @orderedIncompleteItem
    @orderedIncompleteItem.expectedIndex = 9

    @container.append @orderedList

    @blockquote.append @field

    @completeItemSourcePos = '1:1-1:14'
    @incompleteItemSourcePos = '2:1-2:16'
    @incompleteNBSPItemSourcePos = '3:1-3:27'
    @quotedCompleteItemSourcePos = '4:3-4:23'
    @quotedIncompleteItemSourcePos = '5:3-5:25'
    @innerCompleteItemSourcePos = '6:4-6:23'
    @innerIncompleteItemSourcePos = '7:5-7:26'
    @orderedCompleteItemSourcePos = '8:3-8:25'
    @orderedIncompleteItemSourcePos = '9:3-9:27'

    $('#qunit-fixture').append(@container)
    @container.taskList()

    @setSourcePosition = (item, pos) =>
      item.attr('data-sourcepos', pos)

    @onChanged = (assert) =>
      utils =
      test: (fn) =>
        done = assert.async()
        @field.on 'tasklist:changed', (event) =>
          fn event
          done()
      eventHas: (name, value) =>
        utils.test (event) =>
          assert.equal event.detail[name], value
      fieldIs: (value) =>
        utils.test () =>
          assert.equal @field.val(), value

  afterEach: ->
    $(document).off 'tasklist:changed'

QUnit.test "updates the source, marking the incomplete item as complete", (assert) ->
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @incompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toIncomplete)

  @incompleteCheckbox.click()

QUnit.test "updates the source, marking the incomplete item as complete (sourcepos)", (assert) ->
  @setSourcePosition(@incompleteItem, @incompleteItemSourcePos)
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @incompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toIncomplete)

  @incompleteCheckbox.click()

QUnit.test "updates the source, marking the complete item as incomplete", (assert) ->
  @onChanged(assert).eventHas('checked', false)
  @onChanged(assert).eventHas('index', @completeItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toComplete)

  @completeCheckbox.click()

QUnit.test "updates the source, marking the complete item as incomplete (sourcepos)", (assert) ->
  @setSourcePosition(@completeItem, @completeItemSourcePos)
  @onChanged(assert).eventHas('checked', false)
  @onChanged(assert).eventHas('index', @completeItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toComplete)

  @completeCheckbox.click()

# See: https://github.com/github/task-lists/pull/14
QUnit.test "updates the source for items with non-breaking spaces", (assert) ->
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @incompleteNBSPItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toIncompleteNBSP)

  @incompleteNBSPCheckbox.click()

# See: https://github.com/github/task-lists/pull/14
QUnit.test "updates the source for items with non-breaking spaces (sourcepos)", (assert) ->
  @setSourcePosition(@incompleteNBSPItem, @incompleteNBSPItemSourcePos)
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @incompleteNBSPItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toIncompleteNBSP)

  @incompleteNBSPCheckbox.click()

QUnit.test "updates the source of a quoted item, marking the incomplete item as complete", (assert) ->
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @quotedIncompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toQuotedIncomplete)

  @quotedIncompleteCheckbox.click()

QUnit.test "updates the source of a quoted item, marking the incomplete item as complete (sourcepos)", (assert) ->
  @setSourcePosition(@quotedIncompleteItem, @quotedIncompleteItemSourcePos)
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @quotedIncompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toQuotedIncomplete)

  @quotedIncompleteCheckbox.click()

QUnit.test "updates the source of a quoted item, marking the complete item as incomplete", (assert) ->
  @onChanged(assert).eventHas('checked', false)
  @onChanged(assert).eventHas('index', @quotedCompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toQuotedComplete)

  @quotedCompleteCheckbox.click()

QUnit.test "updates the source of a quoted item, marking the complete item as incomplete (sourcepos)", (assert) ->
  @setSourcePosition(@quotedCompleteItem, @quotedCompleteItemSourcePos)
  @onChanged(assert).eventHas('checked', false)
  @onChanged(assert).eventHas('index', @quotedCompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toQuotedComplete)

  @quotedCompleteCheckbox.click()

QUnit.test "updates the source of a quoted quoted item, marking the incomplete item as complete", (assert) ->
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @innerIncompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toInnerIncomplete)

  @innerIncompleteCheckbox.click()

QUnit.test "updates the source of a quoted quoted item, marking the incomplete item as complete (sourcepos)", (assert) ->
  @setSourcePosition(@innerIncompleteItem, @innerIncompleteItemSourcePos)
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @innerIncompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toInnerIncomplete)

  @innerIncompleteCheckbox.click()

QUnit.test "updates the source of a quoted quoted item, marking the complete item as incomplete", (assert) ->
  @onChanged(assert).eventHas('checked', false)
  @onChanged(assert).eventHas('index', @innerCompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toInnerComplete)

  @innerCompleteCheckbox.click()

QUnit.test "updates the source of a quoted quoted item, marking the complete item as incomplete (sourcepos)", (assert) ->
  @setSourcePosition(@innerCompleteItem, @innerCompleteItemSourcePos)
  @onChanged(assert).eventHas('checked', false)
  @onChanged(assert).eventHas('index', @innerCompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toInnerComplete)

  @innerCompleteCheckbox.click()

QUnit.test "updates the source of an ordered list item, marking the incomplete item as complete", (assert) ->
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @orderedIncompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toOrderedIncomplete)

  @orderedIncompleteCheckbox.click()

QUnit.test "updates the source of an ordered list item, marking the incomplete item as complete (sourcepos)", (assert) ->
  @setSourcePosition(@orderedIncompleteItem, @orderedIncompleteItemSourcePos)
  @onChanged(assert).eventHas('checked', true)
  @onChanged(assert).eventHas('index', @orderedIncompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toOrderedIncomplete)

  @orderedIncompleteCheckbox.click()

QUnit.test "updates the source of an ordered list item, marking the complete item as incomplete", (assert) ->
  @onChanged(assert).eventHas('checked', false)
  @onChanged(assert).eventHas('index', @orderedCompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toOrderedComplete)

  @orderedCompleteCheckbox.click()

QUnit.test "updates the source of an ordered list item, marking the complete item as incomplete (sourcepos)", (assert) ->
  @setSourcePosition(@orderedCompleteItem, @orderedCompleteItemSourcePos)
  @onChanged(assert).eventHas('checked', false)
  @onChanged(assert).eventHas('index', @orderedCompleteItem.expectedIndex)
  @onChanged(assert).fieldIs(@changes.toOrderedComplete)

  @orderedCompleteCheckbox.click()

QUnit.test "update ignores items that look like Task List items but lack list prefix", (assert) ->
  assertItemsLackListPrefix(assert, null, null)

QUnit.test "update ignores items that look like Task List items but lack list prefix (sourcepos)", (assert) ->
  assertItemsLackListPrefix(assert, '3:1-3:11', '4:1-4:10')

assertItemsLackListPrefix =(assert, sourcepos1, sourcepos2) ->
  done = assert.async()
  assert.expect 3

  $('#qunit-fixture').empty()

  container = $ '<div>', class: 'js-task-list-container'

  list = $ '<ul>', class: 'task-list'

  item1 = $ '<li>', class: 'task-list-item'
  item1.attr('data-sourcepos', sourcepos1) if sourcepos1
  item1Checkbox = $ '<input>',
    type: 'checkbox'
    class: 'task-list-item-checkbox'
    disabled: true
    checked: false

  item2 = $ '<li>', class: 'task-list-item'
  item2.attr('data-sourcepos', sourcepos2) if sourcepos2
  item2Checkbox = $ '<input>',
    type: 'checkbox'
    class: 'task-list-item-checkbox'
    disabled: true
    checked: false

  field = $ '<textarea>', class: 'js-task-list-field', text: """
    [ ] one
    [ ] two
    - [ ] three
    - [ ] four
  """

  changes = """
    [ ] one
    [ ] two
    - [ ] three
    - [x] four
  """

  item1.append item1Checkbox
  list.append item1
  item1.expectedIndex = 1

  item2.append item2Checkbox
  list.append item2
  item2.expectedIndex = 2

  container.append list
  container.append field

  $('#qunit-fixture').append(container)
  container.taskList()

  field.on 'tasklist:changed', (event) =>
    assert.ok event.detail.checked
    assert.equal event.detail.index, item2.expectedIndex
    assert.equal field.val(), changes
    done()

  item2Checkbox.click()

QUnit.test "update ignores items that look like Task List items but are links", (assert) ->
  assertItemsButAreLinks(assert, null, null)

QUnit.test "update ignores items that look like Task List items but are links (sourcepos)", (assert) ->
  assertItemsButAreLinks(assert, '5:1-5:24', '6:1-6:10')

assertItemsButAreLinks =(assert, sourcepos1, sourcepos2) ->
  done = assert.async()
  assert.expect 3

  $('#qunit-fixture').empty()

  container = $ '<div>', class: 'js-task-list-container'

  list = $ '<ul>', class: 'task-list'

  item1 = $ '<li>', class: 'task-list-item'
  item1.attr('data-sourcepos', sourcepos1) if sourcepos1
  item1Checkbox = $ '<input>',
    type: 'checkbox'
    class: 'task-list-item-checkbox'
    disabled: true
    checked: false

  item2 = $ '<li>', class: 'task-list-item'
  item2.attr('data-sourcepos', sourcepos2) if sourcepos2
  item2Checkbox = $ '<input>',
    type: 'checkbox'
    class: 'task-list-item-checkbox'
    disabled: true
    checked: false

  field = $ '<textarea>', class: 'js-task-list-field', text: """
    - [ ](link)
    - [ ][reference]
    - [ ]() collapsed
    - [ ][] collapsed reference
    - [ ] (no longer a link)
    - [ ] item
  """

  changes = """
    - [ ](link)
    - [ ][reference]
    - [ ]() collapsed
    - [ ][] collapsed reference
    - [ ] (no longer a link)
    - [x] item
  """

  item1.append item1Checkbox
  list.append item1
  item1.expectedIndex = 1

  item2.append item2Checkbox
  list.append item2
  item2.expectedIndex = 2

  container.append list
  container.append field

  $('#qunit-fixture').append(container)
  container.taskList()

  field.on 'tasklist:changed', (event) =>
    assert.ok event.detail.checked
    assert.equal event.detail.index, item2.expectedIndex
    assert.equal field.val(), changes
    done()

  item2Checkbox.click()

QUnit.test "updates items followed by links", (assert) ->
  assertItemsFollowedByLinks(assert, null, null)

QUnit.test "updates items followed by links (sourcepos)", (assert) ->
  assertItemsFollowedByLinks(assert, '1:1-1:24', '2:1-3:0')

assertItemsFollowedByLinks =(assert, sourcepos1, sourcepos2) ->
  done = assert.async()
  assert.expect 3

  $('#qunit-fixture').empty()

  container = $ '<div>', class: 'js-task-list-container'

  list = $ '<ul>', class: 'task-list'

  item1 = $ '<li>', class: 'task-list-item'
  item1.attr('data-sourcepos', sourcepos1) if sourcepos1
  item1Checkbox = $ '<input>',
    type: 'checkbox'
    class: 'task-list-item-checkbox'
    disabled: true
    checked: false

  item2 = $ '<li>', class: 'task-list-item'
  item2.attr('data-sourcepos', sourcepos2) if sourcepos2
  item2Checkbox = $ '<input>',
    type: 'checkbox'
    class: 'task-list-item-checkbox'
    disabled: true
    checked: false

  field = $ '<textarea>', class: 'js-task-list-field', text: """
    - [ ] [link label](link)
    - [ ] [reference label][reference]
  """

  changes = """
    - [ ] [link label](link)
    - [x] [reference label][reference]
  """

  item1.append item1Checkbox
  list.append item1
  item1.expectedIndex = 1

  item2.append item2Checkbox
  list.append item2
  item2.expectedIndex = 2

  container.append list
  container.append field

  $('#qunit-fixture').append(container)
  container.taskList()

  field.on 'tasklist:changed', (event) =>
    assert.ok event.detail.checked
    assert.equal event.detail.index, item2.expectedIndex
    assert.equal field.val(), changes
    done()

  item2Checkbox.click()

# See https://github.com/deckar01/task_list/issues/3
QUnit.test "doesn't update items inside code blocks", (assert) ->
  assertItemsInsideCodeBlocks(assert, null, null)

QUnit.test "doesn't update items inside code blocks (sourcepos)", (assert) ->
  assertItemsInsideCodeBlocks(assert, '6:1-6:11', '7:1-7:11')

assertItemsInsideCodeBlocks =(assert, sourcepos1, sourcepos2) ->
  done = assert.async()
  assert.expect 3

  container = $ '<div>', class: 'js-task-list-container'

  list = $ '<ul>', class: 'task-list'

  item1 = $ '<li>', class: 'task-list-item'
  item1.attr('data-sourcepos', sourcepos1) if sourcepos1
  item1Checkbox = $ '<input>',
    type: 'checkbox'
    class: 'task-list-item-checkbox'
    disabled: true
    checked: false

  item2 = $ '<li>', class: 'task-list-item'
  item2.attr('data-sourcepos', sourcepos2) if sourcepos2
  item2Checkbox = $ '<input>',
    type: 'checkbox'
    class: 'task-list-item-checkbox'
    disabled: true
    checked: false

  field = $ '<textarea>', class: 'js-task-list-field', text: """
    ```
    - [ ] test1
    - [ ] test2
    ```

    - [ ] test1
    - [ ] test2
  """

  changes = """
    ```
    - [ ] test1
    - [ ] test2
    ```

    - [ ] test1
    - [x] test2
  """

  item1.append item1Checkbox
  list.append item1
  item1.expectedIndex = 1

  item2.append item2Checkbox
  list.append item2
  item2.expectedIndex = 2

  container.append list
  container.append field

  $('#qunit-fixture').append(container)
  container.taskList()

  field.on 'tasklist:changed', (event) =>
    assert.ok event.detail.checked
    assert.equal event.detail.index, item2.expectedIndex
    assert.equal field.val(), changes
    done()

  item2Checkbox.click()
