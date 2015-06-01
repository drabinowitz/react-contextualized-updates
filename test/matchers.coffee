_         = require 'lodash'
Immutable = require 'immutable'
TestUtils = require('react/addons').addons.TestUtils
moment    = require 'moment'


properties = [
  'innerHTML'
  'placeholder'
  'tagName'
  'textContent'
  'value'
]

module.exports = (chai, utils) ->
  inspect = utils.inspect
  flag    = utils.flag

  _matchProperty = (name) ->
    chai.Assertion.addMethod name, (expected) ->
      value = flag(this, 'object')[name]
      @assert value is expected,
        "expected \#{this} to have #{name} \#{exp}, but got \#{act}",
        "expected \#{this} not have have #{name} \#{exp}",
        expected, value
  _matchProperty(prop) for prop in properties

  chai.Assertion.addMethod 'haveAttribute', (expected) ->
    hasAttr = flag(this, 'object').hasAttribute(expected)
    @assert hasAttr,
      "expected \#{this} to have attribute #{expected}, but got \#{act}",
      "expected \#{this} not have have attribute #{expected}, found \#{act}",
      expected

  chai.Assertion.addMethod 'haveClass', (expected) ->
    classes = flag(this, 'object').className.split /\s+/
    @assert expected in classes,
      "expected \#{this} to have class #{expected}, but got \#{act}",
      "expected \#{this} not have have class #{expected}, found \#{act}",
      expected, classes

  chai.Assertion.addMethod 'haveCount', (expected) ->
    count = flag(this, 'object').count()
    @assert expected is count,
      "expected \#{this} to have count #{expected}, but got \#{act}",
      "expected \#{this} not have have count #{expected}, found \#{act}",
      expected, count

  chai.Assertion.addMethod 'haveElement', (expected) ->
    component = flag(this, 'object')
    rootNode  = component.getDOMNode()
    @assert rootNode.querySelectorAll(expected).length > 0,
      "expected \#{this} to contain element found by #{expected}",
      "expected \#{this} not to contain #{expected}",
      expected

  chai.Assertion.addMethod 'beElementOfType', (expected) ->
    element = flag(this, 'object')
    expectedName = expected.displayName ? 'EXPECTED TYPE HAS NO DISPLAY NAME'
    @assert TestUtils.isElementOfType(element, expected),
      "expected this to be a React element of type #{expectedName}",
      "expected this to not be a React element of type #{expectedName}",
      expected

  chai.Assertion.addMethod 'beValue', (expected) ->
    value = flag(this, 'object')
    @assert Immutable.is(expected, value),
      "expected \#{this} to be value #{expected}, but got #{value}",
      "expected \#{this} to not be value #{expected}, found #{value}",
      expected, value

  chai.Assertion.addMethod 'utcISOString', (expected) ->
    actual   = flag(this, 'object')
    expected = moment(expected).toISOString()
    @assert actual == expected,
      "expected #{actual} to be utc isoString of #{expected}",
      "expected #{actual} to not be utc isoString of #{expected}"

  chai.Assertion.addProperty 'eventObject', ->
    expectedEventKeys = [
      '_dispatchIDs'
      '_dispatchListeners'
      'bubbles'
      'cancelable'
      'currentTarget'
      'defaultPrevented'
      'dispatchConfig'
      'dispatchMarker'
      'eventPhase'
      'isDefaultPrevented'
      'isPropagationStopped'
      'isTrusted'
      'nativeEvent'
      'target'
      'timeStamp'
      'type'
    ]
    actualEventKeys = Object.keys(flag(this, 'object'))
    diff = _.difference(expectedEventKeys, actualEventKeys)
    @assert diff.length is 0,
      "expected \#{this} to be an Event object, but was missing keys:  #{diff}",
      "expected \#{this} not to be an Event object",
      diff
