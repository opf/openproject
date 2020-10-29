require 'ffi'

module Sys
  class Filesystem
    module Functions
      extend FFI::Library
      ffi_lib :kernel32

      # Make FFI functions private
      module FFI::Library
        def attach_pfunc(*args)
          attach_function(*args)
          private args[0]
        end
      end

      attach_pfunc :DeleteVolumeMountPointA, [:string], :bool
      attach_pfunc :GetDiskFreeSpaceW, [:buffer_in, :pointer, :pointer, :pointer, :pointer], :bool
      attach_pfunc :GetDiskFreeSpaceExW, [:buffer_in, :pointer, :pointer, :pointer], :bool
      attach_pfunc :GetLogicalDriveStringsA, [:ulong, :pointer], :ulong

      attach_pfunc :GetVolumeInformationA,
        [:buffer_in, :pointer, :ulong, :pointer, :pointer, :pointer, :pointer, :ulong],
        :bool

      attach_pfunc :GetVolumeInformationW,
        [:buffer_in, :pointer, :ulong, :pointer, :pointer, :pointer, :pointer, :ulong],
        :bool

      attach_pfunc :GetVolumeNameForVolumeMountPointW, [:buffer_in, :buffer_in, :ulong], :bool
      attach_pfunc :QueryDosDeviceA, [:buffer_in, :buffer_out, :ulong], :ulong
      attach_pfunc :SetVolumeMountPointW, [:buffer_in, :buffer_in], :bool

      ffi_lib :shlwapi

      attach_pfunc :PathStripToRootW, [:pointer], :bool
    end
  end
end
