require! {
  expect: 'expect.js'
}

(...) <-! describe \test, _

it 'should pass', ->
  expect true .to.be true
