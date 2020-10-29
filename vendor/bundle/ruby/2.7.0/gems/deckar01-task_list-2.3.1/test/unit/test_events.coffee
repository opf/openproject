window.$ = window.jQuery = require('jquery')
window.TaskList = require('../../app/assets/javascripts/task_list')

QUnit.module "TaskList events",
  beforeEach: ->
    @container = $ '<div>', class: 'js-task-list-container'

    @list = $ '<ul>', class: 'task-list'
    @item = $ '<li>', class: 'task-list-item'
    @checkbox = $ '<input>',
      type: 'checkbox'
      class: 'task-list-item-checkbox'
      disabled: true
      checked: false

    @field = $ '<textarea>', class: 'js-task-list-field', "- [ ] text"

    @item.append @checkbox
    @list.append @item
    @container.append @list

    @container.append @field

    $('#qunit-fixture').append(@container)
    @container.taskList()

  afterEach: ->
    $(document).off 'tasklist:enabled'
    $(document).off 'tasklist:disabled'
    $(document).off 'tasklist:change'
    $(document).off 'tasklist:changed'

QUnit.test "triggers a tasklist:change event before making task list item changes", (assert) ->
  done = assert.async()
  assert.expect 1

  @field.on 'tasklist:change', (event, index, checked) ->
    assert.ok true
    done()

  @checkbox.click()

QUnit.test "triggers a tasklist:changed event once a task list item changes", (assert) ->
  done = assert.async()
  assert.expect 1

  @field.on 'tasklist:changed', (event, index, checked) ->
    assert.ok true
    done()

  @checkbox.click()

QUnit.test "can cancel a tasklist:changed event", (assert) ->
  done = assert.async()
  done2 = assert.async()
  assert.expect 2

  @field.on 'tasklist:change', (event, index, checked) ->
    assert.ok true
    event.preventDefault()
    done2()

  @field.on 'tasklist:changed', (event, index, checked) ->
    assert.ok false

  before = @checkbox.val()
  setTimeout =>
    assert.ok true
    done()
  , 20

  @checkbox.click()

QUnit.test "enables task list items when a .js-task-list-field is present", (assert) ->
  done = assert.async()
  assert.expect 1

  $(document).on 'tasklist:enabled', (event) ->
    assert.ok true
    done()
  
  @container.taskList()

QUnit.test "doesn't enable task list items when a .js-task-list-field is absent", (assert) ->
  done = assert.async()
  assert.expect 1

  $(document).on 'tasklist:enabled', (event) ->
    assert.ok false

  @field.remove()

  @container.taskList()

  setTimeout =>
    assert.ok true
    done()
  , 20
