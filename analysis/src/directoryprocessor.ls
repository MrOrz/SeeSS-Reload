require! {
  sh: execSync
  fs
  path
  Promise: bluebird
}
require! './mhtprocessor'.MHTProcessor

class DirectoryProcessor
  (@input-dir) ->
    @mhts = fs.readdir-sync(@input-dir)
              .filter (name) -> path.extname(name) is '.mhtml' || path.extname(name) is '.mht'
              .sort!

  output: (output-dir) ->
    return Promise.reject('no MHT files') unless @mhts.length

    file-promise = null

    sh.run "rm -rf #{output-dir}; mkdir -p #{output-dir}"
    sh.run "cd #{output-dir}; git init"

    @mhts.forEach (mht-name) ~>

      # A funciton that reads mht and return the promise of MHT processor
      process = ~>
        processor = new MHTProcessor "#{@input-dir}/#{mht-name}"
        return processor.process!then ->
          return processor.output output-dir
        .then ->
          # console.log "New revision: #{mht-name}"
          sh.run "cd #{output-dir}; git add . ; git commit -m '#{mht-name}'"

      if file-promise
        # Chain the process function in the last promise
        file-promise := file-promise.then process
      else
        # Execute the process function and store the promise for chaning
        file-promise := process!

    # Return a promise that resolves itself when all done
    return file-promise

exports <<< {DirectoryProcessor}
