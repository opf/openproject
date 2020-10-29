require 'ffi'

module Sys
  class Filesystem
    module Functions
      extend FFI::Library

      ffi_lib FFI::Library::LIBC

      if RbConfig::CONFIG['host_os'] =~ /sunos|solaris|linux/i
        attach_function(:statvfs, :statvfs64, [:string, :pointer], :int)
      else
        attach_function(:statvfs, [:string, :pointer], :int)
      end

      attach_function(:strerror, [:int], :string)
      attach_function(:mount_c, :mount, [:string, :string, :string, :ulong, :string], :int)

      begin
        attach_function(:umount_c, :umount, [:string], :int)
      rescue FFI::NotFoundError
        if RbConfig::CONFIG['host_os'] =~ /darwin|osx|mach|bsd/i
          attach_function(:umount_c, :unmount, [:string], :int)
        end
      end

      private_class_method :statvfs, :strerror, :mount_c, :umount_c

      begin
        if RbConfig::CONFIG['host_os'] =~ /sunos|solaris/i
          attach_function(:fopen, [:string, :string], :pointer)
          attach_function(:fclose, [:pointer], :int)
          attach_function(:getmntent, [:pointer, :pointer], :int)
          private_class_method :fopen, :fclose, :getmntent
        else
          attach_function(:getmntent, [:pointer], :pointer)
          attach_function(:setmntent, [:string, :string], :pointer)
          attach_function(:endmntent, [:pointer], :int)
          attach_function(:umount2, [:string, :int], :int)
          private_class_method :getmntent, :setmntent, :endmntent, :umount2
        end
      rescue FFI::NotFoundError
        if RbConfig::CONFIG['host_os'] =~ /darwin|osx|mach/i
          attach_function(:getmntinfo, :getmntinfo64, [:pointer, :int], :int)
        else
          attach_function(:getmntinfo, [:pointer, :int], :int)
        end
        private_class_method :getmntinfo
      end
    end
  end
end
