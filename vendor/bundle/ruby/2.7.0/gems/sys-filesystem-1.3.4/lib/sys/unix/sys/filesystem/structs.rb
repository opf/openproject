require 'ffi'
require 'rbconfig'

module Sys
  class Filesystem
    module Structs
      class Statfs < FFI::Struct

        # FreeBSD 12.0 MNAMELEN from 88 => 1024.
        MNAMELEN =
          if RbConfig::CONFIG['host_os'] =~ /freebsd(.*)/i
            $1.to_f < 12.0 ? 88 : 1024
          else
            88
          end

        if RbConfig::CONFIG['host_os'] =~ /bsd/i
          layout(
            :f_version, :uint32,
            :f_type, :uint32,
            :f_flags, :uint64,
            :f_bsize, :uint64,
            :f_iosize, :int64,
            :f_blocks, :uint64,
            :f_bfree, :uint64,
            :f_bavail, :int64,
            :f_files, :uint64,
            :f_ffree, :uint64,
            :f_syncwrites, :uint64,
            :f_asyncwrites, :uint64,
            :f_syncreads, :uint64,
            :f_asyncreads, :uint64,
            :f_spare, [:uint64, 10],
            :f_namemax, :uint32,
            :f_owner, :int32,
            :f_fsid,  [:int32, 2],
            :f_charspare, [:char, 80],
            :f_fstypename, [:char, 16],
            :f_mntfromname, [:char, MNAMELEN],
            :f_mntonname, [:char, MNAMELEN]
          )
        elsif RbConfig::CONFIG['host_os'] =~ /linux/i
          layout(
            :f_type, :ulong,
            :f_bsize, :ulong,
            :f_blocks, :uint64,
            :f_bfree, :uint64,
            :f_bavail, :uint64,
            :f_files, :uint64,
            :f_ffree, :uint64,
            :f_fsid, [:int, 2],
            :f_namelen, :ulong,
            :f_frsize, :ulong,
            :f_flags, :ulong,
            :f_spare, [:ulong, 4]
          )
        else
          layout(
            :f_bsize, :uint32,
            :f_iosize, :int32,
            :f_blocks, :uint64,
            :f_bfree, :uint64,
            :f_bavail, :uint64,
            :f_files, :uint64,
            :f_ffree, :uint64,
            :f_fsid, [:int32, 2],
            :f_owner, :int32,
            :f_type, :uint32,
            :f_flags, :uint32,
            :f_fssubtype, :uint32,
            :f_fstypename, [:char, 16],
            :f_mntonname, [:char, 1024],
            :f_mntfromname, [:char, 1024],
            :f_reserved, [:uint32, 8]
          )
        end
      end

      # The Statvfs struct represents struct statvfs from sys/statvfs.h.
      class Statvfs < FFI::Struct
        if RbConfig::CONFIG['host_os'] =~ /darwin|osx|mach/i
          layout(
            :f_bsize, :ulong,
            :f_frsize, :ulong,
            :f_blocks, :uint,
            :f_bfree, :uint,
            :f_bavail, :uint,
            :f_files, :uint,
            :f_ffree, :uint,
            :f_favail, :uint,
            :f_fsid, :ulong,
            :f_flag, :ulong,
            :f_namemax, :ulong
          )
        elsif RbConfig::CONFIG['host'] =~ /bsd/i
          layout(
            :f_bavail, :uint64,
            :f_bfree, :uint64,
            :f_blocks, :uint64,
            :f_favail, :uint64,
            :f_ffree, :uint64,
            :f_files, :uint64,
            :f_bsize, :ulong,
            :f_flag, :ulong,
            :f_frsize, :ulong,
            :f_fsid, :ulong,
            :f_namemax, :ulong
          )
        elsif RbConfig::CONFIG['host'] =~ /sunos|solaris/i
          layout(
            :f_bsize, :ulong,
            :f_frsize, :ulong,
            :f_blocks, :uint64_t,
            :f_bfree, :uint64_t,
            :f_bavail, :uint64_t,
            :f_files, :uint64_t,
            :f_ffree, :uint64_t,
            :f_favail, :uint64_t,
            :f_fsid, :ulong,
            :f_basetype, [:char, 16],
            :f_flag, :ulong,
            :f_namemax, :ulong,
            :f_fstr, [:char, 32],
            :f_filler, [:ulong, 16]
          )
        else
          layout(
            :f_bsize, :ulong,
            :f_frsize, :ulong,
            :f_blocks, :uint64,
            :f_bfree, :uint64,
            :f_bavail, :uint64,
            :f_files, :uint64,
            :f_ffree, :uint64,
            :f_favail, :uint64,
            :f_fsid, :ulong,
            :f_flag, :ulong,
            :f_namemax, :ulong,
            :f_spare, [:int, 6]
          )
        end
      end

      # The Mnttab struct represents struct mnnttab from sys/mnttab.h on Solaris.
      class Mnttab < FFI::Struct
        layout(
          :mnt_special, :string,
          :mnt_mountp, :string,
          :mnt_fstype, :string,
          :mnt_mntopts, :string,
          :mnt_time, :string
        )
      end

      # The Mntent struct represents struct mntent from sys/mount.h on Unix.
      class Mntent < FFI::Struct
        layout(
          :mnt_fsname, :string,
          :mnt_dir, :string,
          :mnt_type, :string,
          :mnt_opts, :string,
          :mnt_freq, :int,
          :mnt_passno, :int
        )
      end
    end
  end
end
