KEY_CODE =
  DOWN: 40
  UP: 38
  ESC: 27
  TAB: 9
  ENTER: 13
  CTRL: 17
  P: 80
  N: 78

# Functions set for handling and rendering the data.
# Others developers can override these methods to tweak At.js such as matcher.
# We can override them in `callbacks` settings.
#
# @mixin
#
# The context of these functions is `$.atwho.Controller` object and they are called in this sequences:
#
# [before_save, matcher, filter, remote_filter, sorter, tpl_evl, highlighter, before_insert]
#
DEFAULT_CALLBACKS =

  # It would be called to restructure the data before At.js invokes `Model#save` to save data
  # In default, At.js will convert it to a Hash Array.
  #
  # @param data [Array] data to refacotor.
  # @return [Array] Data after refactor.
  before_save: (data) ->
    return data if not $.isArray data
    for item in data
      if $.isPlainObject item then item else name:item

  # It would be called to match the `flag`.
  # It will match at start of line or after whitespace
  #
  # @param flag [String] current `flag` ("@", etc)
  # @param subtext [String] Text from start to current caret position.
  #
  # @return [String | null] Matched result.
  matcher: (flag, subtext, should_start_with_space) ->
    # escape RegExp
    flag = flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
    flag = '(?:^|\\s)' + flag if should_start_with_space
    regexp = new RegExp flag+'([A-Za-z0-9_\+\-]*)$|'+flag+'([^\\x00-\\xff]*)$','gi'
    match = regexp.exec subtext
    if match then match[2] || match[1] else null

  # ---------------------

  # Filter data by matched string.
  #
  # @param query [String] Matched string.
  # @param data [Array] data list
  # @param search_key [String] at char for searching.
  #
  # @return [Array] result data.
  filter: (query, data, search_key) ->
    # !!null #=> false; !!undefined #=> false; !!'' #=> false;
    _results = []
    for item in data
      _results.push item if ~item[search_key].toLowerCase().indexOf query.toLowerCase()
    _results

  # If a function is given, At.js will invoke it if local filter can not find any data
  #
  # @param params [String] matched query
  # @param callback [Function] callback to render page.
  remote_filter: null
  # remote_filter: (query, callback) ->
  #   $.ajax url,
  #     data: params
  #     success: (data) ->
  #       callback(data)

  # Sorter data of course.
  #
  # @param query [String] matched string
  # @param items [Array] data that was refactored
  # @param search_key [String] at char to search
  #
  # @return [Array] sorted data
  sorter: (query, items, search_key) ->
    return items unless query

    _results = []
    for item in items
      item.atwho_order = item[search_key].toLowerCase().indexOf query.toLowerCase()
      _results.push item if item.atwho_order > -1

    _results.sort (a,b) -> a.atwho_order - b.atwho_order

  # Eval template for every single item in display list.
  #
  # @param tpl [String] The template string.
  # @param map [Hash] Data map to eval.
  tpl_eval: (tpl, map) ->
    try
      tpl.replace /\$\{([^\}]*)\}/g, (tag, key, pos) -> map[key]
    catch error
      ""

  # Highlight the `matched query` string.
  #
  # @param li [String] HTML String after eval.
  # @param query [String] matched query.
  #
  # @return [String] highlighted string.
  highlighter: (li, query) ->
    return li if not query
    regexp = new RegExp(">\\s*(\\w*)(" + query.replace("+","\\+") + ")(\\w*)\\s*<", 'ig')
    li.replace regexp, (str, $1, $2, $3) -> '> '+$1+'<strong>' + $2 + '</strong>'+$3+' <'

  # What to do before inserting item's value into inputor.
  #
  # @param value [String] content to insert
  # @param $li [jQuery Object] the chosen item
  before_insert: (value, $li) ->
    value

  # You can adjust the menu's offset here.
  #
  # @param offset [Hash] offset will be applied to menu
  # before_reposition: (offset) ->
  #   offset.left += 10
  #   offset.top += 10
  #   offset
