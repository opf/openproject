module Daemons
  class Optparse
    attr_reader :usage

    def initialize(controller)
      @controller = controller
      @options = {}

      @opts = OptionParser.new do |opts|
        opts.banner = ''

        opts.on('-t', '--ontop', 'Stay on top (does not daemonize)') do |t|
          @options[:ontop] = t
        end

        opts.on('-s', '--shush', 'Silent mode (no output to the terminal)') do |t|
          @options[:shush] = t
        end

        opts.on('-f', '--force', 'Force operation') do |t|
          @options[:force] = t
        end

        opts.on('-n', '--no_wait', 'Do not wait for processes to stop') do |t|
          @options[:no_wait] = t
        end

        opts.on('-w', '--force_kill_waittime SECONDS', Integer, 'Maximum time to wait for processes to stop before force-killing') do |t|
          @options[:force_kill_waittime] = t
        end

        opts.on('--pid_delimiter STRING', 'Text used to separate process number in full process name and pid-file name') do |value|
          @options[:pid_delimiter] = value
        end

        opts.separator ''
        opts.separator 'Common options:'

        opts.on('-l', '--log_output', 'Enable input/output stream redirection') do |value|
          @options[:log_output] = value
        end

        opts.on('--logfilename FILE', String, 'Custom log file name for exceptions') do |value|
          @options[:logfilename] = value
        end

        opts.on('--output_logfilename FILE', String, 'Custom file name for input/output stream redirection log') do |value|
          @options[:output_logfilename] = value
        end

        opts.on('--log_dir DIR', String, 'Directory for log files') do |value|
          @options[:log_dir] = value
        end

        opts.on('--syslog', 'Enable output redirction into SYSLOG instead of a file') do |value|
          @options[:log_output_syslog] = value
        end

        # No argument, shows at tail.  This will print an options summary
        opts.on_tail('-h', '--help', 'Show this message') do
          controller.print_usage

          exit
        end

        # Switch to print the version.
        opts.on_tail('--version', 'Show version') do
          puts "daemons version #{Daemons::VERSION}"
          exit
        end
      end

      begin
        @usage = @opts.to_s
      rescue ::Exception # work around a bug in ruby 1.9
        @usage = <<END
            -t, --ontop                      Stay on top (does not daemonize)
            -f, --force                      Force operation
            -n, --no_wait                    Do not wait for processes to stop

        Common options:
            -h, --help                       Show this message
                --version                    Show version
END
      end
    end

    # Return a hash describing the options.
    #
    def parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.

      @opts.parse(args)

      @options
    end
  end

  class Controller
    def print_usage
      puts <<-USAGE.gsub(/^ {6}/, '')
      Usage: #{@app_name} <command> <options> -- <application options>

      * where <command> is one of:
        start         start an instance of the application
        stop          stop all instances of the application
        restart       stop all instances and restart them afterwards
        reload        send a SIGHUP to all instances of the application
        run           run the application in the foreground (same as start -t)
        zap           set the application to a stopped state
        status        show status (PID) of application instances

      * and where <options> may contain several of the following:
      #{@optparse.usage}
      USAGE
    end

    def catch_exceptions(&block)
      begin
        block.call
      rescue CmdException, OptionParser::ParseError => e
        puts "ERROR: #{e}"
        puts
        print_usage
      rescue RuntimeException => e
        puts "ERROR: #{e}"
      end
    end
  end
end
