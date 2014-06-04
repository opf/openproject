# At.js central contoller(searching, matching, evaluating and rendering.)
class App

  # @param inputor [HTML DOM Object] `input` or `textarea`
  constructor: (inputor) ->
    @current_flag = null
    @controllers = {}
    @alias_maps = {}
    @$inputor = $(inputor)
    @iframe = null
    this.setIframe()
    this.listen()

  setIframe: (iframe) ->
    if iframe
      @window = iframe.contentWindow
      @document = iframe.contentDocument || @window.document
      @iframe = iframe
      this
    else
      @document = @$inputor[0].ownerDocument
      @window = @document.defaultView || @document.parentWindow
      try
        @iframe = @window.frameElement
      catch error
        # throws error in cross-domain iframes

  controller: (at) ->
    @controllers[@alias_maps[at] || at || @current_flag]

  set_context_for: (at) ->
    @current_flag = at
    this

  # At.js can register multiple at char (flag) to every inputor such as "@" and ":"
  # Along with their own `settings` so that it works differently.
  # After register, we still can update their `settings` such as updating `data`
  #
  # @param flag [String] at char (flag)
  # @param settings [Hash] the settings
  reg: (flag, setting) ->
    controller = @controllers[flag] ||= new Controller(this, flag)
    # TODO: it will produce rubbish alias map, reduse this.
    @alias_maps[setting.alias] = flag if setting.alias
    controller.init setting
    this

  # binding jQuery events of `inputor`'s
  listen: ->
    @$inputor
      .on 'keyup.atwhoInner', (e) =>
        this.on_keyup(e)
      .on 'keydown.atwhoInner', (e) =>
        this.on_keydown(e)
      .on 'scroll.atwhoInner', (e) =>
        this.controller()?.view.hide()
      .on 'blur.atwhoInner', (e) =>
        c.view.hide(c.get_opt("display_timeout")) if c = this.controller()

  shutdown: ->
    for _, c of @controllers
      c.destroy() 
      delete @controllers[_]
    @$inputor.off '.atwhoInner'

  dispatch: ->
    $.map @controllers, (c) =>
      if delay = c.get_opt('delay')
        clearTimeout @delayedCallback
        @delayedCallback = setTimeout(=>
          this.set_context_for c.at if c.look_up()
        , delay)
      else
        this.set_context_for c.at if c.look_up()

  on_keyup: (e) ->
    switch e.keyCode
      when KEY_CODE.ESC
        e.preventDefault()
        this.controller()?.view.hide()
      when KEY_CODE.DOWN, KEY_CODE.UP, KEY_CODE.CTRL
        $.noop()
      when KEY_CODE.P, KEY_CODE.N
        this.dispatch() if not e.ctrlKey
      else
        this.dispatch()
    # coffeescript will return everywhere!!
    return

  on_keydown: (e) ->
    # return if not (view = this.controller().view).visible()
    view = this.controller()?.view
    return if not (view and view.visible())
    switch e.keyCode
      when KEY_CODE.ESC
        e.preventDefault()
        view.hide()
      when KEY_CODE.UP
        e.preventDefault()
        view.prev()
      when KEY_CODE.DOWN
        e.preventDefault()
        view.next()
      when KEY_CODE.P
        return if not e.ctrlKey
        e.preventDefault()
        view.prev()
      when KEY_CODE.N
        return if not e.ctrlKey
        e.preventDefault()
        view.next()
      when KEY_CODE.TAB, KEY_CODE.ENTER
        return if not view.visible()
        e.preventDefault()
        view.choose()
      else
        $.noop()
    return
