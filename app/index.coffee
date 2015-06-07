React = require 'react'

### Plug Store ###
# plug store into app context
# store must implement addChangeListener interface:
#
# store.addChangeListener(cb)
#
# such that when the store changes it invokes the cb

### Mixin ###
# inject store(s) context into component class

getLocalStoreKey = (key) -> "__localStore__#{key}"

appContextMixin = (stores) ->
  childContextTypes = __appStores__: React.PropTypes.object
  childContext = __appStores__: {}
  for key, store of stores
    unless typeof store.addChangeListener is 'function'
      throw new Error(
        "store plugged at key: #{key} does not possess an 'addChangeListener'
        method")
    unless typeof store.removeChangeListener is 'function'
      throw new Error(
        "store plugged at key: #{key} does not possess a 'removeChangeListener'
        method")

    childContext.__appStores__[key] = store

    localStoreKey = getLocalStoreKey key
    childContextTypes[localStoreKey] = React.PropTypes.bool

  childContextTypes: childContextTypes
  getChildContext: -> childContext
  getInitialState: ->
    @__appOwnerContext__ = childContext
    {}

contextMixin = (storeKeys, queryKey, stateChangeKey) ->
  storeKeys = [storeKeys] unless Array.isArray storeKeys
  contextTypes = __appStores__: React.PropTypes.object
  childContextTypes = {}
  childContext = {}
  for key in storeKeys
    localStoreKey = getLocalStoreKey key
    contextTypes[localStoreKey] = React.PropTypes.bool
    childContextTypes[localStoreKey] = React.PropTypes.bool.isRequired
    childContext[localStoreKey] = true

  query = undefined
  result =
    contextTypes: contextTypes
    childContextTypes: childContextTypes
    getChildContext: -> childContext
    getInitialState: ->
      if @__appOwnerContext__? and @context?.__appStores__?
        throw new Error(
          "component has appContextMixin and is not the top level React
          component")

      if not @__appOwnerContext__? and not @context?.__appStores__?
        throw new Error(
          "component does not have access to app context and and does not have
          the appContextMixin this likely occurred because either the component
          did not receive the appContextMixin or the appContextMixin was passed
          in after the contextMixin. Please verify that this component has
          received all mixins and that the order of mixins is correct")

      if queryKey? and typeof @[queryKey] isnt 'function'
        throw new Error("did not find a method at #{queryKey}")

      if stateChangeKey? and typeof @[stateChangeKey] isnt 'function'
        throw new Error("did not find a method at #{stateChangeKey}")

      contextKey = 'context'
      if @__appOwnerContext__?
        contextKey = '__appOwnerContext__'

      @plugged = stores: {}
      for key in storeKeys
        store = @[contextKey].__appStores__[key]
        unless store
          throw new Error(
            "key: #{key} does not match any of the plugged in store keys")

        @plugged.stores[key] = store
        unless @context?[getLocalStoreKey key]
          store.addChangeListener @__triggerUpdate__
          @plugged.__listenedStores__ or= []
          @plugged.__listenedStores__.push key

      if queryKey?
        query = @[queryKey]
        @plugged.data = query(@props)

      state = undefined
      if stateChangeKey?
        state = @[stateChangeKey](@plugged.data)
      state or= {}
      state.__contextualizedState__ = true
      state

    componentWillUnmount: ->
      if @plugged.__listenedStores__?
        for storeKey in @plugged.__listenedStores__
          store = @plugged.stores[storeKey]
          store.removeChangeListener @__triggerUpdate__

  result.__triggerUpdate__ = (nextProps=@props)->
    state = undefined
    if query?
      @plugged.prevData = undefined
      @plugged.nextData = query(nextProps)
      if stateChangeKey?
        state = @[stateChangeKey](@plugged.nextData)
    state or= {}
    state.__contextualizedState__ = true
    @setState state

  if queryKey?
    result.componentWillReceiveProps = (nextProps) ->
      @__triggerUpdate__(nextProps)

    result.componentWillUpdate = ->
      @plugged.prevData = @plugged.data
      @plugged.data = @plugged.nextData
      @plugged.nextData = undefined

  result

###
React.createClass
  mixins: [ContextUpdate('storeKey', 'otherStoreKey')]
  render: ->
    myData = @pluggedIn[storeKey]byId @props.id
    <div>{myData}</div>
###

# components use local-context to determine if they need to add an event
# listener to the plugged in stores
# injected stores update app context when they change
# mixin-ed stores update local component local-context when they update
# all mixins update after the app-context updates to handle next render
# component checks to see if app-context isnt local-context
#   - true: set local-context to app-context and setState with internal key
#   - false: do nothing


module.exports = {appContextMixin, contextMixin}
