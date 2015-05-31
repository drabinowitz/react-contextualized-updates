### Plug Store ###
# plug store into app context
# store must implement addChangeListener interface:
#
# store.addChangeListener(cb)
#
# such that when the store changes it invokes the cb

###
appContext.plugInOne 'myStore', MyStore
appContext.plugInAll
  myStore: MyStore
###

### CONTEXT ###
# inject app context to React withContext

class App
  constructor: (stores) -> @plugInAll stores

  plugInOne: (storeKey, store) ->
    if @_pluggedStores[storeKey]
      throw new Error("store already plugged at key: #{storeKey}")
    @_pluggedStores[storeKey] = store
    store.onPlug?()
    unless typeof store.addChangeListener is 'function'
      throw new Error(
        "store plugged at key: #{storeKey} does not possess an 'addChangeListener' method")

  plugInAll: (stores) ->
    @plugInOne key, store for key, store of stores

  getContext: ->
    context = __appStores__: {}
    for key, store of @_pluggedStores
      context.__appStores__[key] = store
      context[getLocalStoreKey key] = false
    context

###
React.withContext appContext, ->
  React.render(<AppView />, document.body)
###

### Mixin ###
# inject store(s) context into component class

getLocalStoreKey = (key) -> "__localStore__#{key}"

contextMixin = (storeKeys...) ->
  @pluggedIn = {}

  contextTypes = __appStores__: React.PropTypes.object
  childContextTypes = {}
  childContext = {}
  for key in storeKeys
    localStoreKey = getLocalStoreKey key
    contextTypes[localStoreKey] = React.PropTypes.bool
    childContexTypes[localStoreKey] = React.PropTypes.bool.isRequired
    childContext[localStoreKey] = true

  getInitialState: -> __contextualizedState__: 0
  contextTypes: contextTypes
  childContextTypes: childContextTypes
  getChildContext: -> childContext
  __triggerUpdate__: -> @setState __contextualizedState__: 0
  componentWillMount: ->
    for key in storeKeys
      store = @context.__appStores__[key]
      unless store
        throw new Error(
          "key: #{key} does not match any of the plugged in store keys")
      @pluggedIn[key] = store
      unless @context[getLocalStoreKey key]
        store.addChangeListener @__triggerUpdate__

###
React.createClass
  mixins: [ContextUpdate('storeKey', 'otherStoreKey')]
  render: ->
    myData = @pluggedIn[storeKey]byId @props.id
    <div>{myData}</div>
###

ShowUser = React.createClass
  displayName: 'ShowUser'
  mixins: [contextMixin('userStore')]
  getDefaultProps: -> id: '0'
  render: ->
    mydata = @pluggedIn.userStore.byId @props.id
    <div>
      <div>User: {mydata}</div>
      <button onClick=@onClick>Update User</button>
    </div>

# components use local-context to determine if they need to add an event
# listener to the plugged in stores
# injected stores update app context when they change
# mixin-ed stores update local component local-context when they update
# all mixins update after the app-context updates to handle next render
# component checks to see if app-context isnt local-context
#   - true: set local-context to app-context and setState with internal key
#   - false: do nothing

userStore =
  users:
    '0': 'Dmitri'
  byId: (id) -> @users[id]
  addChangeListener: (cb) -> @_cb = cb
  changed: ->
    @users["0"] = "New Dmitri #{Math.random()}"
    @_cb()

app = new App()
app.plugInOne 'userStore', userStore
React.withContext app.getContext(), ->
  React.render <ShowUser />, document.body
