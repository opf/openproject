#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
# Author:: Ho-Sheng Hsiao (<hosh@opscode.com>)
# Copyright:: Copyright (c) 2011, 2012 Opscode, Inc.
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

require 'win32/process'
require 'windows/handle'
require 'windows/process'
require 'windows/synchronize'

require 'mixlib/shellout/windows/core_ext'

module Mixlib
  class ShellOut
    module Windows

      include ::Windows::Handle
      include ::Windows::Process
      include ::Windows::Synchronize

      TIME_SLICE = 0.05

      # Option validation that is windows specific
      def validate_options(opts)
        if opts[:user]
          unless opts[:password]
            raise InvalidCommandOption, "You must supply both a username and password when supplying a user in windows"
          end
        end
      end

      #--
      # Missing lots of features from the UNIX version, such as
      # uid, etc.
      def run_command

        #
        # Create pipes to capture stdout and stderr,
        #
        stdout_read, stdout_write = IO.pipe
        stderr_read, stderr_write = IO.pipe
        stdin_read, stdin_write = IO.pipe
        open_streams = [ stdout_read, stderr_read ]

        begin

          #
          # Set cwd, environment, appname, etc.
          #
          app_name, command_line = command_to_run(self.command)
          create_process_args = {
            :app_name => app_name,
            :command_line => command_line,
            :startup_info => {
              :stdout => stdout_write,
              :stderr => stderr_write,
              :stdin => stdin_read
            },
            :environment => inherit_environment.map { |k,v| "#{k}=#{v}" },
            :close_handles => false
          }
          create_process_args[:cwd] = cwd if cwd
          # default to local account database if domain is not specified
          create_process_args[:domain] = domain.nil? ? "." : domain
          create_process_args[:with_logon] = with_logon if with_logon
          create_process_args[:password] = password if password

          #
          # Start the process
          #
          process = Process.create(create_process_args)
          begin
            # Start pushing data into input
            stdin_write << input if input

            # Close pipe to kick things off
            stdin_write.close

            #
            # Wait for the process to finish, consuming output as we go
            #
            start_wait = Time.now
            while true
              wait_status = WaitForSingleObject(process.process_handle, 0)
              case wait_status
              when WAIT_OBJECT_0
                # Get process exit code
                exit_code = [0].pack('l')
                unless GetExitCodeProcess(process.process_handle, exit_code)
                  raise get_last_error
                end
                @status = ThingThatLooksSortOfLikeAProcessStatus.new
                @status.exitstatus = exit_code.unpack('l').first

                return self
              when WAIT_TIMEOUT
                # Kill the process
                if (Time.now - start_wait) > timeout
                  begin
                    Process.kill(:KILL, process.process_id)
                  rescue Errno::EIO
                    logger.warn("Failed to kill timed out process #{process.process_id}") if logger
                  end

                  raise Mixlib::ShellOut::CommandTimeout, "command timed out:\n#{format_for_exception}"
                end

                consume_output(open_streams, stdout_read, stderr_read)
              else
                raise "Unknown response from WaitForSingleObject(#{process.process_handle}, #{timeout*1000}): #{wait_status}"
              end

            end

          ensure
            CloseHandle(process.thread_handle) if process.thread_handle
            CloseHandle(process.process_handle) if process.process_handle
          end

        ensure
          #
          # Consume all remaining data from the pipes until they are closed
          #
          stdout_write.close
          stderr_write.close

          while consume_output(open_streams, stdout_read, stderr_read)
          end
        end
      end

      private

      class ThingThatLooksSortOfLikeAProcessStatus
        attr_accessor :exitstatus
        def success?
          exitstatus == 0
        end
      end

      def consume_output(open_streams, stdout_read, stderr_read)
        return false if open_streams.length == 0
        ready = IO.select(open_streams, nil, nil, READ_WAIT_TIME)
        return true if ! ready

        if ready.first.include?(stdout_read)
          begin
            next_chunk = stdout_read.readpartial(READ_SIZE)
            @stdout << next_chunk
            @live_stdout << next_chunk if @live_stdout
          rescue EOFError
            stdout_read.close
            open_streams.delete(stdout_read)
          end
        end

        if ready.first.include?(stderr_read)
          begin
            next_chunk = stderr_read.readpartial(READ_SIZE)
            @stderr << next_chunk
            @live_stderr << next_chunk if @live_stderr
          rescue EOFError
            stderr_read.close
            open_streams.delete(stderr_read)
          end
        end

        return true
      end

      IS_BATCH_FILE = /\.bat"?$|\.cmd"?$/i

      def command_to_run(command)
        return _run_under_cmd(command) if Utils.should_run_under_cmd?(command)

        candidate = candidate_executable_for_command(command)

        # Don't do searching for empty commands.  Let it fail when it runs.
        return [ nil, command ] if candidate.length == 0

        # Check if the exe exists directly.  Otherwise, search PATH.
        exe = Utils.find_executable(candidate)
        exe = Utils.which(unquoted_executable_path(command)) if exe.nil? && exe !~ /[\\\/]/

        # Batch files MUST use cmd; and if we couldn't find the command we're looking for,
        # we assume it must be a cmd builtin.
        if exe.nil? || exe =~ IS_BATCH_FILE
          _run_under_cmd(command)
        else
          _run_directly(command, exe)
        end
      end

      # cmd does not parse multiple quotes well unless the whole thing is wrapped up in quotes.
      # https://github.com/opscode/mixlib-shellout/pull/2#issuecomment-4837859
      # http://ss64.com/nt/syntax-esc.html
      def _run_under_cmd(command)
        [ ENV['COMSPEC'], "cmd /c \"#{command}\"" ]
      end

      def _run_directly(command, exe)
        [ exe, command ]
      end

      def unquoted_executable_path(command)
        command[0,command.index(/\s/) || command.length]
      end

      def candidate_executable_for_command(command)
        if command =~ /^\s*"(.*?)"/
          # If we have quotes, do an exact match
          $1
        else
          # Otherwise check everything up to the first space
          unquoted_executable_path(command).strip
        end
      end

      def inherit_environment
        result = {}
        ENV.each_pair do |k,v|
          result[k] = v
        end

        environment.each_pair do |k,v|
          if v == nil
            result.delete(k)
          else
            result[k] = v
          end
        end
        result
      end

      module Utils
        # api: semi-private
        # If there are special characters parsable by cmd.exe (such as file redirection), then
        # this method should return true.
        #
        # This parser is based on
        # https://github.com/ruby/ruby/blob/9073db5cb1d3173aff62be5b48d00f0fb2890991/win32/win32.c#L1437
        def self.should_run_under_cmd?(command)
          return true if command =~ /^@/

          quote = nil
          env = false
          env_first_char = false

          command.dup.each_char do |c|
            case c
            when "'", '"'
              if (!quote)
                quote = c
              elsif quote == c
                quote = nil
              end
              next
            when '>', '<', '|', '&', "\n"
              return true unless quote
            when '%'
              return true if env
              env = env_first_char = true
              next
            else
              next unless env
              if env_first_char
                env_first_char = false
                env = false and next if c !~ /[A-Za-z_]/
              end
              env = false if c !~ /[A-Za-z1-9_]/
            end
          end
          return false
        end

        def self.pathext
          @pathext ||= ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') + [''] : ['']
        end

        # which() mimicks the Unix which command
        # FIXME: it is not working
        def self.which(cmd)
          ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
            exe = find_executable("#{path}/#{cmd}")
            return exe if exe
          end
          return nil
        end

        # Windows has a different notion of what "executable" means
        # The OS will search through valid the extensions and look
        # for a binary there.
        def self.find_executable(path)
          return path if File.executable? path

          pathext.each do |ext|
            exe = "#{path}#{ext}"
            return exe if File.executable? exe
          end
          return nil
        end
      end
    end # class
  end
end
