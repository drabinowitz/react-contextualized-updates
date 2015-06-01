{sandbox, spy, stub} = require 'sinon'

_initDocument = ->
  domino = require 'domino'
  Window = require 'domino/lib/Window'
  Node   = require 'domino/lib/Node'
  # Mock Node.focus - not implemented in domino
  Node.prototype.focus = ->
  # Mock Node.select - not implemented in domino
  Node.prototype.select = ->
    @selectionStart = 0
    @selectionEnd = @value.length
  # Mock Node.contains - not implemented in domino
  Node.prototype.contains = (that) ->
    return false unless that
    that.parentNode = null unless that.parentNode?

    result = @compareDocumentPosition that
    result is
      (Node.DOCUMENT_POSITION_FOLLOWING + Node.DOCUMENT_POSITION_CONTAINED_BY)
  Node.prototype.getBoundingClientRect = ->
    # return a ClientRect-like object
    top:     10
    height:  57
    width:   1221
    left:    222
    bottom:  294
    right:   1443

  global.document or= domino.createDocument()
  window = new Window(global.document)

  global.window     = window
  global.navigator  = window.navigator

  sandbox.create()
  global.Blob                 = stub()
  global.URL                  = stub()
  global.URL.createObjectURL  = stub()

  window


_destroyWindow = ->
  sandbox.restore()
  delete global.navigator
  delete global.window


# Initialize the window/document/navigator and add helpful functions for dealing
# with DOM elements.
beforeEach ->
  window  = _initDocument()

  React     = require('react')
  TestUtils = require('react/addons').addons.TestUtils

  @_nodes = []
  @renderWithContext = (reactWithContext, cls, el) ->
    if not el?
      el = document.createElement('div')
      document.body.appendChild(el)
      @_nodes.push(el)
    reactWithContext.render(cls, el)

  @simulate   = TestUtils.Simulate
  @allByClass = TestUtils.scryRenderedDOMComponentsWithClass
  @allByTag   = TestUtils.scryRenderedDOMComponentsWithTag
  @allByType  = TestUtils.scryRenderedComponentsWithType
  @oneByClass = TestUtils.findRenderedDOMComponentWithClass
  @oneByTag   = TestUtils.findRenderedDOMComponentWithTag
  @oneByType  = TestUtils.findRenderedComponentWithType
  @allInTree  = TestUtils.findAllInRenderedTree

  @enterInput = (component, text) ->
    component.getDOMNode().value = text
    @simulate.change(component)

  @simulate.keyPress = (component, key) =>
    @simulate.keyDown(component, key)
    @simulate.keyUp(component, key)

  @openDatePicker = (el) =>
    input = el.querySelector('input.for-date')
    @simulate.focus input

  @chooseDay = (el, dayNumber) =>
    day = el.querySelector(".day:contains(#{dayNumber})")
    @simulate.click day

  @enterTime = (el, timeString) =>
    input = el.querySelector('.time-input input')
    input.value = timeString
    @simulate.change input
    @simulate.blur input


# Nuke the global state of window/document/navigator
afterEach ->
  React = require('react')
  for node in @_nodes
    React.unmountComponentAtNode(node)
    node.remove()

  _destroyWindow()


# if a 'window' is not in place when React first loads, it will silently get
# into a very bizarre state and throw an 'Invariant Violation' the first time
# you try to render something. This behavior seems specific to 0.10.0, so try
# removing this if you notice the currect React version is higher.
_initDocument()
