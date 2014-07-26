require!{
  fs
  expect: 'expect.js'
}

require! '../src/mhtparser'.MHTParser

(...) <- describe \MHTParser, _

!function expect-from-file (name)
  expected = require "./fixtures/#{name}.json"

  (err, data) <-! fs.read-file "test/fixtures/#{name}.mhtml", encoding: \utf8, _

  console.error err if err
  # console.log data

  parser = new MHTParser(data)

  # Pick interested columns only
  output = [item{content, type, location, encoding} for item in parser.parse!]

  expect output .to.eql expected

it 'should parse simple MHT files', !->
  expect-from-file \simple