# frozen_string_literal: true

require 'optparse'

module Pups
  class Cli
    def self.opts
      OptionParser.new do |opts|
        opts.banner = 'Usage: pups [FILE|--stdin]'
        opts.on('--stdin', 'Read input from stdin.')
        opts.on('--quiet', "Don't print any logs.")
        opts.on('-h', '--help') do
          puts opts
          exit
        end
      end
    end

    def self.parse_args(args)
      options = {}
      opts.parse!(args, into: options)
      options
    end

    def self.run(args)
      options = parse_args(args)
      input_file = options[:stdin] ? 'stdin' : args.last
      unless input_file
        puts opts.parse!(%w[--help])
        exit
      end

      if options[:quiet]
        Pups.silence
      end

      Pups.log.info("Reading from #{input_file}")

      if options[:stdin]
        conf = $stdin.readlines.join
        split = conf.split('_FILE_SEPERATOR_')

        conf = nil
        split.each do |data|
          current = YAML.safe_load(data.strip)
          conf = if conf
            Pups::MergeCommand.deep_merge(conf, current, :merge_arrays)
          else
            current
          end
        end

        config = Pups::Config.new(conf)
      else
        config = Pups::Config.load_file(input_file)
      end

      config.run
    ensure
      Pups::ExecCommand.terminate_async
    end
  end
end
