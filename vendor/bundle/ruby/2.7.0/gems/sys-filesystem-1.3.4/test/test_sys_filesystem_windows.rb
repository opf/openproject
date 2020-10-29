####################################################################
# test_sys_filesystem_windows.rb
#
# Test case for the Sys::Filesystem.stat method and related stuff.
# This should be run via the 'rake test' task.
####################################################################
require 'test-unit'
require 'sys/filesystem'
require 'rbconfig'
require 'pathname'
include Sys

class TC_Sys_Filesystem_Windows < Test::Unit::TestCase
  def setup
    @dir   = 'C:/'
    @stat  = Filesystem.stat(@dir)
    @mount = Filesystem.mounts[0]
    @size  = 58720256
    @array = []
  end

  test "version number is set to the expected value" do
    assert_equal('1.3.4', Filesystem::VERSION)
    assert_true(Filesystem::VERSION.frozen?)
  end

  test "stat path works as expected" do
    assert_respond_to(@stat, :path)
    assert_equal("C:/", @stat.path)
  end

  test "stat block_size works as expected" do
    assert_respond_to(@stat, :block_size)
    assert_kind_of(Numeric, @stat.block_size)
  end

  test "stat works with or without trailing slash on standard paths" do
    assert_equal("C:/", Filesystem.stat("C:/").path)
    assert_equal("C:/Users", Filesystem.stat("C:/Users").path)
    assert_equal("C:/Users/", Filesystem.stat("C:/Users/").path)
    assert_equal("C:/Users/", Filesystem.stat("C:/Users/").path)
  end

  test "stat works with or without trailing slash on UNC paths" do
    assert_equal("//127.0.0.1/C$", Filesystem.stat("//127.0.0.1/C$").path)
    assert_equal("//127.0.0.1/C$/", Filesystem.stat("//127.0.0.1/C$/").path)
    assert_equal("\\\\127.0.0.1\\C$", Filesystem.stat("\\\\127.0.0.1\\C$").path)
    assert_equal("\\\\127.0.0.1\\C$\\", Filesystem.stat("\\\\127.0.0.1\\C$\\").path)
  end

  test "stat fragment_size works as expected" do
    assert_respond_to(@stat, :fragment_size)
    assert_nil(@stat.fragment_size)
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

  test "block stats return expected relative values" do
    assert_true(@stat.blocks >= @stat.blocks_free)
    assert_true(@stat.blocks_free >= @stat.blocks_available)
  end

  test "stat files works as expected" do
    assert_respond_to(@stat, :files)
    assert_nil(@stat.files)
  end

  test "stat inodes is an alias for files" do
    assert_alias_method(@stat, :inodes, :files)
  end

  test "stat files_free works as expected" do
    assert_respond_to(@stat, :files_free)
    assert_nil(@stat.files_free)
  end

  test "stat inodes_free is an alias for files_free" do
    assert_respond_to(@stat, :inodes_free)
  end

  test "stat files available works as expected" do
    assert_respond_to(@stat, :files_available)
    assert_nil(@stat.files_available)
  end

  test "stat inodes_available is an alias for files_available" do
    assert_alias_method(@stat, :inodes_available, :files_available)
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
    assert_respond_to(@stat, :base_type)
    assert_kind_of(String, @stat.base_type)
  end

  test "stat bytes_total basic functionality" do
    assert_respond_to(@stat, :bytes_total)
    assert_kind_of(Numeric, @stat.bytes_total)
  end

  test "stat bytes_free basic functionality" do
    assert_respond_to(@stat, :bytes_free)
    assert_kind_of(Numeric, @stat.bytes_free)
    assert_equal(@stat.bytes_free, @stat.blocks_free * @stat.block_size)
  end

  test "stat bytes_available basic functionality" do
    assert_respond_to(@stat, :bytes_available)
    assert_kind_of(Numeric, @stat.bytes_available)
    assert_equal(@stat.bytes_available, @stat.blocks_available * @stat.block_size)
  end

  test "stat bytes_used basic functionality" do
    assert_respond_to(@stat, :bytes_used)
    assert_kind_of(Numeric, @stat.bytes_used)
  end

  test "stat percent_used basic functionality" do
    assert_respond_to(@stat, :percent_used)
    assert_kind_of(Float, @stat.percent_used)
  end

  test "case_insensitive returns expected result" do
    assert_respond_to(@stat, :case_insensitive?)
    assert_true(@stat.case_insensitive?)
  end

  test "mount_point singleton method basic functionality" do
    assert_respond_to(Filesystem, :mount_point)
    assert_nothing_raised{ Filesystem.mount_point(Dir.pwd) }
    assert_kind_of(String, Filesystem.mount_point(Dir.pwd))
  end

  test "mount_point singleton method returns expected value" do
    assert_equal("C:\\", Filesystem.mount_point("C:\\Users\\foo"))
    assert_equal("\\\\foo\\bar", Filesystem.mount_point("//foo/bar/baz"))
  end

  test "mount_point works with Pathname object" do
    assert_nothing_raised{ Filesystem.mount_point(Pathname.new("C:/Users/foo")) }
    assert_equal("C:\\", Filesystem.mount_point("C:\\Users\\foo"))
    assert_equal("\\\\foo\\bar", Filesystem.mount_point("//foo/bar/baz"))
  end

  test "filesystem constants are defined" do
    assert_not_nil(Filesystem::CASE_SENSITIVE_SEARCH)
    assert_not_nil(Filesystem::CASE_PRESERVED_NAMES)
    assert_not_nil(Filesystem::UNICODE_ON_DISK)
    assert_not_nil(Filesystem::PERSISTENT_ACLS)
    assert_not_nil(Filesystem::FILE_COMPRESSION)
    assert_not_nil(Filesystem::VOLUME_QUOTAS)
    assert_not_nil(Filesystem::SUPPORTS_SPARSE_FILES)
    assert_not_nil(Filesystem::SUPPORTS_REPARSE_POINTS)
    assert_not_nil(Filesystem::SUPPORTS_REMOTE_STORAGE)
    assert_not_nil(Filesystem::VOLUME_IS_COMPRESSED)
    assert_not_nil(Filesystem::SUPPORTS_OBJECT_IDS)
    assert_not_nil(Filesystem::SUPPORTS_ENCRYPTION)
    assert_not_nil(Filesystem::NAMED_STREAMS)
    assert_not_nil(Filesystem::READ_ONLY_VOLUME)
  end

  test "stat singleton method defaults to root path if proviced" do
    assert_nothing_raised{ Filesystem.stat("C://Program Files") }
  end

  test "stat singleton method accepts a Pathname object" do
    assert_nothing_raised{ Filesystem.stat(Pathname.new("C://Program Files")) }
  end

  test "stat singleton method requires a single argument" do
    assert_raise(ArgumentError){ Filesystem.stat }
    assert_raise(ArgumentError){ Filesystem.stat(Dir.pwd, Dir.pwd) }
  end

  test "stat singleton method raises an error if path is not found" do
    assert_raise(Errno::ESRCH){ Filesystem.stat("C://Bogus//Dir") }
  end

   # Filesystem.mounts

  test "mounts singleton method basic functionality" do
    assert_respond_to(Filesystem, :mounts)
    assert_nothing_raised{ Filesystem.mounts }
    assert_nothing_raised{ Filesystem.mounts{} }
  end

  test "mounts singleton method returns the expected value" do
    assert_kind_of(Array, Filesystem.mounts)
    assert_kind_of(Filesystem::Mount, Filesystem.mounts[0])
  end

  test "mounts singleton method works as expected when a block is provided" do
    assert_nil(Filesystem.mounts{})
    assert_nothing_raised{ Filesystem.mounts{ |mt| @array << mt }}
    assert_kind_of(Filesystem::Mount, @array[0])
  end

  test "mount name works as expected" do
    assert_respond_to(@mount, :name)
    assert_kind_of(String, @mount.name)
  end

  test "mount time works as expected" do
    assert_respond_to(@mount, :mount_time)
    assert_kind_of(Time, @mount.mount_time)
  end

  test "mount type works as expected" do
    assert_respond_to(@mount, :mount_type)
    assert_kind_of(String, @mount.mount_type)
  end

  test "mount point works as expected" do
    assert_respond_to(@mount, :mount_point)
    assert_kind_of(String, @mount.mount_point)
  end

  test "mount options works as expected" do
    assert_respond_to(@mount, :options)
    assert_kind_of(String, @mount.options)
  end

  test "mount pass_number works as expected" do
    assert_respond_to(@mount, :pass_number)
    assert_nil(@mount.pass_number)
  end

  test "mount frequency works as expected" do
    assert_respond_to(@mount, :frequency)
    assert_nil(@mount.frequency)
  end

  test "mounts singleton method does not accept any arguments" do
    assert_raise(ArgumentError){ Filesystem.mounts("C:\\") }
  end

  test "custom Numeric#to_kb method works as expected" do
    assert_respond_to(@size, :to_kb)
    assert_equal(57344, @size.to_kb)
  end

  test "custom Numeric#to_mb method works as expected" do
    assert_respond_to(@size, :to_mb)
    assert_equal(56, @size.to_mb)
  end

  test "custom Numeric#to_gb method works as expected" do
    assert_respond_to(@size, :to_gb)
    assert_equal(0, @size.to_gb)
  end

  # Mount and Unmount

  test "mount singleton method exists" do
    assert_respond_to(Sys::Filesystem, :mount)
  end

  test "umount singleton method exists" do
    assert_respond_to(Sys::Filesystem, :umount)
  end

  # FFI

  test "internal ffi functions are not public" do
    assert_false(Filesystem.methods.include?(:GetVolumeInformationA))
    assert_false(Filesystem.instance_methods.include?(:GetVolumeInformationA))
  end

  def teardown
    @array = nil
    @dir   = nil
    @stat  = nil
    @size  = nil
    @mount = nil
  end
end
