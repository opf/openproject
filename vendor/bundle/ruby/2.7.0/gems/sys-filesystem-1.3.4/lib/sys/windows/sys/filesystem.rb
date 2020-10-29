require_relative 'filesystem/constants'
require_relative 'filesystem/functions'
require_relative 'filesystem/helper'

require 'socket'
require 'win32ole'
require 'date'
require 'time'

# The Sys module serves as a namespace only.
module Sys

  # The Filesystem class encapsulates information about your filesystem.
  class Filesystem
    include Sys::Filesystem::Constants
    extend Sys::Filesystem::Functions

    # Error typically raised if any of the Sys::Filesystem methods fail.
    class Error < StandardError; end

    class Mount
      # The name of the volume. This is the device mapping.
      attr_reader :name

      # The last time the volume was mounted. For MS Windows this equates
      # to your system's boot time.
      attr_reader :mount_time

      # The type of mount, e.g. NTFS, UDF, etc.
      attr_reader :mount_type

      # The volume mount point, e.g. 'C:\'
      attr_reader :mount_point

      # Various comma separated options that reflect the volume's features
      attr_reader :options

      # Always nil on MS Windows. Provided for interface compatibility only.
      attr_reader :pass_number

      # Always nil on MS Windows. Provided for interface compatibility only.
      attr_reader :frequency

      alias fsname name
      alias dir mount_point
      alias opts options
      alias passno pass_number
      alias freq frequency
    end

    class Stat
      # The path of the file system.
      attr_reader :path

      # The file system block size. MS Windows typically defaults to 4096.
      attr_reader :block_size

      # Fragment size. Meaningless at the moment.
      attr_reader :fragment_size

      # The total number of blocks available (used or unused) on the file
      # system.
      attr_reader :blocks

      # The total number of unused blocks.
      attr_reader :blocks_free

      # The total number of unused blocks available to unprivileged processes.
      attr_reader :blocks_available

      # Total number of files/inodes that can be created on the file system.
      # This attribute is always nil on MS Windows.
      attr_reader :files

      # Total number of free files/inodes that can be created on the file
      # system. This attribute is always nil on MS Windows.
      attr_reader :files_free

      # Total number of available files/inodes for unprivileged processes
      # that can be created on the file system. This attribute is always
      # nil on MS Windows.
      attr_reader :files_available

      # The file system volume id.
      attr_reader :filesystem_id

      # A bit mask of file system flags.
      attr_reader :flags

      # The maximum length of a file name permitted on the file system.
      attr_reader :name_max

      # The file system type, e.g. NTFS, FAT, etc.
      attr_reader :base_type

      # The total amount of free space on the partition.
      attr_reader :bytes_free

      # The amount of free space available to unprivileged processes.
      attr_reader :bytes_available

      alias inodes files
      alias inodes_free files_free
      alias inodes_available files_available

      # Returns the total space on the partition.
      def bytes_total
        blocks * block_size
      end

      # Returns the total amount of used space on the partition.
      def bytes_used
        bytes_total - bytes_free
      end

      # Returns the percentage of the partition that has been used.
      def percent_used
        100 - (100.0 * bytes_free.to_f / bytes_total.to_f)
      end
    end

    # Yields a Filesystem::Mount object for each volume on your system in
    # block form. Returns an array of Filesystem::Mount objects in non-block
    # form.
    #
    # Example:
    #
    #    Sys::Filesystem.mounts{ |mount|
    #       p mt.name        # => \\Device\\HarddiskVolume1
    #       p mt.mount_point # => C:\
    #       p mt.mount_time  # => Thu Dec 18 20:12:08 -0700 2008
    #       p mt.mount_type  # => NTFS
    #       p mt.options     # => casepres,casesens,ro,unicode
    #       p mt.pass_number # => nil
    #       p mt.dump_freq   # => nil
    #    }
    #
    # This method is a bit of a fudge for MS Windows in the name of interface
    # compatibility because this method deals with volumes, not actual mount
    # points. But, I believe it provides the sort of information many users
    # want at a glance.
    #
    # The possible values for the +options+ and their meanings are as follows:
    #
    # casepres     => The filesystem preserves the case of file names when it places a name on disk.
    # casesens     => The filesystem supports case-sensitive file names.
    # compression  => The filesystem supports file-based compression.
    # namedstreams => The filesystem supports named streams.
    # pacls        => The filesystem preserves and enforces access control lists.
    # ro           => The filesystem is read-only.
    # encryption   => The filesystem supports the Encrypted File System (EFS).
    # objids       => The filesystem supports object identifiers.
    # rpoints      => The filesystem supports reparse points.
    # sparse       => The filesystem supports sparse files.
    # unicode      => The filesystem supports Unicode in file names as they appear on disk.
    # compressed   => The filesystem is compressed.
    #
    #--
    # I couldn't really find a good reason to use the wide functions for this
    # method. If you have one, patches welcome.
    #
    def self.mounts
      # First call, get needed buffer size
      buffer = 0.chr
      length = GetLogicalDriveStringsA(buffer.size, buffer)

      if length == 0
        raise SystemCallError.new('GetLogicalDriveStrings', FFI.errno)
      else
        buffer = 0.chr * length
      end

      mounts = block_given? ? nil : []

      # Try again with new buffer size
      if GetLogicalDriveStringsA(buffer.size, buffer) == 0
        raise SystemCallError.new('GetLogicalDriveStrings', FFI.errno)
      end

      drives = buffer.split(0.chr)

      boot_time = get_boot_time

      drives.each{ |drive|
        mount  = Mount.new
        volume = FFI::MemoryPointer.new(:char, MAXPATH)
        fsname = FFI::MemoryPointer.new(:char, MAXPATH)

        mount.instance_variable_set(:@mount_point, drive)
        mount.instance_variable_set(:@mount_time, boot_time)

        volume_serial_number = FFI::MemoryPointer.new(:ulong)
        max_component_length = FFI::MemoryPointer.new(:ulong)
        filesystem_flags     = FFI::MemoryPointer.new(:ulong)

        bool = GetVolumeInformationA(
           drive,
           volume,
           volume.size,
           volume_serial_number,
           max_component_length,
           filesystem_flags,
           fsname,
           fsname.size
        )

        # Skip unmounted floppies or cd-roms, or inaccessible drives
        unless bool
          if [5,21].include?(FFI.errno) # ERROR_NOT_READY or ERROR_ACCESS_DENIED
            next
          else
            raise SystemCallError.new('GetVolumeInformation', FFI.errno)
          end
        end

        filesystem_flags = filesystem_flags.read_ulong
        fsname = fsname.read_string

        name = 0.chr * MAXPATH

        if QueryDosDeviceA(drive[0,2], name, name.size) == 0
          raise SystemCallError.new('QueryDosDevice', FFI.errno)
        end

        mount.instance_variable_set(:@name, name.strip)
        mount.instance_variable_set(:@mount_type, fsname)
        mount.instance_variable_set(:@options, get_options(filesystem_flags))

        if block_given?
          yield mount
        else
          mounts << mount
        end
      }

      mounts # Nil if the block form was used.
    end

    # Returns the mount point for the given +file+. For MS Windows this
    # means the root of the path.
    #
    # Example:
    #
    #    File.mount_point("C:\\Documents and Settings") # => "C:\\'
    #
    def self.mount_point(file)
      wfile = FFI::MemoryPointer.from_string(file.to_s.wincode)

      if PathStripToRootW(wfile)
        wfile.read_string(wfile.size).split("\000\000").first.tr(0.chr, '')
      else
        nil
      end
    end

    # Returns a Filesystem::Stat object that contains information about the
    # +path+ file system. On Windows this will default to using the root
    # path for volume information.
    #
    # Examples:
    #
    #    Sys::Filesystem.stat("C:\\")
    #    Sys::Filesystem.stat("C:\\Documents and Settings\\some_user")
    #
    def self.stat(path)
      bytes_avail = FFI::MemoryPointer.new(:ulong_long)
      bytes_free  = FFI::MemoryPointer.new(:ulong_long)
      total_bytes = FFI::MemoryPointer.new(:ulong_long)

      mpoint = mount_point(path).to_s
      mpoint << '/' unless mpoint.end_with?('/')

      wpath  = path.to_s.wincode

      # We need this call for the 64 bit support
      unless GetDiskFreeSpaceExW(wpath, bytes_avail, total_bytes, bytes_free)
        raise SystemCallError.new('GetDiskFreeSpaceEx', FFI.errno)
      end

      bytes_avail = bytes_avail.read_ulong_long
      bytes_free  = bytes_free.read_ulong_long
      total_bytes = total_bytes.read_ulong_long

      sectors_ptr = FFI::MemoryPointer.new(:ulong_long)
      bytes_ptr   = FFI::MemoryPointer.new(:ulong_long)
      free_ptr    = FFI::MemoryPointer.new(:ulong_long)
      total_ptr   = FFI::MemoryPointer.new(:ulong_long)

      # We need this call for the total/cluster info, which is not in the Ex call.
      unless GetDiskFreeSpaceW(wpath, sectors_ptr, bytes_ptr, free_ptr, total_ptr)
        raise SystemCallError.new('GetDiskFreeSpace', FFI.errno)
      end

      sectors_per_cluster = sectors_ptr.read_ulong_long
      bytes_per_sector    = bytes_ptr.read_ulong_long

      free_ptr.free
      total_ptr.free

      block_size   = sectors_per_cluster * bytes_per_sector
      blocks_avail = bytes_avail / block_size
      blocks_free  = bytes_free / block_size
      total_blocks = total_bytes / block_size

      vol_name_ptr   = FFI::MemoryPointer.new(:char, MAXPATH)
      base_type_ptr  = FFI::MemoryPointer.new(:char, MAXPATH)
      vol_serial_ptr = FFI::MemoryPointer.new(:ulong)
      name_max_ptr   = FFI::MemoryPointer.new(:ulong)
      flags_ptr      = FFI::MemoryPointer.new(:ulong)

      bool = GetVolumeInformationW(
        mpoint.wincode,
        vol_name_ptr,
        vol_name_ptr.size,
        vol_serial_ptr,
        name_max_ptr,
        flags_ptr,
        base_type_ptr,
        base_type_ptr.size
      )

      unless bool
        raise SystemCallError.new('GetVolumeInformation', FFI.errno)
      end

      vol_serial = vol_serial_ptr.read_ulong
      name_max   = name_max_ptr.read_ulong
      flags      = flags_ptr.read_ulong
      base_type  = base_type_ptr.read_string(base_type_ptr.size).tr(0.chr, '')

      # Lets explicitly free our pointers
      vol_name_ptr.free
      vol_serial_ptr.free
      name_max_ptr.free
      flags_ptr.free
      base_type_ptr.free
      sectors_ptr.free
      bytes_ptr.free

      stat_obj = Stat.new
      stat_obj.instance_variable_set(:@path, path)
      stat_obj.instance_variable_set(:@block_size, block_size)
      stat_obj.instance_variable_set(:@blocks, total_blocks)
      stat_obj.instance_variable_set(:@blocks_available, blocks_avail)
      stat_obj.instance_variable_set(:@blocks_free, blocks_free)
      stat_obj.instance_variable_set(:@name_max, name_max)
      stat_obj.instance_variable_set(:@base_type, base_type)
      stat_obj.instance_variable_set(:@flags, flags)
      stat_obj.instance_variable_set(:@filesystem_id, vol_serial)
      stat_obj.instance_variable_set(:@bytes_free, bytes_free)
      stat_obj.instance_variable_set(:@bytes_available, bytes_avail)

      stat_obj.freeze # Read-only object
    end

    # Associate a volume with a drive letter or a directory on another volume.
    #
    def self.mount(target, source)
      targetw = target.to_s.wincode
      sourcew = source.to_s.wincode

      volume_namew = (0.chr * 256).wincode

      unless GetVolumeNameForVolumeMountPointW(sourcew, volume_namew, volume_namew.size)
        raise SystemCallError.new('GetVolumeNameForVolumeMountPoint', FFI.errno)
      end

      unless SetVolumeMountPointW(targetw, volume_namew)
        raise SystemCallError.new('SetVolumeMountPoint', FFI.errno)
      end

      self
    end

    # Deletes a drive letter or mounted folder.
    #
    def self.umount(mount_point)
      unless DeleteVolumeMountPoint(mount_point)
        raise SystemCallError.new('DeleteVolumeMountPoint', FFI.errno)
      end

      self
    end

    private

    # This method is used to get the boot time of the system, which is used
    # for the mount_time attribute within the File.mounts method.
    #
    def self.get_boot_time
      host = Socket.gethostname
      cs = "winmgmts://#{host}/root/cimv2"
      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => e
        raise Error, e
      else
        query = 'select LastBootupTime from Win32_OperatingSystem'
        results = wmi.ExecQuery(query)
        results.each{ |ole|
          time_array = Time.parse(ole.LastBootupTime.split('.').first)
          return Time.mktime(*time_array)
        }
      end
    end

    # Private method that converts filesystem flags into a comma separated
    # list of strings. The presentation is meant as a rough analogue to the
    # way options are presented for Unix filesystems.
    #
    def self.get_options(flags)
       str = ""
       str << " casepres" if CASE_PRESERVED_NAMES & flags > 0
       str << " casesens" if CASE_SENSITIVE_SEARCH & flags > 0
       str << " compression" if FILE_COMPRESSION & flags > 0
       str << " namedstreams" if NAMED_STREAMS & flags > 0
       str << " pacls" if PERSISTENT_ACLS & flags > 0
       str << " ro" if READ_ONLY_VOLUME & flags > 0
       str << " encryption" if SUPPORTS_ENCRYPTION & flags > 0
       str << " objids" if SUPPORTS_OBJECT_IDS & flags > 0
       str << " rpoints" if SUPPORTS_REPARSE_POINTS & flags > 0
       str << " sparse" if SUPPORTS_SPARSE_FILES & flags > 0
       str << " unicode" if UNICODE_ON_DISK & flags > 0
       str << " compressed" if VOLUME_IS_COMPRESSED & flags > 0

       str.tr!(' ', ',')
       str = str[1..-1] # Ignore the first comma
       str
    end
  end
end
