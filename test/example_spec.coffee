require './test_case'

React    = require 'react'
{expect} = require 'chai'

reactUpdates = require '../app'


describe 'Example', ->

  beforeEach ->
    @userStore =
      users:
        '0': 'Dmitri'
      byId: (id) -> @users[id]
      addChangeListener: (cb) -> @_cb = cb
      removeChangeListener: (cb) -> @_cb = null
      changed: ->
        @users["0"] = "New Dmitri #{Math.random()}"
        @_cb?()

    @messageStore =
      messages:
        '0': 'hi there'
      byId: (id) -> @messages[id]
      _cb: []
      addChangeListener: (cb) -> @_cb.push cb
      removeChangeListener: (cb) -> @_cb = @_cb.filter (v) -> v isnt cb
      changed: ->
        @messages["0"] = "New hi there #{Math.random()}"
        @_cb.forEach (v) -> v?()

    @ShowUser = ShowUser = React.createClass
      displayName: 'ShowUser'
      mixins: [reactUpdates.contextMixin('userStore')]
      getDefaultProps: -> id: '0'
      onClick: =>
        @userStore.changed()
      render: ->
        mydata = @plugged.stores.userStore.byId @props.id
        <div>
          <div>User Child: {mydata}</div>
          <button className='user' onClick=@onClick>Update User</button>
        </div>

    @ShowMessage = ShowMessage = React.createClass
      displayName: 'ShowMessage'
      mixins: [reactUpdates.contextMixin('messageStore')]
      getDefaultProps: -> id: '0'
      onClick: =>
        @messageStore.changed()
      render: ->
        mydata = @plugged.stores.messageStore.byId @props.id
        <div>
          <div>Message: {mydata}</div>
          <button className='message' onClick=@onClick>Update Message</button>
        </div>

    @QueryMessage = QueryMessage = React.createClass
      displayName: 'ShowMessage'
      mixins: [reactUpdates.contextMixin('messageStore', '_getData', '_stateFromData')]
      getDefaultProps: -> id: '0'
      _getData: (props) -> @plugged.stores.messageStore.byId props.id
      _stateFromData: (data) -> message: data
      render: ->
        <div>
          <div>Message Query Result: {@plugged.data}</div>
          <div>Stateful Query Result: {@state.message}</div>
        </div>

    @StateStopMessage = StateStopMessage = React.createClass
      displayName: 'ShowMessage'
      mixins: [reactUpdates.contextMixin('messageStore', '_getData', '_stateFromData')]
      getDefaultProps: -> id: '0'
      _getData: (props) -> @plugged.stores.messageStore.byId props.id
      _stateFromData: (data) ->
        unless @state?.message
          message: data
      render: ->
        <div>
          <div>StateStop Query Result: {@state.message}</div>
        </div>

    @ShowOtherUser = ShowOtherUser = React.createClass
      displayName: 'ShowOtherUser'
      mixins: [reactUpdates.contextMixin('userStore')]
      getDefaultProps: -> id: '0'
      render: ->
        mydata = @plugged.stores.userStore.byId @props.id
        <div>
          <div>User Other Child: {mydata}</div>
        </div>

    @UserParent = UserParent = React.createClass
      displayName: 'UserParent'
      mixins: [
        reactUpdates.appContextMixin
          userStore: @userStore
          messageStore: @messageStore
        reactUpdates.contextMixin('userStore')]
      getDefaultProps: -> id: '0'
      render: ->
        mydata = @plugged.stores.userStore.byId @props.id
        <div>
          <div>User Parent: {mydata}</div>
          <ShowUser />
          <div>
            <ShowOtherUser />
            <ShowMessage />
            <QueryMessage />
            <StateStopMessage />
          </div>
        </div>

    @view = @render <@UserParent />

  it 'should display the user name of the child', ->
    expect(@view.getDOMNode().textContent).to.contain 'User Child: Dmitri'

  it 'should update user on button click', ->
    @simulate.click @oneByClass @view, 'user'
    expect(@view.getDOMNode().textContent).to.contain 'User Child: New Dmitri'

  it 'should display the user name of the other child', ->
    expect(@view.getDOMNode().textContent).to.contain 'User Other Child: Dmitri'

  it 'should update other user on button click', ->
    @simulate.click @oneByClass @view, 'user'
    expect(@view.getDOMNode().textContent).to.contain 'User Other Child: New Dmitri'

  it 'should display the user name of the parent', ->
    expect(@view.getDOMNode().textContent).to.contain 'User Parent: Dmitri'

  it 'should update parent on button click', ->
    @simulate.click @oneByClass @view, 'user'
    expect(@view.getDOMNode().textContent).to.contain 'User Parent: New Dmitri'

  it 'should show the message name', ->
    expect(@view.getDOMNode().textContent).to.contain 'Message: hi there'

  it 'should update message on button click', ->
    @simulate.click @oneByClass @view, 'message'
    expect(@view.getDOMNode().textContent).to.contain 'Message: New hi there'

  it 'should show the message name when queried', ->
    expect(@view.getDOMNode().textContent)
      .to.contain 'Message Query Result: hi there'

  it 'should update message query on button click', ->
    @simulate.click @oneByClass @view, 'message'
    expect(@view.getDOMNode().textContent)
      .to.contain 'Message Query Result: New hi there'

  it 'should show the message name when stateful', ->
    expect(@view.getDOMNode().textContent)
      .to.contain 'Stateful Query Result: hi there'

  it 'should update message state on button click', ->
    @simulate.click @oneByClass @view, 'message'
    expect(@view.getDOMNode().textContent)
      .to.contain 'Stateful Query Result: New hi there'

  it 'should show the message name when statestop', ->
    expect(@view.getDOMNode().textContent)
      .to.contain 'StateStop Query Result: hi there'

  it 'should not update message state on button click', ->
    @simulate.click @oneByClass @view, 'message'
    expect(@view.getDOMNode().textContent)
      .to.contain 'StateStop Query Result: hi there'

  it 'should remove change listeners on unmount', ->
    expect(@userStore._cb).to.exist
    expect(@messageStore._cb).to.have.length.above 0
    React.unmountComponentAtNode @_nodes[0]
    expect(@userStore._cb).not.to.exist
    expect(@messageStore._cb).to.have.length 0
