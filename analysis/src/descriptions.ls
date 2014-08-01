# https://developers.google.com/drive/web/quickstart/quickstart-nodejs
# https://github.com/google/google-api-nodejs-client/blob/master/examples/oauth2.js
# https://github.com/google/google-api-nodejs-client/blob/master/examples/mediaupload.js

require! {
  google: googleapis
  readline
  fs
}

secrets = require '../config/secrets.json'

const CLIENT_ID = secrets.GOOGLE_CLIENT_ID
const CLIENT_SECRET = secrets.GOOGLE_CLIENT_SECRET
const REDIRECT_URIS = "http://localhost"
const SCOPE = "https://www.googleapis.com/auth/drive"

oauth2-client = new google.auth.OAuth2 CLIENT_ID, CLIENT_SECRET, REDIRECT_URIS

rl = readline.create-interface do
  input: process.stdin
  output: process.stdout

exports.fetch-description = (folder-id, dest-json) ->

  # Authentication
  #
  console.log "Visit URL: ", oauth2-client.generate-auth-url do
    scope: SCOPE
    access_type: \offline

  (code) <- rl.question "Enter the code here: " , _
  (err, tokens) <- oauth2-client.get-token code, _
  throw err if err
  # console.log tokens
  oauth2-client.set-credentials tokens


  # Retrieve file list under the specified folder
  #

  # https://github.com/google/google-api-nodejs-client#settings-global-or-service-level-auth
  drive = google.drive version: \v2, auth: oauth2-client
  result = []
  page-index = 0

  # Kick start the list retrieval
  retrieve-page!

  function retrieve-page (page-token)
    (err, resp) <- drive.files.list do
      pageToken: page-token
      q: "'#{folder-id}' in parents"
      fields: 'items(description,id,thumbnailLink,title),nextPageToken'
      , _

    throw err if err

    page-index += 1
    result ++= resp.items

    console.log "Page #{page-index} fetched."

    # Preparing for next page
    new-page-token = resp.next-page-token

    if new-page-token
      retrieve-page new-page-token
    else
      # No more pages. Write the output manifest
      #
      # console.log result
      <- fs.write-file dest-json, JSON.stringify(result), +
      console.log "Output: #{dest-json}"
      process.exit!

# If the script is not required, execute fetchDescription directly.
#
unless module.parent
  # console.log process.argv
  [folder-id, dest-json] = process.argv.slice -2

  exports.fetch-description folder-id, dest-json
