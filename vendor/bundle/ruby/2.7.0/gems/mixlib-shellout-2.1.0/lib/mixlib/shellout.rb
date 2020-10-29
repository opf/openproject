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

require 'etc'
require 'tmpdir'
require 'fcntl'
require 'mixlib/shellout/exceptions'

module Mixlib

  class ShellOut
    READ_WAIT_TIME = 0.01
    READ_SIZE = 4096
    DEFAULT_READ_TIMEOUT = 600

    if RUBY_PLATFORM =~ /mswin|mingw32|windows/
      require 'mixlib/shellout/windows'
      include ShellOut::Windows
    else
      require 'mixlib/shellout/unix'
      include ShellOut::Unix
    end

    # User the command will run as. Normally set via options passed to new
    attr_accessor :user
    attr_accessor :domain
    attr_accessor :password
    # TODO remove
    attr_accessor :with_logon

    # Whether to simulate logon as the user. Normally set via options passed to new
    # Always enabled on windows
    attr_accessor :login

    # Group the command will run as. Normally set via options passed to new
    attr_accessor :group

    # Working directory for the subprocess. Normally set via options to new
    attr_accessor :cwd

    # An Array of acceptable exit codes. #error? (and #error!) use this list
    # to determine if the command was successful. Normally set via options to new
    attr_accessor :valid_exit_codes

    # When live_stdout is set, the stdout of the subprocess will be copied to it
    # as the subprocess is running.
    attr_accessor :live_stdout

    # When live_stderr is set, the stderr of the subprocess will be copied to it
    # as the subprocess is running.
    attr_accessor :live_stderr

    # ShellOut will push data from :input down the stdin of the subprocss.
    # Normally set via options passed to new.
    # Default: nil
    attr_accessor :input

    # If a logger is set, ShellOut will log a message before it executes the
    # command.
    attr_accessor :logger

    # The log level at which ShellOut should log.
    attr_accessor :log_level

    # A string which will be prepended to the log message.
    attr_accessor :log_tag

    # The command to be executed.
    attr_reader :command

    # The umask that will be set for the subcommand.
    attr_reader :umask

    # Environment variables that will be set for the subcommand. Refer to the
    # documentation of new to understand how ShellOut interprets this.
    attr_accessor :environment

    # The maximum time this command is allowed to run. Usually set via options
    # to new
    attr_writer :timeout

    # The amount of time the subcommand took to execute
    attr_reader :execution_time

    # Data written to stdout by the subprocess
    attr_reader :stdout

    # Data written to stderr by the subprocess
    attr_reader :stderr

    # A Process::Status (or ducktype) object collected when the subprocess is
    # reaped.
    attr_reader :status

    attr_reader :stdin_pipe, :stdout_pipe, :stderr_pipe, :process_status_pipe

    # === Arguments:
    # Takes a single command, or a list of command fragments. These are used
    # as arguments to Kernel.exec. See the Kernel.exec documentation for more
    # explanation of how arguments are evaluated. The last argument can be an
    # options Hash.
    # === Options:
    # If the last argument is a Hash, it is removed from the list of args passed
    # to exec and used as an options hash. The following options are available:
    # * +user+: the user the commmand should run as. if an integer is given, it is
    #   used as a uid. A string is treated as a username and resolved to a uid
    #   with Etc.getpwnam
    # * +group+: the group the command should run as. works similarly to +user+
    # * +cwd+: the directory to chdir to before running the command
    # * +umask+: a umask to set before running the command. If given as an Integer,
    #   be sure to use two leading zeros so it's parsed as Octal. A string will
    #   be treated as an octal integer
    # * +returns+:  one or more Integer values to use as valid exit codes for the
    #   subprocess. This only has an effect if you call +error!+ after
    #   +run_command+.
    # * +environment+: a Hash of environment variables to set before the command
    #   is run.
    # * +timeout+: a Numeric value for the number of seconds to wait on the
    #   child process before raising an Exception. This is calculated as the
    #   total amount of time that ShellOut waited on the child process without
    #   receiving any output (i.e., IO.select returned nil). Default is 60
    #   seconds. Note: the stdlib Timeout library is not used.
    # * +input+: A String of data to be passed to the subcommand. This is
    #   written to the child process' stdin stream before the process is
    #   launched. The child's stdin stream will be a pipe, so the size of input
    #   data should not exceed the system's default pipe capacity (4096 bytes
    #   is a safe value, though on newer Linux systems the capacity is 64k by
    #   default).
    # * +live_stream+: An IO or Logger-like object (must respond to the append
    #   operator +<<+) that will receive data as ShellOut reads it from the
    #   child process. Generally this is used to copy data from the child to
    #   the parent's stdout so that users may observe the progress of
    #   long-running commands.
    # * +login+: Whether to simulate a login (set secondary groups, primary group, environment
    #   variables etc) as done by the OS in an actual login
    # === Examples:
    # Invoke find(1) to search for .rb files:
    #   find = Mixlib::ShellOut.new("find . -name '*.rb'")
    #   find.run_command
    #   # If all went well, the results are on +stdout+
    #   puts find.stdout
    #   # find(1) prints diagnostic info to STDERR:
    #   puts "error messages" + find.stderr
    #   # Raise an exception if it didn't exit with 0
    #   find.error!
    # Run a command as the +www+ user with no extra ENV settings from +/tmp+
    #   cmd = Mixlib::ShellOut.new("apachectl", "start", :user => 'www', :env => nil, :cwd => '/tmp')
    #   cmd.run_command # etc.
    def initialize(*command_args)
      @stdout, @stderr, @process_status = '', '', ''
      @live_stdout = @live_stderr = nil
      @input = nil
      @log_level = :debug
      @log_tag = nil
      @environment = {}
      @cwd = nil
      @valid_exit_codes = [0]
      @terminate_reason = nil
      @timeout = nil

      if command_args.last.is_a?(Hash)
        parse_options(command_args.pop)
      end

      @command = command_args.size == 1 ? command_args.first : command_args
    end

    # Returns the stream that both is being used by both live_stdout and live_stderr, or nil
    def live_stream
      live_stdout == live_stderr ? live_stdout : nil
    end

    # A shortcut for setting both live_stdout and live_stderr, so that both the
    # stdout and stderr from the subprocess will be copied to the same stream as
    # the subprocess is running.
    def live_stream=(stream)
      @live_stdout = @live_stderr = stream
    end

    # Set the umask that the subprocess will have. If given as a string, it
    # will be converted to an integer by String#oct.
    def umask=(new_umask)
      @umask = (new_umask.respond_to?(:oct) ? new_umask.oct : new_umask.to_i) & 007777
    end

    # The uid that the subprocess will switch to. If the user attribute was
    # given as a username, it is converted to a uid by Etc.getpwnam
    # TODO migrate to shellout/unix.rb
    def uid
      return nil unless user
      user.kind_of?(Integer) ? user : Etc.getpwnam(user.to_s).uid
    end

    # The gid that the subprocess will switch to. If the group attribute is
    # given as a group name, it is converted to a gid by Etc.getgrnam
    # TODO migrate to shellout/unix.rb
    def gid
      return group.kind_of?(Integer) ? group : Etc.getgrnam(group.to_s).gid if group
      return Etc.getpwuid(uid).gid if using_login?
      return nil
    end

    def timeout
      @timeout || DEFAULT_READ_TIMEOUT
    end

    # Creates a String showing the output of the command, including a banner
    # showing the exact command executed. Used by +invalid!+ to show command
    # results when the command exited with an unexpected status.
    def format_for_exception
      msg = ""
      msg << "#{@terminate_reason}\n" if @terminate_reason
      msg << "---- Begin output of #{command} ----\n"
      msg << "STDOUT: #{stdout.strip}\n"
      msg << "STDERR: #{stderr.strip}\n"
      msg << "---- End output of #{command} ----\n"
      msg << "Ran #{command} returned #{status.exitstatus}" if status
      msg
    end

    # The exit status of the subprocess. Will be nil if the command is still
    # running or died without setting an exit status (e.g., terminated by
    # `kill -9`).
    def exitstatus
      @status && @status.exitstatus
    end

    # Run the command, writing the command's standard out and standard error
    # to +stdout+ and +stderr+, and saving its exit status object to +status+
    # === Returns
    # returns   +self+; +stdout+, +stderr+, +status+, and +exitstatus+ will be
    # populated with results of the command
    # === Raises
    # * Errno::EACCES  when you are not privileged to execute the command
    # * Errno::ENOENT  when the command is not available on the system (or not
    #   in the current $PATH)
    # * CommandTimeout  when the command does not complete
    #   within +timeout+ seconds (default: 600s)
    def run_command
      if logger
        log_message = (log_tag.nil? ? "" : "#@log_tag ") << "sh(#@command)"
        logger.send(log_level, log_message)
      end
      super
    end

    # Checks the +exitstatus+ against the set of +valid_exit_codes+.
    # === Returns
    # +true+ if +exitstatus+ is not in the list of +valid_exit_codes+, false
    # otherwise.
    def error?
      !Array(valid_exit_codes).include?(exitstatus)
    end

    # If #error? is true, calls +invalid!+, which raises an Exception.
    # === Returns
    # nil::: always returns nil when it does not raise
    # === Raises
    # ::ShellCommandFailed::: via +invalid!+
    def error!
      invalid!("Expected process to exit with #{valid_exit_codes.inspect}, but received '#{exitstatus}'") if error?
    end

    # Raises a ShellCommandFailed exception, appending the
    # command's stdout, stderr, and exitstatus to the exception message.
    # === Arguments
    # +msg+:  A String to use as the basis of the exception message. The
    # default explanation is very generic, providing a more informative message
    # is highly encouraged.
    # === Raises
    # ShellCommandFailed  always
    def invalid!(msg=nil)
      msg ||= "Command produced unexpected results"
      raise ShellCommandFailed, msg + "\n" + format_for_exception
    end

    def inspect
      "<#{self.class.name}##{object_id}: command: '#@command' process_status: #{@status.inspect} " +
      "stdout: '#{stdout.strip}' stderr: '#{stderr.strip}' child_pid: #{@child_pid.inspect} " +
      "environment: #{@environment.inspect} timeout: #{timeout} user: #@user group: #@group working_dir: #@cwd >"
    end

    private

    def parse_options(opts)
      opts.each do |option, setting|
        case option.to_s
        when 'cwd'
          self.cwd = setting
        when 'domain'
          self.domain = setting
        when 'password'
          self.password = setting
        when 'user'
          self.user = setting
          self.with_logon = setting
        when 'group'
          self.group = setting
        when 'umask'
          self.umask = setting
        when 'timeout'
          self.timeout = setting
        when 'returns'
          self.valid_exit_codes = Array(setting)
        when 'live_stream'
          self.live_stdout = self.live_stderr = setting
        when 'live_stdout'
          self.live_stdout = setting
        when 'live_stderr'
          self.live_stderr = setting
        when 'input'
          self.input = setting
        when 'logger'
          self.logger = setting
        when 'log_level'
          self.log_level = setting
        when 'log_tag'
          self.log_tag = setting
        when 'environment', 'env'
          self.environment = setting || {}
        when 'login'
          self.login = setting
        else
          raise InvalidCommandOption, "option '#{option.inspect}' is not a valid option for #{self.class.name}"
        end
      end

      validate_options(opts)
    end

    def validate_options(opts)
      if login && !user
        raise InvalidCommandOption, "cannot set login without specifying a user"
      end
      super
    end
  end
end
