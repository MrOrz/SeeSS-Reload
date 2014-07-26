require!{
  fs
  expect: 'expect.js'
}

require! '../src/mhtprocessor'.MHTProcessor

(...) <- describe \MHTProcessor _

!function expect-from-file (name)
  expected = require "./fixtures/#{name}.json"

  processor = new MHTProcessor "test/fixtures/#{name}.mhtml"

  return processor.process!then (files) ->
    # Pick interested columns only
    output = [file{content, name} for file in files]

    expect output .to.eql expected

    return true

it 'should process simple MHT files', ->
  expect-from-file \simple-process
