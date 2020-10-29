####################################################################
# test_sys_filesystem_unix.rb
#
# Test case for the Sys::Filesystem.stat method and related stuff.
# This test suite should be run via the 'rake test' task.
####################################################################
require 'test-unit'
require 'sys-filesystem'
require 'mkmf-lite'
include Sys
include Mkmf::Lite

class TC_Sys_Filesystem_Unix < Test::Unit::TestCase
  def self.startup
    @@solaris = RbConfig::CONFIG['host_os'] =~ /solaris/i
    @@linux   = RbConfig::CONFIG['host_os'] =~ /linux/i
    @@freebsd = RbConfig::CONFIG['host_os'] =~ /freebsd/i
    @@darwin  = RbConfig::CONFIG['host_os'] =~ /darwin/i
  end

  def setup
    @dir   = "/"
    @stat  = Filesystem.stat(@dir)
    @mnt   = Filesystem.mounts[0]
    @size  = 58720256
    @array = []
  end

  test "version number is set to the expected value" do
    assert_equal('1.3.4', Filesystem::VERSION)
    assert_true(Filesystem::VERSION.frozen?)
  end

  test "stat path works as expected" do
    assert_respond_to(@stat, :path)
    assert_equal("/", @stat.path)
  end

  test "stat block_size works as expected" do
    assert_respond_to(@stat, :block_size)
    assert_kind_of(Numeric, @stat.block_size)
  end

  test "stat fragment_size works as expected" do
    assert_respond_to(@stat, :fragment_size)
    assert_kind_of(Numeric, @stat.fragment_size)
  end

  test "stat fragment_size is a plausible value" do
    assert_true(@stat.fragment_size >= 512)
    assert_true(@stat.fragment_size <= 16384)
  end

  test "stat blocks works as expected" do
    assert_respond_to(@stat, :blocks)
    assert_kind_of(Numeric, @stat.blocks)
  end

  test "stat blocks_free works as expected" do
    assert_respond_to(@stat, :blocks_free)
    assert_kind_of(Numeric, @stat.blocks_free)
  end

  test "stat blocks_available works as expected" do
    assert_respond_to(@stat, :blocks_available)
    assert_kind_of(Numeric, @stat.blocks_available)
  end

  test "stat files works as expected" do
    assert_respond_to(@stat, :files)
    assert_kind_of(Numeric, @stat.files)
  end

  test "stat inodes is an alias for files" do
    assert_respond_to(@stat, :inodes)
    assert_true(@stat.method(:inodes) == @stat.method(:files))
  end

  test "stat files tree works as expected" do
    assert_respond_to(@stat, :files_free)
    assert_kind_of(Numeric, @stat.files_free)
  end

  test "stat inodes_free is an alias for files_free" do
    assert_respond_to(@stat, :inodes_free)
    assert_true(@stat.method(:inodes_free) == @stat.method(:files_free))
  end

  test "stat files_available works as expected" do
    assert_respond_to(@stat, :files_available)
    assert_kind_of(Numeric, @stat.files_available)
  end

  test "stat inodes_available is an alias for files_available" do
    assert_respond_to(@stat, :inodes_available)
    assert_true(@stat.method(:inodes_available) == @stat.method(:files_available))
  end

  test "stat filesystem_id works as expected" do
    assert_respond_to(@stat, :filesystem_id)
    assert_kind_of(Integer, @stat.filesystem_id)
  end

  test "stat flags works as expected" do
    assert_respond_to(@stat, :flags)
    assert_kind_of(Numeric, @stat.flags)
  end

  test "stat name_max works as expected" do
    assert_respond_to(@stat, :name_max)
    assert_kind_of(Numeric, @stat.name_max)
  end

  test "stat base_type works as expected" do
    omit_unless(@@solaris, "base_type test skipped except on Solaris")

    assert_respond_to(@stat, :base_type)
    assert_kind_of(String, @stat.base_type)
  end

  test "stat constants are defined" do
    assert_not_nil(Filesystem::Stat::RDONLY)
    assert_not_nil(Filesystem::Stat::NOSUID)

    omit_unless(@@solaris, "NOTRUNC test skipped except on Solaris")

    assert_not_nil(Filesystem::Stat::NOTRUNC)
  end

  test "stat bytes_total works as expected" do
    assert_respond_to(@stat, :bytes_total)
    assert_kind_of(Numeric, @stat.bytes_total)
  end

  test "stat bytes_free works as expected" do
    assert_respond_to(@stat, :bytes_free)
    assert_kind_of(Numeric, @stat.bytes_free)
    assert_equal(@stat.bytes_free, @stat.blocks_free * @stat.fragment_size)
  end

  test "stat bytes_available works as expected" do
    assert_respond_to(@stat, :bytes_available)
    assert_kind_of(Numeric, @stat.bytes_available)
    assert_equal(@stat.bytes_available, @stat.blocks_available * @stat.fragment_size)
  end

  test "stat bytes works as expected" do
    assert_respond_to(@stat, :bytes_used)
    assert_kind_of(Numeric, @stat.bytes_used)
  end

  test "stat percent_used works as expected" do
    assert_respond_to(@stat, :percent_used)
    assert_kind_of(Float, @stat.percent_used)
  end

  test "stat singleton method requires an argument" do
    assert_raises(ArgumentError){ Filesystem.stat }
  end

  test "stat case_insensitive method works as expected" do
    expected = @@darwin ? true : false
    assert_equal(expected, @stat.case_insensitive?)
    assert_equal(expected, Filesystem.stat(Dir.home).case_insensitive?)
  end

  test "stat case_sensitive method works as expected" do
    expected = @@darwin ? false : true
    assert_equal(expected, @stat.case_sensitive?)
    assert_equal(expected, Filesystem.stat(Dir.home).case_sensitive?)
  end

  test "numeric helper methods are defined" do
    assert_respond_to(@size, :to_kb)
    assert_respond_to(@size, :to_mb)
    assert_respond_to(@size, :to_gb)
    assert_respond_to(@size, :to_tb)
  end

  test "to_kb works as expected" do
    assert_equal(57344, @size.to_kb)
  end

  test "to_mb works as expected" do
    assert_equal(56, @size.to_mb)
  end

  test "to_gb works as expected" do
    assert_equal(0, @size.to_gb)
  end

  # Filesystem::Mount tests

  test "mounts singleton method works as expected without a block" do
    assert_nothing_raised{ @array = Filesystem.mounts }
    assert_kind_of(Filesystem::Mount, @array[0])
  end

  test "mounts singleton method works as expected with a block" do
    assert_nothing_raised{ Filesystem.mounts{ |m| @array << m } }
    assert_kind_of(Filesystem::Mount, @array[0])
  end

  test "calling the mounts singleton method a large number of times does not cause issues" do
    assert_nothing_raised{ 1000.times{ @array = Filesystem.mounts } }
  end

  test "mount name method works as expected" do
    assert_respond_to(@mnt, :name)
    assert_kind_of(String, @mnt.name)
  end

  test "mount fsname is an alias for name" do
    assert_respond_to(@mnt, :fsname)
    assert_true(@mnt.method(:fsname) == @mnt.method(:name))
  end

  test "mount point method works as expected" do
    assert_respond_to(@mnt, :mount_point)
    assert_kind_of(String, @mnt.mount_point)
  end

  test "mount dir is an alias for mount_point" do
    assert_respond_to(@mnt, :dir)
    assert_true(@mnt.method(:dir) == @mnt.method(:mount_point))
  end

  test "mount mount_type works as expected" do
    assert_respond_to(@mnt, :mount_type)
    assert_kind_of(String, @mnt.mount_type)
  end

  test "mount options works as expected" do
    assert_respond_to(@mnt, :options)
    assert_kind_of(String, @mnt.options)
  end

  test "mount opts is an alias for options" do
    assert_respond_to(@mnt, :opts)
    assert_true(@mnt.method(:opts) == @mnt.method(:options))
  end

  test "mount time works as expected" do
    assert_respond_to(@mnt, :mount_time)

    if @@solaris
      assert_kind_of(Time, @mnt.mount_time)
    else
      assert_nil(@mnt.mount_time)
    end
  end

  test "mount dump_frequency works as expected" do
    msg = 'dump_frequency test skipped on this platform'
    omit_if(@@solaris || @@freebsd || @@darwin, msg)
    assert_respond_to(@mnt, :dump_frequency)
    assert_kind_of(Numeric, @mnt.dump_frequency)
  end

  test "mount freq is an alias for dump_frequency" do
    assert_respond_to(@mnt, :freq)
    assert_true(@mnt.method(:freq) == @mnt.method(:dump_frequency))
  end

  test "mount pass_number works as expected" do
    msg = 'pass_number test skipped on this platform'
    omit_if(@@solaris || @@freebsd || @@darwin, msg)
    assert_respond_to(@mnt, :pass_number)
    assert_kind_of(Numeric, @mnt.pass_number)
  end

  test "mount passno is an alias for pass_number" do
    assert_respond_to(@mnt, :passno)
    assert_true(@mnt.method(:passno) == @mnt.method(:pass_number))
  end

  test "mount_point singleton method works as expected" do
    assert_respond_to(Filesystem, :mount_point)
    assert_nothing_raised{ Filesystem.mount_point(Dir.pwd) }
    assert_kind_of(String, Filesystem.mount_point(Dir.pwd))
  end

  test "mount singleton method is defined" do
    assert_respond_to(Sys::Filesystem, :mount)
  end

  test "umount singleton method is defined" do
    assert_respond_to(Sys::Filesystem, :umount)
  end

  # FFI

  test "ffi functions are private" do
    assert_false(Filesystem.methods.include?('statvfs'))
    assert_false(Filesystem.methods.include?('strerror'))
  end

  test "statfs struct is expected size" do
    header = @@freebsd || @@darwin ? 'sys/mount.h' : 'sys/statfs.h'
    assert_equal(check_sizeof('struct statfs', header), Filesystem::Structs::Statfs.size)
  end

  test "statvfs struct is expected size" do
    assert_equal(check_sizeof('struct statvfs', 'sys/statvfs.h'), Filesystem::Structs::Statvfs.size)
  end

  test "mnttab struct is expected size" do
    omit_unless(@@solaris, "mnttab test skipped except on Solaris")
    assert_equal(check_sizeof('struct mnttab', 'sys/mnttab.h'), Filesystem::Structs::Mnttab.size)
  end

  test "mntent struct is expected size" do
    omit_unless(@@linux, "mnttab test skipped except on Linux")
    assert_equal(check_sizeof('struct mntent', 'mntent.h'), Filesystem::Structs::Mntent.size)
  end

  def teardown
    @dir   = nil
    @stat  = nil
    @array = nil
  end

  def self.shutdown
    @@solaris = nil
    @@linux   = nil
    @@freebsd = nil
    @@darwin  = nil
  end
end
