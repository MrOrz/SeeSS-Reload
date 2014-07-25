require! {
  fs
}
require! './mhtparser'.MHTParser

err, data <- fs.readFile 'data/Macs.mhtml', encoding: \utf8 , _

if err
  console.error err
  return

parser = new MHTParser(data)
parts = parser.parse!

for part in parts
  filename = encodeURIComponent part.header['content-location'].0
  opt =
    encoding: if part.header['content-transfer-encoding'].0 is 'base64' then 'base64' else null

  fs.writeFile "output/#{filename}", part.content, opt, ->
    console.error it if it