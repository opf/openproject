#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
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

# Add new constants for Logon
module Process::Constants
  LOGON32_LOGON_INTERACTIVE = 0x00000002
  LOGON32_PROVIDER_DEFAULT  = 0x00000000
  UOI_NAME = 0x00000002
end  

# Define the functions needed to check with Service windows station
module Process::Functions
  module FFI::Library
    # Wrapper method for attach_function + private
    def attach_pfunc(*args)
      attach_function(*args)
      private args[0]
    end
  end

  extend FFI::Library

  ffi_lib :advapi32

  attach_pfunc :LogonUserW,
    [:buffer_in, :buffer_in, :buffer_in, :ulong, :ulong, :pointer], :bool

  attach_pfunc :CreateProcessAsUserW,
    [:ulong, :buffer_in, :buffer_in, :pointer, :pointer, :bool,
      :ulong, :buffer_in, :buffer_in, :pointer, :pointer], :bool

  ffi_lib :user32

  attach_pfunc :GetProcessWindowStation,
    [], :ulong

  attach_pfunc :GetUserObjectInformationA,
    [:ulong, :uint, :buffer_out, :ulong, :pointer], :bool
end

# Override Process.create to check for running in the Service window station and doing
# a full logon with LogonUser, instead of a CreateProcessWithLogon
module Process
  include Process::Constants
  include Process::Structs

  def create(args)
    unless args.kind_of?(Hash)
      raise TypeError, 'hash keyword arguments expected'
    end

    valid_keys = %w[
      app_name command_line inherit creation_flags cwd environment
      startup_info thread_inherit process_inherit close_handles with_logon
      domain password
    ]

    valid_si_keys = %w[
      startf_flags desktop title x y x_size y_size x_count_chars
      y_count_chars fill_attribute sw_flags stdin stdout stderr
    ]

    # Set default values
    hash = {
      'app_name'       => nil,
      'creation_flags' => 0,
      'close_handles'  => true
    }

    # Validate the keys, and convert symbols and case to lowercase strings.
    args.each{ |key, val|
      key = key.to_s.downcase
      unless valid_keys.include?(key)
        raise ArgumentError, "invalid key '#{key}'"
      end
      hash[key] = val
    }

    si_hash = {}

    # If the startup_info key is present, validate its subkeys
    if hash['startup_info']
      hash['startup_info'].each{ |key, val|
        key = key.to_s.downcase
        unless valid_si_keys.include?(key)
          raise ArgumentError, "invalid startup_info key '#{key}'"
        end
        si_hash[key] = val
      }
    end

    # The +command_line+ key is mandatory unless the +app_name+ key
    # is specified.
    unless hash['command_line']
      if hash['app_name']
        hash['command_line'] = hash['app_name']
        hash['app_name'] = nil
      else
        raise ArgumentError, 'command_line or app_name must be specified'
      end
    end

    env = nil

    # The env string should be passed as a string of ';' separated paths.
    if hash['environment']
      env = hash['environment']

      unless env.respond_to?(:join)
        env = hash['environment'].split(File::PATH_SEPARATOR)
      end

      env = env.map{ |e| e + 0.chr }.join('') + 0.chr
      env.to_wide_string! if hash['with_logon']
    end

    # Process SECURITY_ATTRIBUTE structure
    process_security = nil

    if hash['process_inherit']
      process_security = SECURITY_ATTRIBUTES.new
      process_security[:nLength] = 12
      process_security[:bInheritHandle] = true
    end

    # Thread SECURITY_ATTRIBUTE structure
    thread_security = nil

    if hash['thread_inherit']
      thread_security = SECURITY_ATTRIBUTES.new
      thread_security[:nLength] = 12
      thread_security[:bInheritHandle] = true
    end

    # Automatically handle stdin, stdout and stderr as either IO objects
    # or file descriptors. This won't work for StringIO, however. It also
    # will not work on JRuby because of the way it handles internal file
    # descriptors.
    #
    ['stdin', 'stdout', 'stderr'].each{ |io|
      if si_hash[io]
        if si_hash[io].respond_to?(:fileno)
          handle = get_osfhandle(si_hash[io].fileno)
        else
          handle = get_osfhandle(si_hash[io])
        end

        if handle == INVALID_HANDLE_VALUE
          ptr = FFI::MemoryPointer.new(:int)

          if windows_version >= 6 && get_errno(ptr) == 0
            errno = ptr.read_int
          else
            errno = FFI.errno
          end

          raise SystemCallError.new("get_osfhandle", errno)
        end

        # Most implementations of Ruby on Windows create inheritable
        # handles by default, but some do not. RF bug #26988.
        bool = SetHandleInformation(
          handle,
          HANDLE_FLAG_INHERIT,
          HANDLE_FLAG_INHERIT
        )

        raise SystemCallError.new("SetHandleInformation", FFI.errno) unless bool

        si_hash[io] = handle
        si_hash['startf_flags'] ||= 0
        si_hash['startf_flags'] |= STARTF_USESTDHANDLES
        hash['inherit'] = true
      end
    }

    procinfo  = PROCESS_INFORMATION.new
    startinfo = STARTUPINFO.new

    unless si_hash.empty?
      startinfo[:cb]              = startinfo.size
      startinfo[:lpDesktop]       = si_hash['desktop'] if si_hash['desktop']
      startinfo[:lpTitle]         = si_hash['title'] if si_hash['title']
      startinfo[:dwX]             = si_hash['x'] if si_hash['x']
      startinfo[:dwY]             = si_hash['y'] if si_hash['y']
      startinfo[:dwXSize]         = si_hash['x_size'] if si_hash['x_size']
      startinfo[:dwYSize]         = si_hash['y_size'] if si_hash['y_size']
      startinfo[:dwXCountChars]   = si_hash['x_count_chars'] if si_hash['x_count_chars']
      startinfo[:dwYCountChars]   = si_hash['y_count_chars'] if si_hash['y_count_chars']
      startinfo[:dwFillAttribute] = si_hash['fill_attribute'] if si_hash['fill_attribute']
      startinfo[:dwFlags]         = si_hash['startf_flags'] if si_hash['startf_flags']
      startinfo[:wShowWindow]     = si_hash['sw_flags'] if si_hash['sw_flags']
      startinfo[:cbReserved2]     = 0
      startinfo[:hStdInput]       = si_hash['stdin'] if si_hash['stdin']
      startinfo[:hStdOutput]      = si_hash['stdout'] if si_hash['stdout']
      startinfo[:hStdError]       = si_hash['stderr'] if si_hash['stderr']
    end

    app = nil
    cmd = nil

    # Convert strings to wide character strings if present
    if hash['app_name']
      app = hash['app_name'].to_wide_string
    end

    if hash['command_line']
      cmd = hash['command_line'].to_wide_string
    end

    if hash['cwd']
      cwd = hash['cwd'].to_wide_string
    end

    inherit  = hash['inherit'] || false

    if hash['with_logon']
      logon = hash['with_logon'].to_wide_string

      if hash['password']
        passwd = hash['password'].to_wide_string
      else
        raise ArgumentError, 'password must be specified if with_logon is used'
      end

      if hash['domain']
        domain = hash['domain'].to_wide_string
      end

      hash['creation_flags'] |= CREATE_UNICODE_ENVIRONMENT

      winsta_name = FFI::MemoryPointer.new(:char, 256)
      return_size = FFI::MemoryPointer.new(:ulong)

      bool = GetUserObjectInformationA(
        GetProcessWindowStation(),  # Window station handle
        UOI_NAME,                   # Information to get
        winsta_name,                # Buffer to receive information
        winsta_name.size,           # Size of buffer
        return_size                 # Size filled into buffer
      )

      unless bool
        raise SystemCallError.new("GetUserObjectInformationA", FFI.errno)
      end

      winsta_name = winsta_name.read_string(return_size.read_ulong)

      # If running in the service windows station must do a log on to get
      # to the interactive desktop.  Running process user account must have
      # the 'Replace a process level token' permission.  This is necessary as
      # the logon (which happens with CreateProcessWithLogon) must have an 
      # interactive windows station to attach to, which is created with the 
      # LogonUser cann with the LOGON32_LOGON_INTERACTIVE flag.
      if winsta_name =~ /^Service-0x0-.*$/i
        token = FFI::MemoryPointer.new(:ulong)

        bool = LogonUserW(
          logon,                      # User
          domain,                     # Domain
          passwd,                     # Password
          LOGON32_LOGON_INTERACTIVE,  # Logon Type
          LOGON32_PROVIDER_DEFAULT,   # Logon Provider
          token                       # User token handle
        )

        unless bool
          raise SystemCallError.new("LogonUserW", FFI.errno)
        end

        token = token.read_ulong

        begin
          bool = CreateProcessAsUserW(
            token,                  # User token handle
            app,                    # App name
            cmd,                    # Command line
            process_security,       # Process attributes
            thread_security,        # Thread attributes
            inherit,                # Inherit handles
            hash['creation_flags'], # Creation Flags
            env,                    # Environment
            cwd,                    # Working directory
            startinfo,              # Startup Info
            procinfo                # Process Info
          )
        ensure
          CloseHandle(token)
        end

        unless bool
          raise SystemCallError.new("CreateProcessAsUserW (You must hold the 'Replace a process level token' permission)", FFI.errno)
        end
      else
        bool = CreateProcessWithLogonW(
          logon,                  # User
          domain,                 # Domain
          passwd,                 # Password
          LOGON_WITH_PROFILE,     # Logon flags
          app,                    # App name
          cmd,                    # Command line
          hash['creation_flags'], # Creation flags
          env,                    # Environment
          cwd,                    # Working directory
          startinfo,              # Startup Info
          procinfo                # Process Info
        )
      end

      unless bool
        raise SystemCallError.new("CreateProcessWithLogonW", FFI.errno)
      end
    else
      bool = CreateProcessW(
        app,                    # App name
        cmd,                    # Command line
        process_security,       # Process attributes
        thread_security,        # Thread attributes
        inherit,                # Inherit handles?
        hash['creation_flags'], # Creation flags
        env,                    # Environment
        cwd,                    # Working directory
        startinfo,              # Startup Info
        procinfo                # Process Info
      )

      unless bool
        raise SystemCallError.new("CreateProcessW", FFI.errno)
      end
    end

    # Automatically close the process and thread handles in the
    # PROCESS_INFORMATION struct unless explicitly told not to.
    if hash['close_handles']
      CloseHandle(procinfo[:hProcess]) if procinfo[:hProcess]
      CloseHandle(procinfo[:hThread]) if procinfo[:hThread]

      # Set fields to nil so callers don't attempt to close the handle
      # which can result in the wrong handle being closed or an
      # exception in some circumstances
      procinfo[:hProcess] = nil
      procinfo[:hThread] = nil
    end

    ProcessInfo.new(
      procinfo[:hProcess],
      procinfo[:hThread],
      procinfo[:dwProcessId],
      procinfo[:dwThreadId]
    )
  end

  module_function :create
end
