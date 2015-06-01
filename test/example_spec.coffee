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
      addChangeListener: (cb) -> @_cb = cb
      removeChangeListener: (cb) -> @_cb = null
      changed: ->
        @messages["0"] = "New hi there #{Math.random()}"
        @_cb?()

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
          </div>
        </div>

    @view = @render <@UserParent />

  it 'should display the user name of the child', ->
    expect(@view.getDOMNode().textContent).to.contain 'User Child: Dmitri'

  it 'should update on button click', ->
    @simulate.click @oneByClass @view, 'user'
    expect(@view.getDOMNode().textContent).to.contain 'User Child: New Dmitri'

  it 'should display the user name of the other child', ->
    expect(@view.getDOMNode().textContent).to.contain 'User Other Child: Dmitri'

  it 'should update on button click', ->
    @simulate.click @oneByClass @view, 'user'
    expect(@view.getDOMNode().textContent).to.contain 'User Other Child: New Dmitri'

  it 'should display the user name of the parent', ->
    expect(@view.getDOMNode().textContent).to.contain 'User Parent: Dmitri'

  it 'should update on button click', ->
    @simulate.click @oneByClass @view, 'user'
    expect(@view.getDOMNode().textContent).to.contain 'User Parent: New Dmitri'

  it 'should upldate the message name', ->
    expect(@view.getDOMNode().textContent).to.contain 'Message: hi there'

  it 'should update on button click', ->
    @simulate.click @oneByClass @view, 'message'
    expect(@view.getDOMNode().textContent).to.contain 'Message: New hi there'
