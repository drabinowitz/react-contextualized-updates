require './test_dom'

require('chai')
  .use(require('chai-string'))
  .use(require('sinon-chai'))


class global.FormData
  constructor: ->
    @obj = {}

  append: (key, value) ->
    @obj[key] = value

beforeEach ->
  @_consoleWarn = console.warn
  console.warn = (msg, args...) ->
    throw new Error(msg, args...)

afterEach ->
  console.warn = @_consoleWarn
