###
  Implement Github like autocomplete mentions
  http://ichord.github.com/At.js

  Copyright (c) 2013 chord.luo@gmail.com
  Licensed under the MIT license.
###

###
本插件操作 textarea 或者 input 内的插入符
只实现了获得插入符在文本框中的位置，我设置
插入符的位置.
###
( (factory) ->
  # Uses AMD or browser globals to create a jQuery plugin.
  # It does not try to register in a CommonJS environment since
  # jQuery is not likely to run in those environments.
  #
  # form [umd](https://github.com/umdjs/umd) project
  if typeof define is 'function' and define.amd
    # Register as an anonymous AMD module:
    define ['jquery'], factory
  else
    # Browser globals
    factory window.jQuery
) ($) ->

  "use strict";

  pluginName = 'caret'

  class EditableCaret
    constructor: (@$inputor) ->
      @domInputor = @$inputor[0]

    # NOTE: Duck type
    setPos: (pos) -> @domInputor
    getIEPosition: -> $.noop()
    getPosition: -> $.noop()

    getOldIEPos: ->
      textRange = oDocument.selection.createRange()
      preCaretTextRange = oDocument.body.createTextRange()
      preCaretTextRange.moveToElementText(@domInputor)
      preCaretTextRange.setEndPoint("EndToEnd", textRange)
      preCaretTextRange.text.length

    getPos: ->
      if range = this.range() # Major Browser and IE > 10
        clonedRange = range.cloneRange()
        clonedRange.selectNodeContents(@domInputor)
        clonedRange.setEnd(range.endContainer, range.endOffset)
        pos = clonedRange.toString().length
        clonedRange.detach()
        pos
      else if oDocument.selection #IE < 9
        this.getOldIEPos()

    getOldIEOffset: ->
      range = oDocument.selection.createRange().duplicate()
      range.moveStart "character", -1
      rect = range.getBoundingClientRect()
      { height: rect.bottom - rect.top, left: rect.left, top: rect.top }

    getOffset: (pos) ->
      if oWindow.getSelection and range = this.range()
        return null if range.endOffset - 1 < 0
        clonedRange = range.cloneRange()
        # NOTE: have to select a char to get the rect.
        clonedRange.setStart(range.endContainer, range.endOffset - 1)
        clonedRange.setEnd(range.endContainer, range.endOffset)
        rect = clonedRange.getBoundingClientRect()
        offset = { height: rect.height, left: rect.left + rect.width, top: rect.top }
        clonedRange.detach()
      else if oDocument.selection # ie < 9
        offset = this.getOldIEOffset()

      if offset and !oFrame
        offset.top += $(oWindow).scrollTop()
        offset.left += $(oWindow).scrollLeft()

      offset

    range: ->
      return unless oWindow.getSelection
      sel = oWindow.getSelection()
      if sel.rangeCount > 0 then sel.getRangeAt(0) else null


  class InputCaret

    constructor: (@$inputor) ->
      @domInputor = @$inputor[0]

    getIEPos: ->
      # https://github.com/ichord/Caret.js/wiki/Get-pos-of-caret-in-IE
      inputor = @domInputor
      range = oDocument.selection.createRange()
      pos = 0
      # selection should in the inputor.
      if range and range.parentElement() is inputor
        normalizedValue = inputor.value.replace /\r\n/g, "\n"
        len = normalizedValue.length
        textInputRange = inputor.createTextRange()
        textInputRange.moveToBookmark range.getBookmark()
        endRange = inputor.createTextRange()
        endRange.collapse false
        if textInputRange.compareEndPoints("StartToEnd", endRange) > -1
          pos = len
        else
          pos = -textInputRange.moveStart "character", -len
      pos

    getPos: ->
      if oDocument.selection then this.getIEPos() else @domInputor.selectionStart

    setPos: (pos) ->
      inputor = @domInputor
      if oDocument.selection #IE
        range = inputor.createTextRange()
        range.move "character", pos
        range.select()
      else if inputor.setSelectionRange
        inputor.setSelectionRange pos, pos
      inputor

    getIEOffset: (pos) ->
      textRange = @domInputor.createTextRange()
      pos ||= this.getPos()
      textRange.move('character', pos)

      x = textRange.boundingLeft
      y = textRange.boundingTop
      h = textRange.boundingHeight

      {left: x, top: y, height: h}

    getOffset: (pos) ->
      $inputor = @$inputor
      if oDocument.selection
        offset = this.getIEOffset(pos)
        offset.top += $(oWindow).scrollTop() + $inputor.scrollTop()
        offset.left += $(oWindow).scrollLeft() + $inputor.scrollLeft()
        offset
      else
        offset = $inputor.offset()
        position = this.getPosition(pos)
        offset =
          left: offset.left + position.left - $inputor.scrollLeft()
          top: offset.top + position.top - $inputor.scrollTop()
          height: position.height

    getPosition: (pos)->
      $inputor = @$inputor
      format = (value) ->
        value.replace(/</g, '&lt')
        .replace(/>/g, '&gt')
        .replace(/`/g,'&#96')
        .replace(/"/g,'&quot')
        .replace(/\r\n|\r|\n/g,"<br />")

      pos = this.getPos() if pos is undefined
      start_range = $inputor.val().slice(0, pos)
      html = "<span>"+format(start_range)+"</span>"
      html += "<span id='caret'>|</span>"

      mirror = new Mirror($inputor)
      at_rect = mirror.create(html).rect()

    getIEPosition: (pos) ->
      offset = this.getIEOffset pos
      inputorOffset = @$inputor.offset()
      x = offset.left - inputorOffset.left
      y = offset.top - inputorOffset.top
      h = offset.height

      {left: x, top: y, height: h}

  # @example
  #   mirror = new Mirror($("textarea#inputor"))
  #   html = "<p>We will get the rect of <span>@</span>icho</p>"
  #   mirror.create(html).rect()
  class Mirror
    css_attr: [
      "overflowY", "height", "width", "paddingTop", "paddingLeft",
      "paddingRight", "paddingBottom", "marginTop", "marginLeft",
      "marginRight", "marginBottom","fontFamily", "borderStyle",
      "borderWidth","wordWrap", "fontSize", "lineHeight", "overflowX",
      "text-align",
    ]

    constructor: (@$inputor) ->

    mirrorCss: ->
      css =
        position: 'absolute'
        left: -9999
        top:0
        zIndex: -20000
        'white-space': 'pre-wrap'
      $.each @css_attr, (i,p) =>
        css[p] = @$inputor.css p
      css

    create: (html) ->
      @$mirror = $('<div></div>')
      @$mirror.css this.mirrorCss()
      @$mirror.html(html)
      @$inputor.after(@$mirror)
      this

    # 获得标记的位置
    #
    # @return [Object] 标记的坐标
    #   {left: 0, top: 0, bottom: 0}
    rect: ->
      $flag = @$mirror.find "#caret"
      pos = $flag.position()
      rect = {left: pos.left, top: pos.top, height: $flag.height() }
      @$mirror.remove()
      rect

  Utils =
    contentEditable: ($inputor)->
      !!($inputor[0].contentEditable && $inputor[0].contentEditable == 'true')

  methods =
    pos: (pos) ->
      if pos or pos == 0
        this.setPos pos 
      else 
        this.getPos()

    position: (pos) ->
      if oDocument.selection then this.getIEPosition pos else this.getPosition pos

    offset: (pos) ->
      offset = this.getOffset(pos)
      if oFrame
        iOffset = $(oFrame).offset()
        offset.top += iOffset.top
        offset.left += iOffset.left
      offset

  oDocument = null
  oWindow = null
  oFrame = null
  setContextBy = (iframe) ->
    oFrame = iframe
    oWindow = iframe.contentWindow
    oDocument = iframe.contentDocument || oWindow.document
  configure = ($dom, settings) ->
    if $.isPlainObject(settings) and iframe = settings.iframe
      $dom.data('caret-iframe', iframe) 
      setContextBy iframe
    else if iframe = $dom.data('caret-iframe') 
      setContextBy iframe
    else
      oDocument = $dom[0].ownerDocument
      oWindow = oDocument.defaultView || oDocument.parentWindow
      try
        oFrame = oWindow.frameElement
      catch error
        # throws error in cross-domain iframes
  $.fn.caret = (method) ->
    # http://stackoverflow.com/questions/16010204/get-reference-of-window-object-from-a-dom-element
    if typeof method is 'object'
      configure this, method
      this
    else if methods[method]
      configure this
      caret = if Utils.contentEditable(this) then new EditableCaret(this) else new InputCaret(this)
      methods[method].apply caret, Array::slice.call(arguments, 1)
    else
      $.error "Method #{method} does not exist on jQuery.caret"



  $.fn.caret.EditableCaret = EditableCaret
  $.fn.caret.InputCaret = InputCaret
  $.fn.caret.Utils = Utils
  $.fn.caret.apis = methods
