require './test_dom'
require './test_injected'

require('chai')
  .use(require('./matchers'))
  .use(require('chai-string'))
  .use(require('sinon-chai'))

{Ajax} = require 'ajax'


class global.FormData
  constructor: ->
    @obj = {}

  append: (key, value) ->
    @obj[key] = value

beforeEach ->
  @req = @injector.getInstance(Ajax)

  @_consoleWarn = console.warn
  console.warn = (msg, args...) ->
    throw new Error(msg, args...)

afterEach ->
  console.warn = @_consoleWarn
