# Class to process data
class Model

  constructor: (@context) ->
    @at = @context.at
    # NOTE: bind data storage to inputor maybe App class can handle it.
    @storage = @context.$inputor

  destroy: ->
    @storage.data(@at, null)

  saved: ->
    this.fetch() > 0

  # fetch data from storage by query.
  # will invoke `callback` to return data
  #
  # @param query [String] catched string for searching
  # @param callback [Function] for receiving data
  query: (query, callback) ->
    data = this.fetch()
    search_key = @context.get_opt("search_key")
    data = @context.callbacks('filter').call(@context, query, data, search_key) || []
    _remote_filter = @context.callbacks('remote_filter')
    if data.length > 0 or (!_remote_filter and data.length == 0)
      callback data
    else
      _remote_filter.call(@context, query, callback)

  # get or set current data which would be shown on the list view.
  #
  # @param data [Array] set data
  # @return [Array|undefined] current data that are showing on the list view.
  fetch: ->
    @storage.data(@at) || []

  # save special flag's data to storage
  #
  # @param data [Array] data to save
  save: (data) ->
    @storage.data @at, @context.callbacks("before_save").call(@context, data || [])

  # load data. It wouldn't load for a second time if it has been loaded.
  #
  # @param data [Array] data to load
  load: (data) ->
    this._load(data) unless this.saved() or not data

  reload: (data) ->
    this._load(data)

  # load data from local or remote with callback
  #
  # @param data [Array|String] data to load.
  _load: (data) ->
    if typeof data is "string"
      $.ajax(data, dataType: "json").done (data) => this.save(data)
    else
      this.save data
