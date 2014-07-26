require! './mhtprocessor'.MHTProcessor

processor = new MHTProcessor 'data/vuse.mhtml'

processor.process!then ->
  processor.output 'output'
