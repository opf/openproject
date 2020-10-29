unless RUBY_PLATFORM =~ /(mswin|mingw|cygwin|bccwin)/
  require 'posix_spawn_ext'
end

require 'posix/spawn/version'
require 'posix/spawn/child'

class IO
  if defined? JRUBY_VERSION
    require 'jruby'
    def posix_fileno
      case self
      when STDIN, $stdin
        0
      when STDOUT, $stdout
        1
      when STDERR, $stderr
        2
      else
        JRuby.reference(self).getOpenFile.getMainStream.getDescriptor.getChannel.getFDVal
      end
    end
  else
    alias :posix_fileno :fileno
  end
end

module POSIX
  # The POSIX::Spawn module implements a compatible subset of Ruby 1.9's
  # Process::spawn and related methods using the IEEE Std 1003.1 posix_spawn(2)
  # system interfaces where available, or a pure Ruby fork/exec based
  # implementation when not.
  #
  # In Ruby 1.9, a versatile new process spawning interface was added
  # (Process::spawn) as the foundation for enhanced versions of existing
  # process-related methods like Kernel#system, Kernel#`, and IO#popen. These
  # methods are backward compatible with their Ruby 1.8 counterparts but
  # support a large number of new options. The POSIX::Spawn module implements
  # many of these methods with support for most of Ruby 1.9's features.
  #
  # The argument signatures for all of these methods follow a new convention,
  # making it possible to take advantage of Process::spawn features:
  #
  #   spawn([env], command, [argv1, ...], [options])
  #   system([env], command, [argv1, ...], [options])
  #   popen([[env], command, [argv1, ...]], mode="r", [options])
  #
  # The env, command, and options arguments are described below.
  #
  # == Environment
  #
  # If a hash is given in the first argument (env), the child process's
  # environment becomes a merge of the parent's and any modifications
  # specified in the hash. When a value in env is nil, the variable is
  # unset in the child:
  #
  #     # set FOO as BAR and unset BAZ.
  #     spawn({"FOO" => "BAR", "BAZ" => nil}, 'echo', 'hello world')
  #
  # == Command
  #
  # The command and optional argvN string arguments specify the command to
  # execute and any program arguments. When only command is given and
  # includes a space character, the command text is executed by the system
  # shell interpreter, as if by:
  #
  #     /bin/sh -c 'command'
  #
  # When command does not include a space character, or one or more argvN
  # arguments are given, the command is executed as if by execve(2) with
  # each argument forming the new program's argv.
  #
  # NOTE: Use of the shell variation is generally discouraged unless you
  # indeed want to execute a shell program. Specifying an explicitly argv is
  # typically more secure and less error prone in most cases.
  #
  # == Options
  #
  # When a hash is given in the last argument (options), it specifies a
  # current directory and zero or more fd redirects for the child process.
  #
  # The :chdir option specifies the current directory. Note that :chdir is not
  # thread-safe on systems that provide posix_spawn(2), because it forces a
  # temporary change of the working directory of the calling process.
  #
  #     spawn(command, :chdir => "/var/tmp")
  #
  # The :in, :out, :err, an Integer, an IO object or an Array option specify
  # fd redirection. For example, stderr can be merged into stdout as follows:
  #
  #     spawn(command, :err => :out)
  #     spawn(command, 2 => 1)
  #     spawn(command, STDERR => :out)
  #     spawn(command, STDERR => STDOUT)
  #
  # The key is a fd in the newly spawned child process (stderr in this case).
  # The value is a fd in the parent process (stdout in this case).
  #
  # You can also specify a filename for redirection instead of an fd:
  #
  #     spawn(command, :in => "/dev/null")   # read mode
  #     spawn(command, :out => "/dev/null")  # write mode
  #     spawn(command, :err => "log")        # write mode
  #     spawn(command, 3 => "/dev/null")     # read mode
  #
  # When redirecting to stdout or stderr, the files are opened in write mode;
  # otherwise, read mode is used.
  #
  # It's also possible to control the open flags and file permissions
  # directly by passing an array value:
  #
  #     spawn(command, :in=>["file"])       # read mode assumed
  #     spawn(command, :in=>["file", "r"])  # explicit read mode
  #     spawn(command, :out=>["log", "w"])  # explicit write mode, 0644 assumed
  #     spawn(command, :out=>["log", "w", 0600])
  #     spawn(command, :out=>["log", File::APPEND | File::CREAT, 0600])
  #
  # The array is a [filename, open_mode, perms] tuple. open_mode can be a
  # string or an integer. When open_mode is omitted or nil, File::RDONLY is
  # assumed. The perms element should be an integer. When perms is omitted or
  # nil, 0644 is assumed.
  #
  # The :close It's possible to direct an fd be closed in the child process.  This is
  # important for implementing `popen`-style logic and other forms of IPC between
  # processes using `IO.pipe`:
  #
  #     rd, wr = IO.pipe
  #     pid = spawn('echo', 'hello world', rd => :close, :stdout => wr)
  #     wr.close
  #     output = rd.read
  #     Process.wait(pid)
  #
  # == Spawn Implementation
  #
  # The POSIX::Spawn#spawn method uses the best available implementation given
  # the current platform and Ruby version. In order of preference, they are:
  #
  #  1. The posix_spawn based C extension method (pspawn).
  #  2. Process::spawn when available (Ruby 1.9 only).
  #  3. A simple pure-Ruby fork/exec based spawn implementation compatible
  #     with Ruby >= 1.8.7.
  #
  module Spawn
    extend self

    # Spawn a child process with a variety of options using the best
    # available implementation for the current platform and Ruby version.
    #
    # spawn([env], command, [argv1, ...], [options])
    #
    # env     - Optional hash specifying the new process's environment.
    # command - A string command name, or shell program, used to determine the
    #           program to execute.
    # argvN   - Zero or more string program arguments (argv).
    # options - Optional hash of operations to perform before executing the
    #           new child process.
    #
    # Returns the integer pid of the newly spawned process.
    # Raises any number of Errno:: exceptions on failure.
    def spawn(*args)
      if respond_to?(:_pspawn)
        pspawn(*args)
      elsif ::Process.respond_to?(:spawn)
        ::Process::spawn(*args)
      else
        fspawn(*args)
      end
    end

    # Spawn a child process with a variety of options using the posix_spawn(2)
    # systems interfaces. Supports the standard spawn interface as described in
    # the POSIX::Spawn module documentation.
    #
    # Raises NotImplementedError when the posix_spawn_ext module could not be
    # loaded due to lack of platform support.
    def pspawn(*args)
      env, argv, options = extract_process_spawn_arguments(*args)
      raise NotImplementedError unless respond_to?(:_pspawn)

      if defined? JRUBY_VERSION
        # On the JVM, changes made to the environment are not propagated down
        # to C via get/setenv, so we have to fake it here.
        unless options[:unsetenv_others] == true
          env = ENV.merge(env)
          options[:unsetenv_others] = true
        end
      end

      _pspawn(env, argv, options)
    end

    # Spawn a child process with a variety of options using a pure
    # Ruby fork + exec. Supports the standard spawn interface as described in
    # the POSIX::Spawn module documentation.
    def fspawn(*args)
      env, argv, options = extract_process_spawn_arguments(*args)
      valid_options = [:chdir, :unsetenv_others, :pgroup]

      if badopt = options.find{ |key,val| !fd?(key) && !valid_options.include?(key) }
        raise ArgumentError, "Invalid option: #{badopt[0].inspect}"
      elsif !argv.is_a?(Array) || !argv[0].is_a?(Array) || argv[0].size != 2
        raise ArgumentError, "Invalid command name"
      end

      fork do
        begin
          # handle FD => {FD, :close, [file,mode,perms]} options
          options.each do |key, val|
            if fd?(key)
              key = fd_to_io(key)

              if fd?(val)
                val = fd_to_io(val)
                key.reopen(val)
                if key.respond_to?(:close_on_exec=)
                  key.close_on_exec = false
                  val.close_on_exec = false
                end
              elsif val == :close
                if key.respond_to?(:close_on_exec=)
                  key.close_on_exec = true
                else
                  key.close
                end
              elsif val.is_a?(Array)
                file, mode_string, perms = *val
                key.reopen(File.open(file, mode_string, perms))
              end
            end
          end

          # setup child environment
          ENV.replace({}) if options[:unsetenv_others] == true
          env.each { |k, v| ENV[k] = v }

          # { :chdir => '/' } in options means change into that dir
          ::Dir.chdir(options[:chdir]) if options[:chdir]

          # { :pgroup => pgid } options
          pgroup = options[:pgroup]
          pgroup = 0 if pgroup == true
          Process::setpgid(0, pgroup) if pgroup

          # do the deed
          if RUBY_VERSION =~ /\A1\.8/
            ::Kernel::exec(*argv)
          else
            argv_and_options = argv + [{:close_others=>false}]
            ::Kernel::exec(*argv_and_options)
          end
        ensure
          exit!(127)
        end
      end
    end

    # Executes a command and waits for it to complete. The command's exit
    # status is available as $?. Supports the standard spawn interface as
    # described in the POSIX::Spawn module documentation.
    #
    # This method is compatible with Kernel#system.
    #
    # Returns true if the command returns a zero exit status, or false for
    # non-zero exit.
    def system(*args)
      pid = spawn(*args)
      return false if pid <= 0
      ::Process.waitpid(pid)
      $?.exitstatus == 0
    rescue Errno::ENOENT
      false
    end

    # Executes a command in a subshell using the system's shell interpreter
    # and returns anything written to the new process's stdout. This method
    # is compatible with Kernel#`.
    #
    # Returns the String output of the command.
    def `(cmd)
      r, w = IO.pipe
      command_and_args = system_command_prefixes + [cmd, {:out => w, r => :close}]
      pid = spawn(*command_and_args)

      if pid > 0
        w.close
        out = r.read
        ::Process.waitpid(pid)
        out
      else
        ''
      end
    ensure
      [r, w].each{ |io| io.close rescue nil }
    end

    # Spawn a child process with all standard IO streams piped in and out of
    # the spawning process. Supports the standard spawn interface as described
    # in the POSIX::Spawn module documentation.
    #
    # Returns a [pid, stdin, stdout, stderr] tuple, where pid is the new
    # process's pid, stdin is a writeable IO object, and stdout / stderr are
    # readable IO objects. The caller should take care to close all IO objects
    # when finished and the child process's status must be collected by a call
    # to Process::waitpid or equivalent.
    def popen4(*argv)
      # create some pipes (see pipe(2) manual -- the ruby docs suck)
      ird, iwr = IO.pipe
      ord, owr = IO.pipe
      erd, ewr = IO.pipe

      # spawn the child process with either end of pipes hooked together
      opts =
        ((argv.pop if argv[-1].is_a?(Hash)) || {}).merge(
          # redirect fds        # close other sides
          :in  => ird,          iwr  => :close,
          :out => owr,          ord  => :close,
          :err => ewr,          erd  => :close
        )
      pid = spawn(*(argv + [opts]))

      [pid, iwr, ord, erd]
    ensure
      # we're in the parent, close child-side fds
      [ird, owr, ewr].each { |fd| fd.close if fd }
    end

    ##
    # Process::Spawn::Child Exceptions

    # Exception raised when the total number of bytes output on the command's
    # stderr and stdout streams exceeds the maximum output size (:max option).
    # Currently
    class MaximumOutputExceeded < StandardError
    end

    # Exception raised when timeout is exceeded.
    class TimeoutExceeded < StandardError
    end

    private

    # Turns the various varargs incantations supported by Process::spawn into a
    # simple [env, argv, options] tuple. This just makes life easier for the
    # extension functions.
    #
    # The following method signature is supported:
    #   Process::spawn([env], command, ..., [options])
    #
    # The env and options hashes are optional. The command may be a variable
    # number of strings or an Array full of strings that make up the new process's
    # argv.
    #
    # Returns an [env, argv, options] tuple. All elements are guaranteed to be
    # non-nil. When no env or options are given, empty hashes are returned.
    def extract_process_spawn_arguments(*args)
      # pop the options hash off the end if it's there
      options =
        if args[-1].respond_to?(:to_hash)
          args.pop.to_hash
        else
          {}
        end
      flatten_process_spawn_options!(options)
      normalize_process_spawn_redirect_file_options!(options)

      # shift the environ hash off the front if it's there and account for
      # possible :env key in options hash.
      env =
        if args[0].respond_to?(:to_hash)
          args.shift.to_hash
        else
          {}
        end
      env.merge!(options.delete(:env)) if options.key?(:env)

      # remaining arguments are the argv supporting a number of variations.
      argv = adjust_process_spawn_argv(args)

      [env, argv, options]
    end

    # Convert { [fd1, fd2, ...] => (:close|fd) } options to individual keys,
    # like: { fd1 => :close, fd2 => :close }. This just makes life easier for the
    # spawn implementations.
    #
    # options - The options hash. This is modified in place.
    #
    # Returns the modified options hash.
    def flatten_process_spawn_options!(options)
      options.to_a.each do |key, value|
        if key.respond_to?(:to_ary)
          key.to_ary.each { |fd| options[fd] = value }
          options.delete(key)
        end
      end
    end

    # Mapping of string open modes to integer oflag versions.
    OFLAGS = {
      "r"  => File::RDONLY,
      "r+" => File::RDWR   | File::CREAT,
      "w"  => File::WRONLY | File::CREAT  | File::TRUNC,
      "w+" => File::RDWR   | File::CREAT  | File::TRUNC,
      "a"  => File::WRONLY | File::APPEND | File::CREAT,
      "a+" => File::RDWR   | File::APPEND | File::CREAT
    }

    # Convert variations of redirecting to a file to a standard tuple.
    #
    # :in   => '/some/file'   => ['/some/file', 'r', 0644]
    # :out  => '/some/file'   => ['/some/file', 'w', 0644]
    # :err  => '/some/file'   => ['/some/file', 'w', 0644]
    # STDIN => '/some/file'   => ['/some/file', 'r', 0644]
    #
    # Returns the modified options hash.
    def normalize_process_spawn_redirect_file_options!(options)
      options.to_a.each do |key, value|
        next if !fd?(key)

        # convert string and short array values to
        if value.respond_to?(:to_str)
          value = default_file_reopen_info(key, value)
        elsif value.respond_to?(:to_ary) && value.size < 3
          defaults = default_file_reopen_info(key, value[0])
          value += defaults[value.size..-1]
        else
          value = nil
        end

        # replace string open mode flag maybe and replace original value
        if value
          value[1] = OFLAGS[value[1]] if value[1].respond_to?(:to_str)
          options[key] = value
        end
      end
    end

    # The default [file, flags, mode] tuple for a given fd and filename. The
    # default flags vary based on the what fd is being redirected. stdout and
    # stderr default to write, while stdin and all other fds default to read.
    #
    # fd   - The file descriptor that is being redirected. This may be an IO
    #        object, integer fd number, or :in, :out, :err for one of the standard
    #        streams.
    # file - The string path to the file that fd should be redirected to.
    #
    # Returns a [file, flags, mode] tuple.
    def default_file_reopen_info(fd, file)
      case fd
      when :in, STDIN, $stdin, 0
        [file, "r", 0644]
      when :out, STDOUT, $stdout, 1
        [file, "w", 0644]
      when :err, STDERR, $stderr, 2
        [file, "w", 0644]
      else
        [file, "r", 0644]
      end
    end

    # Determine whether object is fd-like.
    #
    # Returns true if object is an instance of IO, Integer >= 0, or one of the
    # the symbolic names :in, :out, or :err.
    def fd?(object)
      case object
      when Integer
        object >= 0
      when :in, :out, :err, STDIN, STDOUT, STDERR, $stdin, $stdout, $stderr, IO
        true
      else
        object.respond_to?(:to_io) && !object.to_io.nil?
      end
    end

    # Convert a fd identifier to an IO object.
    #
    # Returns nil or an instance of IO.
    def fd_to_io(object)
      case object
      when STDIN, STDOUT, STDERR, $stdin, $stdout, $stderr
        object
      when :in, 0
        STDIN
      when :out, 1
        STDOUT
      when :err, 2
        STDERR
      when Integer
        object >= 0 ? IO.for_fd(object) : nil
      when IO
        object
      else
        object.respond_to?(:to_io) ? object.to_io : nil
      end
    end

    # Derives the shell command to use when running the spawn.
    #
    # On a Windows machine, this will yield:
    #   [['cmd.exe', 'cmd.exe'], '/c']
    # Note: 'cmd.exe' is used if the COMSPEC environment variable
    #   is not specified. If you would like to use something other
    #   than 'cmd.exe', specify its path in ENV['COMSPEC']
    #
    # On all other systems, this will yield:
    #   [['/bin/sh', '/bin/sh'], '-c']
    #
    # Returns a platform-specific [[<shell>, <shell>], <command-switch>] array.
    def system_command_prefixes
      if RUBY_PLATFORM =~ /(mswin|mingw|cygwin|bccwin)/
        sh = ENV['COMSPEC'] || 'cmd.exe'
        [[sh, sh], '/c']
      else
        [['/bin/sh', '/bin/sh'], '-c']
      end
    end

    # Converts the various supported command argument variations into a
    # standard argv suitable for use with exec. This includes detecting commands
    # to be run through the shell (single argument strings with spaces).
    #
    # The args array may follow any of these variations:
    #
    # 'true'                     => [['true', 'true']]
    # 'echo', 'hello', 'world'   => [['echo', 'echo'], 'hello', 'world']
    # 'echo hello world'         => [['/bin/sh', '/bin/sh'], '-c', 'echo hello world']
    # ['echo', 'fuuu'], 'hello'  => [['echo', 'fuuu'], 'hello']
    #
    # Returns a [[cmdname, argv0], argv1, ...] array.
    def adjust_process_spawn_argv(args)
      if args.size == 1 && args[0].is_a?(String) && args[0] =~ /[ |>]/
        # single string with these characters means run it through the shell
        command_and_args = system_command_prefixes + [args[0]]
        [*command_and_args]
      elsif !args[0].respond_to?(:to_ary)
        # [argv0, argv1, ...]
        [[args[0], args[0]], *args[1..-1]]
      else
        # [[cmdname, argv0], argv1, ...]
        args
      end
    end
  end
end
