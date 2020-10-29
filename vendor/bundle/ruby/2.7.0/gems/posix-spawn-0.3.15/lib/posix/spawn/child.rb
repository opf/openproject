module POSIX
  module Spawn
    # POSIX::Spawn::Child includes logic for executing child processes and
    # reading/writing from their standard input, output, and error streams. It's
    # designed to take all input in a single string and provides all output
    # (stderr and stdout) as single strings and is therefore not well-suited
    # to streaming large quantities of data in and out of commands.
    #
    # Create and run a process to completion:
    #
    #   >> child = POSIX::Spawn::Child.new('git', '--help')
    #
    # Retrieve stdout or stderr output:
    #
    #   >> child.out
    #   => "usage: git [--version] [--exec-path[=GIT_EXEC_PATH]]\n ..."
    #   >> child.err
    #   => ""
    #
    # Check process exit status information:
    #
    #   >> child.status
    #   => #<Process::Status: pid=80718,exited(0)>
    #
    # To write data on the new process's stdin immediately after spawning:
    #
    #   >> child = POSIX::Spawn::Child.new('bc', :input => '40 + 2')
    #   >> child.out
    #   "42\n"
    #
    # To access output from the process even if an exception was raised:
    #
    #   >> child = POSIX::Spawn::Child.build('git', 'log', :max => 1000)
    #   >> begin
    #   ?>   child.exec!
    #   ?> rescue POSIX::Spawn::MaximumOutputExceeded
    #   ?>   # just so you know
    #   ?> end
    #   >> child.out
    #   "... first 1000 characters of log output ..."
    #
    # Q: Why use POSIX::Spawn::Child instead of popen3, hand rolled fork/exec
    # code, or Process::spawn?
    #
    # - It's more efficient than popen3 and provides meaningful process
    #   hierarchies because it performs a single fork/exec. (popen3 double forks
    #   to avoid needing to collect the exit status and also calls
    #   Process::detach which creates a Ruby Thread!!!!).
    #
    # - It handles all max pipe buffer (PIPE_BUF) hang cases when reading and
    #   writing semi-large amounts of data. This is non-trivial to implement
    #   correctly and must be accounted for with popen3, spawn, or hand rolled
    #   fork/exec code.
    #
    # - It's more portable than hand rolled pipe, fork, exec code because
    #   fork(2) and exec aren't available on all platforms. In those cases,
    #   POSIX::Spawn::Child falls back to using whatever janky substitutes
    #   the platform provides.
    class Child
      include POSIX::Spawn

      # Spawn a new process, write all input and read all output, and wait for
      # the program to exit. Supports the standard spawn interface as described
      # in the POSIX::Spawn module documentation:
      #
      #   new([env], command, [argv1, ...], [options])
      #
      # The following options are supported in addition to the standard
      # POSIX::Spawn options:
      #
      #   :input   => str      Write str to the new process's standard input.
      #   :timeout => int      Maximum number of seconds to allow the process
      #                        to execute before aborting with a TimeoutExceeded
      #                        exception.
      #   :max     => total    Maximum number of bytes of output to allow the
      #                        process to generate before aborting with a
      #                        MaximumOutputExceeded exception.
      #   :pgroup_kill => bool Boolean specifying whether to kill the process
      #                        group (true) or individual process (false, default).
      #                        Setting this option true implies :pgroup => true.
      #
      # Returns a new Child instance whose underlying process has already
      # executed to completion. The out, err, and status attributes are
      # immediately available.
      def initialize(*args)
        @env, @argv, options = extract_process_spawn_arguments(*args)
        @options = options.dup
        @input = @options.delete(:input)
        @timeout = @options.delete(:timeout)
        @max = @options.delete(:max)
        if @options.delete(:pgroup_kill)
          @pgroup_kill = true
          @options[:pgroup] = true
        end
        @options.delete(:chdir) if @options[:chdir].nil?
        exec! if !@options.delete(:noexec)
      end

      # Set up a new process to spawn, but do not actually spawn it.
      #
      # Invoke this just like the normal constructor to set up a process
      # to be run.  Call `exec!` to actually run the child process, send
      # the input, read the output, and wait for completion.  Use this
      # alternative way of constructing a POSIX::Spawn::Child if you want
      # to read any partial output from the child process even after an
      # exception.
      #
      #   child = POSIX::Spawn::Child.build(... arguments ...)
      #   child.exec!
      #
      # The arguments are the same as the regular constructor.
      #
      # Returns a new Child instance but does not run the underlying process.
      def self.build(*args)
        options =
          if args[-1].respond_to?(:to_hash)
            args.pop.to_hash
          else
            {}
          end
        new(*(args + [{ :noexec => true }.merge(options)]))
      end

      # All data written to the child process's stdout stream as a String.
      attr_reader :out

      # All data written to the child process's stderr stream as a String.
      attr_reader :err

      # A Process::Status object with information on how the child exited.
      attr_reader :status

      # Total command execution time (wall-clock time)
      attr_reader :runtime

      # The pid of the spawned child process. This is unlikely to be a valid
      # current pid since Child#exec! doesn't return until the process finishes
      # and is reaped.
      attr_reader :pid

      # Determine if the process did exit with a zero exit status.
      def success?
        @status && @status.success?
      end

      # Execute command, write input, and read output. This is called
      # immediately when a new instance of this object is created, or
      # can be called explicitly when creating the Child via `build`.
      def exec!
        # spawn the process and hook up the pipes
        pid, stdin, stdout, stderr = popen4(@env, *(@argv + [@options]))
        @pid = pid

        # async read from all streams into buffers
        read_and_write(@input, stdin, stdout, stderr, @timeout, @max)

        # grab exit status
        @status = waitpid(pid)
      rescue Object
        [stdin, stdout, stderr].each { |fd| fd.close rescue nil }
        if @status.nil?
          if !@pgroup_kill
            ::Process.kill('TERM', pid) rescue nil
          else
            ::Process.kill('-TERM', pid) rescue nil
          end
          @status = waitpid(pid) rescue nil
        end
        raise
      ensure
        # let's be absolutely certain these are closed
        [stdin, stdout, stderr].each { |fd| fd.close rescue nil }
      end

    private
      # Maximum buffer size for reading
      BUFSIZE = (32 * 1024)

      # Start a select loop writing any input on the child's stdin and reading
      # any output from the child's stdout or stderr.
      #
      # input   - String input to write on stdin. May be nil.
      # stdin   - The write side IO object for the child's stdin stream.
      # stdout  - The read side IO object for the child's stdout stream.
      # stderr  - The read side IO object for the child's stderr stream.
      # timeout - An optional Numeric specifying the total number of seconds
      #           the read/write operations should occur for.
      #
      # Returns an [out, err] tuple where both elements are strings with all
      #   data written to the stdout and stderr streams, respectively.
      # Raises TimeoutExceeded when all data has not been read / written within
      #   the duration specified in the timeout argument.
      # Raises MaximumOutputExceeded when the total number of bytes output
      #   exceeds the amount specified by the max argument.
      def read_and_write(input, stdin, stdout, stderr, timeout=nil, max=nil)
        max = nil if max && max <= 0
        @out, @err = '', ''

        # force all string and IO encodings to BINARY under 1.9 for now
        if @out.respond_to?(:force_encoding) and stdin.respond_to?(:set_encoding)
          [stdin, stdout, stderr].each do |fd|
            fd.set_encoding('BINARY', 'BINARY')
          end
          @out.force_encoding('BINARY')
          @err.force_encoding('BINARY')
          input = input.dup.force_encoding('BINARY') if input
        end

        timeout = nil if timeout && timeout <= 0.0
        @runtime = 0.0
        start = Time.now

        readers = [stdout, stderr]
        writers =
          if input
            [stdin]
          else
            stdin.close
            []
          end
        slice_method = input.respond_to?(:byteslice) ? :byteslice : :slice
        t = timeout

        while readers.any? || writers.any?
          ready = IO.select(readers, writers, readers + writers, t)
          raise TimeoutExceeded if ready.nil?

          # write to stdin stream
          ready[1].each do |fd|
            begin
              boom = nil
              size = fd.write_nonblock(input)
              input = input.send(slice_method, size..-1)
            rescue Errno::EPIPE => boom
            rescue Errno::EAGAIN, Errno::EINTR
            end
            if boom || input.bytesize == 0
              stdin.close
              writers.delete(stdin)
            end
          end

          # read from stdout and stderr streams
          ready[0].each do |fd|
            buf = (fd == stdout) ? @out : @err
            begin
              buf << fd.readpartial(BUFSIZE)
            rescue Errno::EAGAIN, Errno::EINTR
            rescue EOFError
              readers.delete(fd)
              fd.close
            end
          end

          # keep tabs on the total amount of time we've spent here
          @runtime = Time.now - start
          if timeout
            t = timeout - @runtime
            raise TimeoutExceeded if t < 0.0
          end

          # maybe we've hit our max output
          if max && ready[0].any? && (@out.size + @err.size) > max
            raise MaximumOutputExceeded
          end
        end

        [@out, @err]
      end

      # Wait for the child process to exit
      #
      # Returns the Process::Status object obtained by reaping the process.
      def waitpid(pid)
        ::Process::waitpid(pid)
        $?
      end
    end
  end
end
