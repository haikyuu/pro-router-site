module.exports = window.R =

  # local cache
  _location: location
  _replaceState: history.replaceState.bind(history)
  _pushState: history.pushState.bind(history)
  _decodeURIComponent: decodeURIComponent
  _encodeURIComponent: encodeURIComponent

  init: (opts = {}) ->
    @root   ||= opts.root    || 'root'
    @views  ||= opts.views   || window.Views || [@root]
    @render ||= opts.render  || window.render
    @h      ||= opts.helpers || window._
    window.onpopstate = @url_changed.bind(@)
    @read()

  cache: {}
  getters: {}
  setters: {}

  # <MAIN API>

  param: (key) ->
    if @getters[key]
    then @cache[key] ||= @getters[key]( @_decodeURIComponent(@params[key] || '') )
    else @_decodeURIComponent(@params[key] || '')

  write: ->
    # accept arguments keeping key, value, key, value order
    # or a hash as a first argument
    # serialize using setters
    # if no argument given just refresh url and rerender

    if arguments.length
      if arguments.length == 1
        @_write(k,v) for k,v of arguments[0]
      else
        for k, i in arguments
          unless i % 2
            v = arguments[i+1]
            @_write(k,v)

    @_replaceState {},
      @_location.pathname, @to_path(@view, @params)
    @url_changed()

  _write: (k,v) ->
    @params[k] = @_encodeURIComponent( if @setters[k] then @setters[k](v) else v )

  toggle: (flag, state) ->
    @write flag, if state?
    then ( 1 if state )
    else ( 1 if !@params[flag] )

  go: (path) ->
    @_pushState {}, null, path
    @url_changed()

  # </MAIN API>

  read: ->
    [@view, @params] = @split_path @_location.pathname
    @_safe_params()

  split_path: (path) ->
    list = @h.compact path.split("/")
    view = @_existance if list.length % 2 then list.shift() else @root
    params = @h.fromPairs @h.chunk(list, 2)
    [ view, params ]

  _existance: (view) ->
    if @h.includes(@views, view) then view else 'not_found'

  _safe_params: ->
    @safe_params = @h.fromPairs @h.reject @h.toPairs(@params), (pair) ->
      /^_/.test pair[0]

  to_path: (view = @view, params = @safe_params) ->
    array = @h.flatten @h.reject( @h.toPairs(params), (p) -> !p[1] )
    array.unshift(view) if view and view != @root
    '/' + array.join('/')

  url_changed: ->
    @cache = {}
    @read()
    @render()
