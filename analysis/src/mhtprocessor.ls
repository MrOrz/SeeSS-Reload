#
# Given a MHT file name and an output directory, output the files.
#

require! {
  fs
  url
  path
  htmlencode.htmlEncode
  Promise: bluebird
}
require! './mhtparser'.MHTParser

Promise.promisifyAll fs

class MHTProcessor
  (@input-file) ->

  process: ->
    data <~ fs.read-file-async @input-file, encoding: \utf8 .then _

    parser = new MHTParser(data)
    parts = parser.parse!

    # Filename re-encoding
    #
    # name-map maps old file names to new one.
    # name-matchers contains an array of the following:
    # {matcher: /kerker.jpg/gm, name: '0.jpg'} means all links to 'kerker.jpg' should become '0.jpg'
    #
    name-map = {}
    name-matchers = for part, idx in parts
      old-name = part.location
      pathname = url.parse(old-name).pathname
      ext = path.extname pathname
      new-name = "#{idx}#{ext}"

      name-map[old-name] = new-name

      # Pushed instance to name-matchers
      # http://stackoverflow.com/questions/4371565/can-you-create-javascript-regexes-on-the-fly-using-string-variables
      #
      matcher: old-name
      name: new-name

    # Longer matcher needs to be first processed.
    #
    name-matchers.sort (a, b) -> b.matcher.length - a.matcher.length
    # console.log name-matchers

    # Output each file after the URL replacement
    #
    @files = for part in parts
      content = part.content
      new-name = name-map[part.location]

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

      part.content = content

      # Return the processed part along with the new name
      part <<< {name: new-name}

    return @files

  output: (output-dir) ->

    write-file-promises = for file in @files
      # Outputting file
      opt =
        encoding: if file.encoding is 'base64' then 'base64' else null

      console.log \Saving, file.location, \as, file.name
      fs.write-file-async "#{output-dir}/#{file.name}", file.content, opt .then ->
        console.error it if it

    return Promise.all write-file-promises

exports <<< {MHTProcessor}
