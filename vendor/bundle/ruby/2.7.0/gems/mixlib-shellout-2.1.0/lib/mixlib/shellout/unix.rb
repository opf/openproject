#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010, 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Mixlib
  class ShellOut
    module Unix

      # "1.8.7" as a frozen string. We use this with a hack that disables GC to
      # avoid segfaults on Ruby 1.8.7, so we need to allocate the fewest
      # objects we possibly can.
      ONE_DOT_EIGHT_DOT_SEVEN = "1.8.7".freeze

      # Option validation that is unix specific
      def validate_options(opts)
        # No options to validate, raise exceptions here if needed
      end

      # Whether we're simulating a login shell
      def using_login?
        return login && user
      end

      # Helper method for sgids
      def all_seconderies
        ret = []
        Etc.endgrent
        while ( g = Etc.getgrent ) do
          ret << g
        end
        Etc.endgrent
        return ret
      end

      # The secondary groups that the subprocess will switch to.
      # Currently valid only if login is used, and is set
      # to the user's secondary groups
      def sgids
        return nil unless using_login?
        user_name = Etc.getpwuid(uid).name
        all_seconderies.select{|g| g.mem.include?(user_name)}.map{|g|g.gid}
      end

      # The environment variables that are deduced from simulating logon
      # Only valid if login is used
      def logon_environment
        return {} unless using_login?
        entry = Etc.getpwuid(uid)
        # According to `man su`, the set fields are:
        #  $HOME, $SHELL, $USER, $LOGNAME, $PATH, and $IFS
        # Values are copied from "shadow" package in Ubuntu 14.10
        {'HOME'=>entry.dir, 'SHELL'=>entry.shell, 'USER'=>entry.name, 'LOGNAME'=>entry.name, 'PATH'=>'/sbin:/bin:/usr/sbin:/usr/bin', 'IFS'=>"\t\n"}
      end

      # Merges the two environments for the process
      def process_environment
        logon_environment.merge(self.environment)
      end

      # Run the command, writing the command's standard out and standard error
      # to +stdout+ and +stderr+, and saving its exit status object to +status+
      # === Returns
      # returns   +self+; +stdout+, +stderr+, +status+, and +exitstatus+ will be
      # populated with results of the command.
      # === Raises
      # * Errno::EACCES  when you are not privileged to execute the command
      # * Errno::ENOENT  when the command is not available on the system (or not
      #   in the current $PATH)
      # * Chef::Exceptions::CommandTimeout  when the command does not complete
      #   within +timeout+ seconds (default: 600s). When this happens, ShellOut
      #   will send a TERM and then KILL to the entire process group to ensure
      #   that any grandchild processes are terminated. If the invocation of
      #   the child process spawned multiple child processes (which commonly
      #   happens if the command is passed as a single string to be interpreted
      #   by bin/sh, and bin/sh is not bash), the exit status object may not
      #   contain the correct exit code of the process (of course there is no
      #   exit code if the command is killed by SIGKILL, also).
      def run_command
        @child_pid = fork_subprocess
        @reaped = false

        configure_parent_process_file_descriptors

        # Ruby 1.8.7 and 1.8.6 from mid 2009 try to allocate objects during GC
        # when calling IO.select and IO#read. Disabling GC works around the
        # segfault, but obviously it's a bad workaround. We no longer support
        # 1.8.6 so we only need this hack for 1.8.7.
        GC.disable if RUBY_VERSION == ONE_DOT_EIGHT_DOT_SEVEN

        # CHEF-3390: Marshall.load on Ruby < 1.8.7p369 also has a GC bug related
        # to Marshall.load, so try disabling GC first.
        propagate_pre_exec_failure

        @status = nil
        @result = nil
        @execution_time = 0

        write_to_child_stdin

        until @status
          ready_buffers = attempt_buffer_read
          unless ready_buffers
            @execution_time += READ_WAIT_TIME
            if @execution_time >= timeout && !@result
              # kill the bad proccess
              reap_errant_child
              # read anything it wrote when we killed it
              attempt_buffer_read
              # raise
              raise CommandTimeout, "Command timed out after #{@execution_time.to_i}s:\n#{format_for_exception}"
            end
          end

          attempt_reap
        end

        self
      rescue Errno::ENOENT
        # When ENOENT happens, we can be reasonably sure that the child process
        # is going to exit quickly, so we use the blocking variant of waitpid2
        reap
        raise
      ensure
        reap_errant_child if should_reap?
        # make one more pass to get the last of the output after the
        # child process dies
        attempt_buffer_read
        # no matter what happens, turn the GC back on, and hope whatever busted
        # version of ruby we're on doesn't allocate some objects during the next
        # GC run.
        GC.enable
        close_all_pipes
      end

      private

      def set_user
        if user
          Process.uid = uid
          Process.euid = uid
        end
      end

      def set_group
        if group
          Process.egid = gid
          Process.gid = gid
        end
      end

      def set_secondarygroups
        if sgids
          Process.groups = sgids
        end
      end

      def set_environment
        # user-set variables should override the login ones
        process_environment.each do |env_var,value|
          ENV[env_var] = value
        end
      end

      def set_umask
        File.umask(umask) if umask
      end

      def set_cwd
        Dir.chdir(cwd) if cwd
      end

      # Since we call setsid the child_pgid will be the child_pid, set to negative here
      # so it can be directly used in arguments to kill, wait, etc.
      def child_pgid
        -@child_pid
      end

      def initialize_ipc
        @stdin_pipe, @stdout_pipe, @stderr_pipe, @process_status_pipe = IO.pipe, IO.pipe, IO.pipe, IO.pipe
        @process_status_pipe.last.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
      end

      def child_stdin
        @stdin_pipe[1]
      end

      def child_stdout
        @stdout_pipe[0]
      end

      def child_stderr
        @stderr_pipe[0]
      end

      def child_process_status
        @process_status_pipe[0]
      end

      def close_all_pipes
        child_stdin.close   unless child_stdin.closed?
        child_stdout.close  unless child_stdout.closed?
        child_stderr.close  unless child_stderr.closed?
        child_process_status.close unless child_process_status.closed?
      end

      # Replace stdout, and stderr with pipes to the parent, and close the
      # reader side of the error marshaling side channel.
      #
      # If there is no input, close STDIN so when we exec,
      # the new program will know it's never getting input ever.
      def configure_subprocess_file_descriptors
        process_status_pipe.first.close

        # HACK: for some reason, just STDIN.close isn't good enough when running
        # under ruby 1.9.2, so make it good enough:
        stdin_pipe.last.close
        STDIN.reopen stdin_pipe.first
        stdin_pipe.first.close unless input

        stdout_pipe.first.close
        STDOUT.reopen stdout_pipe.last
        stdout_pipe.last.close

        stderr_pipe.first.close
        STDERR.reopen stderr_pipe.last
        stderr_pipe.last.close

        STDOUT.sync = STDERR.sync = true
        STDIN.sync = true if input
      end

      def configure_parent_process_file_descriptors
        # Close the sides of the pipes we don't care about
        stdin_pipe.first.close
        stdin_pipe.last.close unless input
        stdout_pipe.last.close
        stderr_pipe.last.close
        process_status_pipe.last.close
        # Get output as it happens rather than buffered
        child_stdin.sync = true if input
        child_stdout.sync = true
        child_stderr.sync = true

        true
      end

      # Some patch levels of ruby in wide use (in particular the ruby 1.8.6 on OSX)
      # segfault when you IO.select a pipe that's reached eof. Weak sauce.
      def open_pipes
        @open_pipes ||= [child_stdout, child_stderr, child_process_status]
      end

      # Keep this unbuffered for now
      def write_to_child_stdin
        return unless input
        child_stdin << input
        child_stdin.close # Kick things off
      end

      def attempt_buffer_read
        ready = IO.select(open_pipes, nil, nil, READ_WAIT_TIME)
        if ready
          read_stdout_to_buffer if ready.first.include?(child_stdout)
          read_stderr_to_buffer if ready.first.include?(child_stderr)
          read_process_status_to_buffer if ready.first.include?(child_process_status)
        end
        ready
      end

      def read_stdout_to_buffer
        while chunk = child_stdout.read_nonblock(READ_SIZE)
          @stdout << chunk
          @live_stdout << chunk if @live_stdout
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete(child_stdout)
      end

      def read_stderr_to_buffer
        while chunk = child_stderr.read_nonblock(READ_SIZE)
          @stderr << chunk
          @live_stderr << chunk if @live_stderr
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete(child_stderr)
      end

      def read_process_status_to_buffer
        while chunk = child_process_status.read_nonblock(READ_SIZE)
          @process_status << chunk
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete(child_process_status)
      end

      def fork_subprocess
        initialize_ipc

        fork do
          # Child processes may themselves fork off children. A common case
          # is when the command is given as a single string (instead of
          # command name plus Array of arguments) and /bin/sh does not
          # support the "ONESHOT" optimization (where sh -c does exec without
          # forking). To support cleaning up all the children, we need to
          # ensure they're in a unique process group.
          #
          # We use setsid here to abandon our controlling tty and get a new session
          # and process group that are set to the pid of the child process.
          Process.setsid

          configure_subprocess_file_descriptors

          set_secondarygroups
          set_group
          set_user
          set_environment
          set_umask
          set_cwd

          begin
            command.kind_of?(Array) ? exec(*command, :close_others=>true) : exec(command, :close_others=>true)

            raise 'forty-two' # Should never get here
          rescue Exception => e
            Marshal.dump(e, process_status_pipe.last)
            process_status_pipe.last.flush
          end
          process_status_pipe.last.close unless (process_status_pipe.last.closed?)
          exit!
        end
      end

      # Attempt to get a Marshaled error from the side-channel.
      # If it's there, un-marshal it and raise. If it's not there,
      # assume everything went well.
      def propagate_pre_exec_failure
        begin
          attempt_buffer_read until child_process_status.eof?
          e = Marshal.load(@process_status)
          raise(Exception === e ? e : "unknown failure: #{e.inspect}")
        rescue ArgumentError # If we get an ArgumentError error, then the exec was successful
          true
        ensure
          child_process_status.close
          open_pipes.delete(child_process_status)
        end
      end

      def reap_errant_child
        return if attempt_reap
        @terminate_reason = "Command exceeded allowed execution time, process terminated"
        logger.error("Command exceeded allowed execution time, sending TERM") if logger
        Process.kill(:TERM, child_pgid)
        sleep 3
        attempt_reap
        logger.error("Command exceeded allowed execution time, sending KILL") if logger
        Process.kill(:KILL, child_pgid)
        reap

        # Should not hit this but it's possible if something is calling waitall
        # in a separate thread.
      rescue Errno::ESRCH
        nil
      end

      def should_reap?
        # if we fail to fork, no child pid so nothing to reap
        @child_pid && !@reaped
      end

      # Unconditionally reap the child process. This is used in scenarios where
      # we can be confident the child will exit quickly, and has not spawned
      # and grandchild processes.
      def reap
        results = Process.waitpid2(@child_pid)
        @reaped = true
        @status = results.last
      rescue Errno::ECHILD
        # When cleaning up timed-out processes, we might send SIGKILL to the
        # whole process group after we've cleaned up the direct child. In that
        # case the grandchildren will have been adopted by init so we can't
        # reap them even if we wanted to (we don't).
        nil
      end

      # Try to reap the child process but don't block if it isn't dead yet.
      def attempt_reap
        if results = Process.waitpid2(@child_pid, Process::WNOHANG)
          @reaped = true
          @status = results.last
        else
          nil
        end
      end

    end
  end
end
