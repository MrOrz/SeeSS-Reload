require!{
  fs
  expect: 'expect.js'
  sh: execSync
}

require! '../src/directoryprocessor'.DirectoryProcessor

(...) <- describe \DirectoryProcessor, _

const TEST_DIR = 'test/directory-tmp'
processor = null

before-each ->
  # Create processor
  processor := new DirectoryProcessor('test/fixtures/testdir')

after-each ->
  sh.run "rm -rf #{TEST_DIR}"

it 'should read all mht files and sort with filename', ->
  expected = [
    '2014-07-02 23_08_32[v]_1391x170_http_--localhost_3000-#-.mht.mhtml'
    '2014-07-02 23_10_23[v]_1391x170_http_--localhost_3000-#-.mht.mhtml'
  ]

  expect processor.mhts .to.eql expected

it 'should create git directory as expected', ->
  <- processor.output TEST_DIR .then _
  expect sh.run("ls #{TEST_DIR}/.git") .to.be 0

  log-output = sh.exec "cd #{TEST_DIR} ; git log --oneline"

  expected-log-output =
    code: 0
    stdout: "1e803ba 2014-07-02 23_10_23[v]_1391x170_http_--localhost_3000-#-.mht.mhtml\n29a58a7 2014-07-02 23_08_32[v]_1391x170_http_--localhost_3000-#-.mht.mhtml\n"
  expect log-output .to.eql expected-log-output

