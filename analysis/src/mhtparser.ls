require! {
  mimelib
  buffer
}

class MHTPart
  (@header, @content) ->
    # Add type and location
    @type = @header['content-type'].0
    @location = @header['content-location'].0
    @encoding = @header['content-transfer-encoding'].0

class MHTParser
  (@input-string) ->

  # split the header and content
  _split: (part) ->
    # Find the first \r\n\r\n. That's the header of the part.
    linebreak-position = part.index-of "\r\n\r\n"

    header: mimelib.parseHeaders part.slice(0, linebreak-position)
    raw-content: part.slice(linebreak-position + 4)

  parse: ->

    # Fetch boundary from the header of MHT file.
    {header: mht-header, raw-content: mht-raw-content} = @_split @input-string

    boundary-token = mht-header['content-type'].0.match(/boundary="(.+)"/).1
    boundary = "--#{boundary-token}\r\n"
    ending-boundary = "--#{boundary-token}--\r\n"
    mht-raw-content = mht-raw-content.slice 0, mht-raw-content.last-index-of(ending-boundary)

    # Ignore the first part. It's the header of the entire MHT file.
    parts = mht-raw-content.split boundary .slice 1

    parsed-parts = []
    for raw-part, i in parts
      part = @_split raw-part
      # console.log part.header

      # Skip all chrome-extension assets
      continue if part.header[\content-location].0.match /^chrome-extension/

      # Skip all Javascript files
      continue if part.header[\content-type].0 is 'application/javascript'

      part.content = switch part.header[\content-transfer-encoding].0
      | 'quoted-printable' => mimelib.decodeQuotedPrintable part.raw-content
      | 'base64' => part.raw-content # Just leave it to output.

      # Return part for this iteration
      parsed-parts ++= new MHTPart(part.header, part.content)

    return parsed-parts

exports <<< {MHTPart, MHTParser}