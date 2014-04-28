# View class to control how At.js's view showing.
# All classes share the same DOM view.
class View

  # @param controller [Object] The Controller.
  constructor: (@context) ->
    @$el = $("<div class='atwho-view'><ul class='atwho-view-ul'></ul></div>")
    @timeout_id = null
    # create HTML DOM of list view if it does not exist
    @context.$el.append(@$el)
    this.bind_event()

  init: ->
    id = @context.get_opt("alias") || @context.at.charCodeAt(0)
    @$el.attr('id': "at-view-#{id}")

  destroy: ->
    @$el.remove()

  bind_event: ->
    $menu = @$el.find('ul')
    $menu.on 'mouseenter.atwho-view','li', (e) ->
      $menu.find('.cur').removeClass 'cur'
      $(e.currentTarget).addClass 'cur'
    .on 'click', (e) =>
      this.choose()
      e.preventDefault()

  # Check if view is visible
  #
  # @return [Boolean]
  visible: ->
    @$el.is(":visible")

  choose: ->
    if ($li = @$el.find ".cur").length
      content = @context.insert_content_for $li
      @context.insert @context.callbacks("before_insert").call(@context, content, $li), $li
      @context.trigger "inserted", [$li]
      this.hide()

  reposition: (rect) ->
    if rect.bottom + @$el.height() - $(window).scrollTop() > $(window).height()
        rect.bottom = rect.top - @$el.height()
    offset = {left:rect.left, top:rect.bottom}
    @context.callbacks("before_reposition")?.call(@context, offset)
    @$el.offset offset
    @context.trigger "reposition", [offset]

  next: ->
    cur = @$el.find('.cur').removeClass('cur')
    next = cur.next()
    next = @$el.find('li:first') if not next.length
    next.addClass 'cur'

  prev: ->
    cur = @$el.find('.cur').removeClass('cur')
    prev = cur.prev()
    prev = @$el.find('li:last') if not prev.length
    prev.addClass 'cur'

  show: ->
    @context.mark_range()
    if not this.visible()
      @$el.show()
      @context.trigger 'shown'
    this.reposition(rect) if rect = @context.rect()

  hide: (time) ->
    if isNaN time and this.visible()
      @context.reset_rect()
      @$el.hide()
      @context.trigger 'hidden'
    else
      callback = => this.hide()
      clearTimeout @timeout_id
      @timeout_id = setTimeout callback, time

  # render list view
  render: (list) ->
    if not ($.isArray(list) and list.length > 0)
      this.hide()
      return

    @$el.find('ul').empty()
    $ul = @$el.find('ul')
    tpl = @context.get_opt('tpl')

    for item in list
      item = $.extend {}, item, {'atwho-at': @context.at}
      li = @context.callbacks("tpl_eval").call(@context, tpl, item)
      $li = $ @context.callbacks("highlighter").call(@context, li, @context.query.text)
      $li.data("item-data", item)
      $ul.append $li

    this.show()
    $ul.find("li:first").addClass "cur" if @context.get_opt('highlight_first')
