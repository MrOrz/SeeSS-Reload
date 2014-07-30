require!{
  fs
  expect: 'expect.js'
  sh: execSync
}

require! '../src/mhtprocessor'.MHTProcessor
const TEST_DIR = 'test/mht-tmp'

(...) <- describe \MHTProcessor _

!function expect-from-file (name)
  expected = require "./fixtures/#{name}.json"

  processor = new MHTProcessor "test/fixtures/#{name}.mhtml"

  return processor.process!then (files) ->
    # Pick interested columns only
    output = [file{content, name} for file in files]

    expect output .to.eql expected

    return true

describe '#process', (...) ->
  it 'should process simple MHT files', ->
    expect-from-file \simple-process

describe '#output', (...) ->
  it 'should return promise that resolves when all files are outputted', ->

    # Cleanup & remake tmp
    sh.run "rm -rf #{TEST_DIR}"
    sh.run "mkdir #{TEST_DIR}"

    processor = new MHTProcessor 'test/fixtures/simple-process.mhtml'
    return processor.process!then -> processor.output TEST_DIR
      .then !->
        # file "0" and "1.png" should exist.
        expect sh.run("ls #{TEST_DIR}/42099b") .to.be 0
        expect sh.run("ls #{TEST_DIR}/5563dd.png") .to.be 0

        # Cleanup
        sh.run "rm -rf #{TEST_DIR}"
