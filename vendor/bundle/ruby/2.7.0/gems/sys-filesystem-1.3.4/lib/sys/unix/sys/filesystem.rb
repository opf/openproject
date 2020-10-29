require_relative 'filesystem/constants'
require_relative 'filesystem/structs'
require_relative 'filesystem/functions'

# The Sys module serves as a namespace only.
module Sys
  # The Filesystem class serves as an abstract base class. Its methods
  # return objects of other types. Do not instantiate.
  class Filesystem
    include Sys::Filesystem::Constants
    include Sys::Filesystem::Structs
    extend Sys::Filesystem::Functions

    private

    # Readable versions of constant names
    OPT_NAMES = {
      MNT_RDONLY           => 'read-only',
      MNT_SYNCHRONOUS      => 'synchronous',
      MNT_NOEXEC           => 'noexec',
      MNT_NOSUID           => 'nosuid',
      MNT_NODEV            => 'nodev',
      MNT_UNION            => 'union',
      MNT_ASYNC            => 'asynchronous',
      MNT_CPROTECT         => 'content-protection',
      MNT_EXPORTED         => 'exported',
      MNT_QUARANTINE       => 'quarantined',
      MNT_LOCAL            => 'local',
      MNT_QUOTA            => 'quotas',
      MNT_ROOTFS           => 'rootfs',
      MNT_DONTBROWSE       => 'nobrowse',
      MNT_IGNORE_OWNERSHIP => 'noowners',
      MNT_AUTOMOUNTED      => 'automounted',
      MNT_JOURNALED        => 'journaled',
      MNT_NOUSERXATTR      => 'nouserxattr',
      MNT_DEFWRITE         => 'defwrite',
      MNT_NOATIME          => 'noatime'
    }.freeze

    # File used to read mount informtion from.
    if File.exist?('/etc/mtab')
      MOUNT_FILE = '/etc/mtab'
    elsif File.exist?('/etc/mnttab')
      MOUNT_FILE = '/etc/mnttab'
    elsif File.exist?('/proc/mounts')
      MOUNT_FILE = '/proc/mounts'
    else
      MOUNT_FILE = 'getmntinfo'
    end

    public

    # The error raised if any of the Filesystem methods fail.
    class Error < StandardError; end

    # Stat objects are returned by the Sys::Filesystem.stat method.
    class Stat
      # Read-only filesystem
      RDONLY  = 1

      # Filesystem does not support suid or sgid semantics.
      NOSUID  = 2

      # Filesystem does not truncate file names longer than +name_max+.
      NOTRUNC = 3

      # The path of the filesystem.
      attr_accessor :path

      # The preferred system block size.
      attr_accessor :block_size

      # The fragment size, i.e. fundamental filesystem block size.
      attr_accessor :fragment_size

      # The total number of +fragment_size+ blocks in the filesystem.
      attr_accessor :blocks

      # The total number of free blocks in the filesystem.
      attr_accessor :blocks_free

      # The number of free blocks available to unprivileged processes.
      attr_accessor :blocks_available

      # The total number of files/inodes that can be created.
      attr_accessor :files

      # The total number of files/inodes on the filesystem.
      attr_accessor :files_free

      # The number of free files/inodes available to unprivileged processes.
      attr_accessor :files_available

      # The filesystem identifier.
      attr_accessor :filesystem_id

      # A bit mask of flags.
      attr_accessor :flags

      # The maximum length of a file name permitted on the filesystem.
      attr_accessor :name_max

      # The filesystem type, e.g. UFS.
      attr_accessor :base_type

      alias inodes files
      alias inodes_free files_free
      alias inodes_available files_available

      # Creates a new Sys::Filesystem::Stat object. This is meant for
      # internal use only. Do not instantiate directly.
      #
      def initialize
        @path             = nil
        @block_size       = nil
        @fragment_size    = nil
        @blocks           = nil
        @blocks_free      = nil
        @blocks_available = nil
        @files            = nil
        @files_free       = nil
        @files_available  = nil
        @filesystem_id    = nil
        @flags            = nil
        @name_max         = nil
        @base_type        = nil
      end

      # Returns the total space on the partition.
      def bytes_total
        blocks * fragment_size
      end

      # Returns the total amount of free space on the partition.
      def bytes_free
        blocks_free * fragment_size
      end

      # Returns the amount of free space available to unprivileged processes.
      def bytes_available
        blocks_available * fragment_size
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

    # Mount objects are returned by the Sys::Filesystem.mounts method.
    class Mount
      # The name of the mounted resource.
      attr_accessor :name

      # The mount point/directory.
      attr_accessor :mount_point

      # The type of filesystem mount, e.g. ufs, nfs, etc.
      attr_accessor :mount_type

      # A list of comma separated options for the mount, e.g. nosuid, etc.
      attr_accessor :options

      # The time the filesystem was mounted. May be nil.
      attr_accessor :mount_time

      # The dump frequency in days. May be nil.
      attr_accessor :dump_frequency

      # The pass number of the filessytem check. May be nil.
      attr_accessor :pass_number

      alias fsname name
      alias dir mount_point
      alias opts options
      alias passno pass_number
      alias freq dump_frequency

      # Creates a Sys::Filesystem::Mount object. This is meant for internal
      # use only. Do no instantiate directly.
      #
      def initialize
        @name = nil
        @mount_point = nil
        @mount_type = nil
        @options = nil
        @mount_time = nil
        @dump_frequency = nil
        @pass_number = nil
      end
    end

    # Returns a Sys::Filesystem::Stat object containing information about the
    # +path+ on the filesystem.
    #
    def self.stat(path)
      fs = Statvfs.new

      if statvfs(path, fs) < 0
        raise Error, 'statvfs() function failed: ' + strerror(FFI.errno)
      end

      obj = Sys::Filesystem::Stat.new
      obj.path = path
      obj.block_size = fs[:f_bsize]
      obj.fragment_size = fs[:f_frsize]
      obj.blocks = fs[:f_blocks]
      obj.blocks_free = fs[:f_bfree]
      obj.blocks_available = fs[:f_bavail]
      obj.files = fs[:f_files]
      obj.files_free = fs[:f_ffree]
      obj.files_available = fs[:f_favail]
      obj.filesystem_id = fs[:f_fsid]
      obj.flags = fs[:f_flag]
      obj.name_max = fs[:f_namemax]

      # OSX does things a little differently
      if RbConfig::CONFIG['host_os'] =~ /darwin|osx|mach/i
        obj.block_size /= 256
      end

      if fs.members.include?(:f_basetype)
        obj.base_type = fs[:f_basetype].to_s
      end

      obj.freeze
    end

    # In block form, yields a Sys::Filesystem::Mount object for each mounted
    # filesytem on the host. Otherwise it returns an array of Mount objects.
    #
    # Example:
    #
    # Sys::Filesystem.mounts{ |fs|
    #   p fs.name        # => '/dev/dsk/c0t0d0s0'
    #   p fs.mount_time  # => Thu Dec 11 15:07:23 -0700 2008
    #   p fs.mount_type  # => 'ufs'
    #   p fs.mount_point # => '/'
    #   p fs.options     # => local, noowner, nosuid
    # }
    #
    def self.mounts
      array = block_given? ? nil : []

      if respond_to?(:getmntinfo, true)
        buf = FFI::MemoryPointer.new(:pointer)

        num = getmntinfo(buf, 2)

        if num == 0
          raise Error, 'getmntinfo() function failed: ' + strerror(FFI.errno)
        end

        ptr = buf.get_pointer(0)

        num.times{ |i|
          mnt = Statfs.new(ptr)
          obj = Sys::Filesystem::Mount.new
          obj.name = mnt[:f_mntfromname].to_s
          obj.mount_point = mnt[:f_mntonname].to_s
          obj.mount_type = mnt[:f_fstypename].to_s

          string = ""
          flags = mnt[:f_flags] & MNT_VISFLAGMASK

          OPT_NAMES.each{ |key,val|
            if flags & key > 0
              if string.empty?
                string << val
              else
                string << ", #{val}"
              end
            end
            flags &= ~key
          }

          obj.options = string

          if block_given?
            yield obj.freeze
          else
            array << obj.freeze
          end

          ptr += Statfs.size
        }
      else
        begin
          if respond_to?(:setmntent, true)
            method_name = 'setmntent'
            fp = setmntent(MOUNT_FILE, 'r')
          else
            method_name = 'fopen'
            fp = fopen(MOUNT_FILE, 'r')
          end

          if fp.null?
            raise SystemCallError.new(method_name, FFI.errno)
          end

          if RbConfig::CONFIG['host_os'] =~ /sunos|solaris/i
            mt = Mnttab.new
            while getmntent(fp, mt) == 0
              obj = Sys::Filesystem::Mount.new
              obj.name = mt[:mnt_special].to_s
              obj.mount_point = mt[:mnt_mountp].to_s
              obj.mount_type = mt[:mnt_fstype].to_s
              obj.options = mt[:mnt_mntopts].to_s
              obj.mount_time = Time.at(Integer(mt[:mnt_time]))

              if block_given?
                yield obj.freeze
              else
                array << obj.freeze
              end
            end
          else
            while ptr = getmntent(fp)
              break if ptr.null?
              mt = Mntent.new(ptr)

              obj = Sys::Filesystem::Mount.new
              obj.name = mt[:mnt_fsname]
              obj.mount_point = mt[:mnt_dir]
              obj.mount_type = mt[:mnt_type]
              obj.options = mt[:mnt_opts]
              obj.mount_time = nil
              obj.dump_frequency = mt[:mnt_freq]
              obj.pass_number = mt[:mnt_passno]

              if block_given?
                yield obj.freeze
              else
                array << obj.freeze
              end
            end
          end
        ensure
          if fp && !fp.null?
            if respond_to?(:endmntent, true)
              endmntent(fp)
            else
              fclose(fp)
            end
          end
        end
      end

      array
    end

    # Returns the mount point of the given +file+, or itself if it cannot
    # be found.
    #
    # Example:
    #
    #  Sys::Filesystem.mount_point('/home/some_user') # => /home
    #
    def self.mount_point(file)
      dev = File.stat(file).dev
      val = file

      self.mounts.each{ |mnt|
        mp = mnt.mount_point
        begin
          if File.stat(mp).dev == dev
            val = mp
            break
          end
        rescue Errno::EACCES
          next
        end
      }

      val
    end

    # Attach the filesystem specified by +source+ to the location (a directory
    # or file) specified by the pathname in +target+.
    #
    # Note that the +source+ is often a pathname referring to a device, but
    # can also be the pathname of a directory or file, or a dummy string.
    #
    # By default this method will assume 'ext2' as the filesystem type, but
    # you should update this as needed.
    #
    # Typically requires admin privileges.
    #
    # Example:
    #
    #   Sys::Filesystem.mount('/dev/loop0', '/home/you/tmp', 'ext4', Sys::Filesystem::MNT_RDONLY)
    #
    def self.mount(source, target, fstype = 'ext2', flags = 0, data = nil)
      if mount_c(source, target, fstype, flags, data) != 0
        raise Error, 'mount() function failed: ' + strerror(FFI.errno)
      end

      self
    end

    # Removes the attachment of the (topmost) filesystem mounted on target.
    # Additional flags may be provided for operating systems that support
    # the umount2 function. Otherwise this argument is ignored.
    #
    # Typically requires admin privileges.
    #
    def self.umount(target, flags = nil)
      if flags && respond_to?(:umount2)
        function = 'umount2'
        rv = umount2_c(target, flags)
      else
        function = 'umount'
        rv = umount_c(target)
      end

      if rv != 0
        raise Error, "#{function} function failed: " + strerror(FFI.errno)
      end

      self
    end
  end
end
