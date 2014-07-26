require! {
  fs
  url
  path
  htmlencode.htmlEncode
}
require! './mhtparser'.MHTParser

err, data <- fs.readFile 'data/Macs.mhtml', encoding: \utf8 , _

if err
  console.error err
  return

parser = new MHTParser(data)
parts = parser.parse!

# Filename re-encoding
#
# name-map maps integer to real filenames.
# {matcher: /kerker.jpg/gm, name: '0.jpg'} means all links to 'kerker.jpg' should become '0.jpg'
#
name-matchers = for part, idx in parts
  filename = part.header['content-location'].0
  pathname = url.parse(filename).pathname
  ext = path.extname pathname

  # Pushed instance to name-matchers
  # http://stackoverflow.com/questions/4371565/can-you-create-javascript-regexes-on-the-fly-using-string-variables
  #
  matcher: filename
  name: "#{idx}#{ext}"

console.log name-matchers

# Output each file after the URL replacement
#
for part, idx in parts
  content = part.content
  new-name = name-matchers[idx].name

  # URL replacement
  for {matcher, name} in name-matchers
    #
    # http://stackoverflow.com/questions/4371565/can-you-create-javascript-regexes-on-the-fly-using-string-variables
    # Don't use new RegExp because there may be special characters like '?' in matcher string.
    #
    content = content.split matcher .join name

    # URLs may contain "&amp;" and the MHT file it's saved as "&" only.
    #
    encoded-matcher = htmlEncode matcher
    content = content.split encoded-matcher .join name

  # Outputting file
  opt =
    encoding: if part.header['content-transfer-encoding'].0 is 'base64' then 'base64' else null

  console.log \Saving, part.header['content-location'].0, \as, new-name
  fs.writeFile "output/#{new-name}", content, opt, ->
    console.error it if it

