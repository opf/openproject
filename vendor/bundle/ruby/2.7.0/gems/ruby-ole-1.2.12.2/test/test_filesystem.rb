#! /usr/bin/ruby
# encoding: ASCII-8BIT

#
# = NOTE
#
# This file was originally called "zipfilesystemtest.rb", and was part of
# the test case for the "rubyzip" project.
#
# As I borrowed the smart idea of using a filesystem style interface, it
# only seemed right that I appropriate the test case in addition :). It is
# a testament to the cleanliness of the original api & tests as to how
# easy it was to repurpose it for this project.
#
# I have made some modifications to the file due to some differences in the
# capabilities of zip vs ole, but the majority of the copyright and credit
# still goes to Thomas. His original copyright message:
#
#   Copyright (C) 2002, 2003 Thomas Sondergaard
#   rubyzip is free software; you can redistribute it and/or
#   modify it under the terms of the ruby license.
#

TEST_DIR = File.dirname __FILE__
$:.unshift "#{TEST_DIR}/../lib"

require 'ole/storage'
require 'test/unit'

module ExtraAssertions

	def assert_forwarded(anObject, method, retVal, *expectedArgs)
		callArgs = nil
		setCallArgsProc = proc { |args| callArgs = args }
		anObject.instance_eval <<-"end_eval"
			alias #{method}_org #{method}
			def #{method}(*args)
				ObjectSpace._id2ref(#{setCallArgsProc.object_id}).call(args)
				ObjectSpace._id2ref(#{retVal.object_id})
				end
		end_eval

		assert_equal(retVal, yield) # Invoke test
		assert_equal(expectedArgs, callArgs)
	ensure
		anObject.instance_eval "alias #{method} #{method}_org"
	end

end

class OleFsNonmutatingTest < Test::Unit::TestCase
	def setup
		@ole = Ole::Storage.open TEST_DIR + '/oleWithDirs.ole', 'rb'
	end

	def teardown
		@ole.close if @ole
	end

=begin
	def test_umask
		assert_equal(File.umask, @ole.file.umask)
		@ole.file.umask(0006)
	end
=end

	def test_exists?
		assert(! @ole.file.exists?("notAFile"))
		assert(@ole.file.exists?("file1"))
		assert(@ole.file.exists?("dir1"))
		assert(@ole.file.exists?("dir1/"))
		assert(@ole.file.exists?("dir1/file12"))
		assert(@ole.file.exist?("dir1/file12")) # notice, tests exist? alias of exists? !

		@ole.dir.chdir "dir1/"
		assert(!@ole.file.exists?("file1"))
		assert(@ole.file.exists?("file12"))
	end

	def test_open_read
		blockCalled = false
		@ole.file.open("file1", "r") {
			|f|
			blockCalled = true
			assert_equal("this is the entry 'file1' in my test archive!", 
										f.readline.chomp)
		}
		assert(blockCalled)

		blockCalled = false
		@ole.dir.chdir "dir2"
		@ole.file.open("file21", "r") {
			|f|
			blockCalled = true
			assert_equal("this is the entry 'dir2/file21' in my test archive!", 
										f.readline.chomp)
		}
		assert(blockCalled)
		@ole.dir.chdir "/"
		
		assert_raise(Errno::ENOENT) {
			@ole.file.open("noSuchEntry")
		}

		begin
			is = @ole.file.open("file1")
			assert_equal("this is the entry 'file1' in my test archive!", 
										is.readline.chomp)
		ensure
			is.close if is
		end
	end

	def test_new
		begin
			is = @ole.file.new("file1")
			assert_equal("this is the entry 'file1' in my test archive!", 
										is.readline.chomp)
		ensure
			is.close if is
		end
		begin
			is = @ole.file.new("file1") {
				fail "should not call block"
			}
		ensure
			is.close if is
		end
	end

	# currently commented out because I've taken the approach of
	# using implicit NameError rather than explicit NotImplementedError.
=begin
	def test_symlink
		assert_raise(NotImplementedError) {
			@ole.file.symlink("file1", "aSymlink")
		}
	end
=end

	def test_size
		assert_raise(Errno::ENOENT) { @ole.file.size("notAFile") }
		assert_equal(72, @ole.file.size("file1"))
		assert_equal(0, @ole.file.size("dir2/dir21"))

		assert_equal(72, @ole.file.stat("file1").size)
		assert_equal(0, @ole.file.stat("dir2/dir21").size)
	end

	def test_size?
		assert_equal(nil, @ole.file.size?("notAFile"))
		assert_equal(72, @ole.file.size?("file1"))
		assert_equal(nil, @ole.file.size?("dir2/dir21"))

		assert_equal(72, @ole.file.stat("file1").size?)
		assert_equal(nil, @ole.file.stat("dir2/dir21").size?)
	end

	def test_file?
		assert(@ole.file.file?("file1"))
		assert(@ole.file.file?("dir2/file21"))
		assert(! @ole.file.file?("dir1"))
		assert(! @ole.file.file?("dir1/dir11"))

		assert(@ole.file.stat("file1").file?)
		assert(@ole.file.stat("dir2/file21").file?)
		assert(! @ole.file.stat("dir1").file?)
		assert(! @ole.file.stat("dir1/dir11").file?)
	end

=begin
	include ExtraAssertions

	def test_dirname
		assert_forwarded(File, :dirname, "retVal", "a/b/c/d") { 
			@ole.file.dirname("a/b/c/d")
		}
	end

	def test_basename
		assert_forwarded(File, :basename, "retVal", "a/b/c/d") { 
			@ole.file.basename("a/b/c/d")
		}
	end

	def test_split
		assert_forwarded(File, :split, "retVal", "a/b/c/d") { 
			@ole.file.split("a/b/c/d")
		}
	end

	def test_join
		assert_equal("a/b/c", @ole.file.join("a/b", "c"))
		assert_equal("a/b/c/d", @ole.file.join("a/b", "c/d"))
		assert_equal("/c/d", @ole.file.join("", "c/d"))
		assert_equal("a/b/c/d", @ole.file.join("a", "b", "c", "d"))
	end

	def test_utime
		t_now = Time.now
		t_bak = @ole.file.mtime("file1")
		@ole.file.utime(t_now, "file1")
		assert_equal(t_now, @ole.file.mtime("file1"))
		@ole.file.utime(t_bak, "file1")
		assert_equal(t_bak, @ole.file.mtime("file1"))
	end


	def assert_always_false(operation)
		assert(! @ole.file.send(operation, "noSuchFile"))
		assert(! @ole.file.send(operation, "file1"))
		assert(! @ole.file.send(operation, "dir1"))
		assert(! @ole.file.stat("file1").send(operation))
		assert(! @ole.file.stat("dir1").send(operation))
	end

	def assert_true_if_entry_exists(operation)
		assert(! @ole.file.send(operation, "noSuchFile"))
		assert(@ole.file.send(operation, "file1"))
		assert(@ole.file.send(operation, "dir1"))
		assert(@ole.file.stat("file1").send(operation))
		assert(@ole.file.stat("dir1").send(operation))
	end

	def test_pipe?
		assert_always_false(:pipe?)
	end

	def test_blockdev?
		assert_always_false(:blockdev?)
	end

	def test_symlink?
		assert_always_false(:symlink?)
	end

	def test_socket?
		assert_always_false(:socket?)
	end

	def test_chardev?
		assert_always_false(:chardev?)
	end

	def test_truncate
		assert_raise(StandardError, "truncate not supported") {
			@ole.file.truncate("file1", 100)
		}
	end

	def assert_e_n_o_e_n_t(operation, args = ["NoSuchFile"])
		assert_raise(Errno::ENOENT) {
			@ole.file.send(operation, *args)
		}
	end

	def test_ftype
		assert_e_n_o_e_n_t(:ftype)
		assert_equal("file", @ole.file.ftype("file1"))
		assert_equal("directory", @ole.file.ftype("dir1/dir11"))
		assert_equal("directory", @ole.file.ftype("dir1/dir11/"))
	end
=end

	def test_directory?
		assert(! @ole.file.directory?("notAFile"))
		assert(! @ole.file.directory?("file1"))
		assert(! @ole.file.directory?("dir1/file11"))
		assert(@ole.file.directory?("dir1"))
		assert(@ole.file.directory?("dir1/"))
		assert(@ole.file.directory?("dir2/dir21"))

		assert(! @ole.file.stat("file1").directory?)
		assert(! @ole.file.stat("dir1/file11").directory?)
		assert(@ole.file.stat("dir1").directory?)
		assert(@ole.file.stat("dir1/").directory?)
		assert(@ole.file.stat("dir2/dir21").directory?)
	end

=begin
	def test_chown
		assert_equal(2, @ole.file.chown(1,2, "dir1", "file1"))
		assert_equal(1, @ole.file.stat("dir1").uid)
		assert_equal(2, @ole.file.stat("dir1").gid)
		assert_equal(2, @ole.file.chown(nil, nil, "dir1", "file1"))
	end

	def test_zero?
		assert(! @ole.file.zero?("notAFile"))
		assert(! @ole.file.zero?("file1"))
		assert(@ole.file.zero?("dir1"))
		blockCalled = false
		ZipFile.open("data/generated/5entry.zip") {
			|zf|
			blockCalled = true
			assert(zf.file.zero?("data/generated/empty.txt"))
		}
		assert(blockCalled)

		assert(! @ole.file.stat("file1").zero?)
		assert(@ole.file.stat("dir1").zero?)
		blockCalled = false
		ZipFile.open("data/generated/5entry.zip") {
			|zf|
			blockCalled = true
			assert(zf.file.stat("data/generated/empty.txt").zero?)
		}
		assert(blockCalled)
	end
=end

	def test_expand_path
		assert_equal("/", @ole.file.expand_path("."))
		@ole.dir.chdir "dir1"
		assert_equal("/dir1", @ole.file.expand_path("."))
		assert_equal("/dir1/file12", @ole.file.expand_path("file12"))
		assert_equal("/", @ole.file.expand_path(".."))
		assert_equal("/dir2/dir21", @ole.file.expand_path("../dir2/dir21"))
	end

=begin
	def test_mtime
		assert_equal(Time.at(1027694306),
									@ole.file.mtime("dir2/file21"))
		assert_equal(Time.at(1027690863),
									@ole.file.mtime("dir2/dir21"))
		assert_raise(Errno::ENOENT) {
			@ole.file.mtime("noSuchEntry")
		}

		assert_equal(Time.at(1027694306),
									@ole.file.stat("dir2/file21").mtime)
		assert_equal(Time.at(1027690863),
									@ole.file.stat("dir2/dir21").mtime)
	end

	def test_ctime
		assert_nil(@ole.file.ctime("file1"))
		assert_nil(@ole.file.stat("file1").ctime)
	end

	def test_atime
		assert_nil(@ole.file.atime("file1"))
		assert_nil(@ole.file.stat("file1").atime)
	end

	def test_readable?
		assert(! @ole.file.readable?("noSuchFile"))
		assert(@ole.file.readable?("file1"))
		assert(@ole.file.readable?("dir1"))
		assert(@ole.file.stat("file1").readable?)
		assert(@ole.file.stat("dir1").readable?)
	end

	def test_readable_real?
		assert(! @ole.file.readable_real?("noSuchFile"))
		assert(@ole.file.readable_real?("file1"))
		assert(@ole.file.readable_real?("dir1"))
		assert(@ole.file.stat("file1").readable_real?)
		assert(@ole.file.stat("dir1").readable_real?)
	end

	def test_writable?
		assert(! @ole.file.writable?("noSuchFile"))
		assert(@ole.file.writable?("file1"))
		assert(@ole.file.writable?("dir1"))
		assert(@ole.file.stat("file1").writable?)
		assert(@ole.file.stat("dir1").writable?)
	end

	def test_writable_real?
		assert(! @ole.file.writable_real?("noSuchFile"))
		assert(@ole.file.writable_real?("file1"))
		assert(@ole.file.writable_real?("dir1"))
		assert(@ole.file.stat("file1").writable_real?)
		assert(@ole.file.stat("dir1").writable_real?)
	end

	def test_executable?
		assert(! @ole.file.executable?("noSuchFile"))
		assert(! @ole.file.executable?("file1"))
		assert(@ole.file.executable?("dir1"))
		assert(! @ole.file.stat("file1").executable?)
		assert(@ole.file.stat("dir1").executable?)
	end

	def test_executable_real?
		assert(! @ole.file.executable_real?("noSuchFile"))
		assert(! @ole.file.executable_real?("file1"))
		assert(@ole.file.executable_real?("dir1"))
		assert(! @ole.file.stat("file1").executable_real?)
		assert(@ole.file.stat("dir1").executable_real?)
	end

	def test_owned?
		assert_true_if_entry_exists(:owned?)
	end

	def test_grpowned?
		assert_true_if_entry_exists(:grpowned?)
	end

	def test_setgid?
		assert_always_false(:setgid?)
	end

	def test_setuid?
		assert_always_false(:setgid?)
	end

	def test_sticky?
		assert_always_false(:sticky?)
	end

	def test_stat
		s = @ole.file.stat("file1")
		assert(s.kind_of?(File::Stat)) # It pretends
		assert_raise(Errno::ENOENT, "No such file or directory - noSuchFile") {
			@ole.file.stat("noSuchFile")
		}
	end

	def test_lstat
		assert(@ole.file.lstat("file1").file?)
	end


	def test_chmod
		assert_raise(Errno::ENOENT, "No such file or directory - noSuchFile") {
			@ole.file.chmod(0644, "file1", "NoSuchFile")
		}
		assert_equal(2, @ole.file.chmod(0644, "file1", "dir1"))
	end

	def test_pipe
		assert_raise(NotImplementedError) {
			@ole.file.pipe
		}
	end

	def test_foreach
		ZipFile.open("data/generated/zipWithDir.zip") {
			|zf|
			ref = []
			File.foreach("data/file1.txt") { |e| ref << e }
			
			index = 0
			zf.file.foreach("data/file1.txt") { 
				|l|
				assert_equal(ref[index], l)
				index = index.next
			}
			assert_equal(ref.size, index)
		}
		
		ZipFile.open("data/generated/zipWithDir.zip") {
			|zf|
			ref = []
			File.foreach("data/file1.txt", " ") { |e| ref << e }
			
			index = 0
			zf.file.foreach("data/file1.txt", " ") { 
				|l|
				assert_equal(ref[index], l)
				index = index.next
			}
			assert_equal(ref.size, index)
		}
	end

	def test_popen
		cmd = /mswin/i =~ RUBY_PLATFORM ? 'dir' : 'ls'

		assert_equal(File.popen(cmd)          { |f| f.read }, 
									@ole.file.popen(cmd) { |f| f.read })
	end

# Can be added later
#  def test_select
#    fail "implement test"
#  end

	def test_readlines
		ZipFile.open("data/generated/zipWithDir.zip") {
			|zf|
			assert_equal(File.readlines("data/file1.txt"), 
										zf.file.readlines("data/file1.txt"))
		}
	end

	def test_read
		ZipFile.open("data/generated/zipWithDir.zip") {
			|zf|
			assert_equal(File.read("data/file1.txt"), 
										zf.file.read("data/file1.txt"))
		}
	end
=end
end

class OleFsFileStatTest < Test::Unit::TestCase

	def setup
		@ole = Ole::Storage.open TEST_DIR + '/oleWithDirs.ole', 'rb'
	end

	def teardown
		@ole.close if @ole
	end

	def test_blocks
		assert_equal(2, @ole.file.stat("file1").blocks)
	end

	def test_ino
		assert_equal(0, @ole.file.stat("file1").ino)
	end

	def test_uid
		assert_equal(0, @ole.file.stat("file1").uid)
	end

	def test_gid
		assert_equal(0, @ole.file.stat("file1").gid)
	end

	def test_ftype
		assert_equal("file", @ole.file.stat("file1").ftype)
		assert_equal("directory", @ole.file.stat("dir1").ftype)
	end

=begin
	def test_mode
		assert_equal(0600, @ole.file.stat("file1").mode & 0777)
		assert_equal(0600, @ole.file.stat("file1").mode & 0777)
		assert_equal(0755, @ole.file.stat("dir1").mode & 0777)
		assert_equal(0755, @ole.file.stat("dir1").mode & 0777)
	end
=end

	def test_dev
		assert_equal(0, @ole.file.stat("file1").dev)
	end

	def test_rdev
		assert_equal(0, @ole.file.stat("file1").rdev)
	end

	def test_rdev_major
		assert_equal(0, @ole.file.stat("file1").rdev_major)
	end

	def test_rdev_minor
		assert_equal(0, @ole.file.stat("file1").rdev_minor)
	end

	def test_nlink
		assert_equal(1, @ole.file.stat("file1").nlink)
	end

	def test_blksize
		assert_equal(64, @ole.file.stat("file1").blksize)
	end

	# an additional test i added for coverage. i've tried to make the inspect
	# string on the ole stat match that of the regular one.
	def test_inspect
		# normalize, as instance_variables order is undefined
		normalize = proc { |s| s[/ (.*)>$/, 1].split(', ').sort.join(', ') }
		assert_match %r{blocks=2.*ftype=file.*size=72}, normalize[@ole.file.stat('file1').inspect]
	end
end

class OleFsFileMutatingTest < Test::Unit::TestCase
	def setup
		# we use an in memory copy of the file instead of the original
		# file based.
		@io = StringIO.new open(TEST_DIR + '/oleWithDirs.ole', 'rb', &:read)
	end

	def teardown
		@io.close if @io
	end
 
	def test_delete
		do_test_delete_or_unlink(:delete)
	end

	def test_unlink
		do_test_delete_or_unlink(:unlink)
	end
	
	def test_open_write
		Ole::Storage.open(@io) {
			|zf|

			blockCalled = nil
			zf.file.open("test_open_write_entry", "w") {
				|f|
				blockCalled = true
				f.write "This is what I'm writing"
			}
			assert(blockCalled)
			assert_equal("This is what I'm writing",
										zf.file.read("test_open_write_entry"))

			blockCalled = nil
			# Test with existing entry
			zf.file.open("file1", "w") {
				|f|
				blockCalled = true
				f.write "This is what I'm writing too"
			}
			assert(blockCalled)
			assert_equal("This is what I'm writing too",
										zf.file.read("file1"))
		}
	end

	def test_rename
		Ole::Storage.open(@io) {
			|zf|
			assert_raise(Errno::ENOENT, "") { 
				zf.file.rename("NoSuchFile", "bimse")
			}
			zf.file.rename("file1", "newNameForFile1")
			# lets also try moving a file to a different directory,
			# and renaming a directory
			zf.file.rename('/dir1/file11', '/dir1/dir11/file111')
			zf.file.rename('dir1', 'dir9')
		}

		Ole::Storage.open(@io) {
			|zf|
			assert(! zf.file.exists?("file1"))
			assert(zf.file.exists?("newNameForFile1"))
			assert(zf.file.exists?("dir9/dir11/file111"))
		}
	end

	def do_test_delete_or_unlink(symbol)
		Ole::Storage.open(@io) {
			|zf|
			assert(zf.file.exists?("dir2/dir21/dir221/file2221"))
			zf.file.send(symbol, "dir2/dir21/dir221/file2221")
			assert(! zf.file.exists?("dir2/dir21/dir221/file2221"))

			assert(zf.file.exists?("dir1/file11"))
			assert(zf.file.exists?("dir1/file12"))
			zf.file.send(symbol, "dir1/file11", "dir1/file12")
			assert(! zf.file.exists?("dir1/file11"))
			assert(! zf.file.exists?("dir1/file12"))

			assert_raise(Errno::ENOENT) { zf.file.send(symbol, "noSuchFile") }
			assert_raise(Errno::EISDIR) { zf.file.send(symbol, "dir1/dir11") }
			assert_raise(Errno::EISDIR) { zf.file.send(symbol, "dir1/dir11/") }
		}

		Ole::Storage.open(@io) {
			|zf|
			assert(! zf.file.exists?("dir2/dir21/dir221/file2221"))
			assert(! zf.file.exists?("dir1/file11"))
			assert(! zf.file.exists?("dir1/file12"))

			assert(zf.file.exists?("dir1/dir11"))
			assert(zf.file.exists?("dir1/dir11/"))
		}
	end

end

class OleFsDirectoryTest < Test::Unit::TestCase
	def setup
		# we use an in memory copy of the file instead of the original
		# file based.
		@io = StringIO.new open(TEST_DIR + '/oleWithDirs.ole', 'rb', &:read)
	end

	def teardown
		@io.close if @io
	end
	
	def test_delete
		Ole::Storage.open(@io) {
			|zf|
			assert_raise(Errno::ENOENT, "No such file or directory - NoSuchFile.txt") {
				zf.dir.delete("NoSuchFile.txt")
			}
			# see explanation below, touch a && ruby -e 'Dir.delete "a"' gives ENOTDIR not EINVAL
			assert_raise(Errno::ENOTDIR, "Invalid argument - file1") {
				zf.dir.delete("file1")
			}
			assert(zf.file.exists?("dir1"))
			#zf.dir.delete("dir1")
			#assert(! zf.file.exists?("dir1"))
			# ^ this was allowed in zipfilesystem, but my code follows Dir.delete, and requires that
			# the directory be empty first. need to delete recursively if you want other behaviour.
			assert_raises(Errno::ENOTEMPTY) { zf.dir.delete('dir1') }
		}
	end

	def test_mkdir
		Ole::Storage.open(@io) {
			|zf|
			assert_raise(Errno::EEXIST, "File exists - dir1") { 
				zf.dir.mkdir("file1") 
			}
			assert_raise(Errno::EEXIST, "File exists - dir1") { 
				zf.dir.mkdir("dir1") 
			}
			assert(!zf.file.exists?("newDir"))
			zf.dir.mkdir("newDir")
			assert(zf.file.directory?("newDir"))
			assert(!zf.file.exists?("newDir2"))
			# FIXME - mode not supported yet
			#zf.dir.mkdir("newDir2", 3485)
			#assert(zf.file.directory?("newDir2"))
			zf.dir.rmdir 'newDir'
			assert(!zf.file.exists?("newDir"))
		}
	end
	
	def test_pwd_chdir_entries
		Ole::Storage.open(@io) {
			|zf|
			assert_equal("/", zf.dir.pwd)

			assert_raise(Errno::ENOENT, "No such file or directory - no such dir") {
				zf.dir.chdir "no such dir"
			}
			
			# changed this to ENOTDIR, which is what touch a; ruby -e "Dir.chdir('a')" gives you.
			assert_raise(Errno::ENOTDIR, "Invalid argument - file1") {
				zf.dir.chdir "file1"
			}

			assert_equal(['.', '..', "dir1", "dir2", "file1"].sort, zf.dir.entries(".").sort)
			zf.dir.chdir "dir1"
			assert_equal("/dir1", zf.dir.pwd)
			zf.dir.chdir('dir11') { assert_equal '/dir1/dir11', zf.dir.pwd }
			assert_equal '/dir1', zf.dir.pwd
			assert_equal(['.', '..', "dir11", "file11", "file12"], zf.dir.entries(".").sort)
			
			zf.dir.chdir "../dir2/dir21"
			assert_equal("/dir2/dir21", zf.dir.pwd)
			assert_equal(['.', '..', "dir221"].sort, zf.dir.entries(".").sort)
		}
	end

	# results here are a bit different from zip/zipfilesystem, as i've chosen to fake '.'
	# and '..'
	def test_foreach
		Ole::Storage.open(@io) {
			|zf|

			blockCalled = false
			assert_raise(Errno::ENOENT, "No such file or directory - noSuchDir") {
				zf.dir.foreach("noSuchDir") { |e| blockCalled = true }
			}
			assert(! blockCalled)

			assert_raise(Errno::ENOTDIR, "Not a directory - file1") {
				zf.dir.foreach("file1") { |e| blockCalled = true }
			}
			assert(! blockCalled)

			entries = []
			zf.dir.foreach(".") { |e| entries << e }
			assert_equal(['.', '..', "dir1", "dir2", "file1"].sort, entries.sort)

			entries = []
			zf.dir.foreach("dir1") { |e| entries << e }
			assert_equal(['.', '..', "dir11", "file11", "file12"], entries.sort)
		}
	end

=begin
	# i've gone for NoMethodError instead.
	def test_chroot
		Ole::Storage.open(@io) {
			|zf|
			assert_raise(NotImplementedError) {
				zf.dir.chroot
			}
		}
	end
=end

	# Globbing not supported yet
	#def test_glob
	#  # test alias []-operator too
	#  fail "implement test"
	#end

	def test_open_new
		Ole::Storage.open(@io) {
			|zf|

			assert_raise(Errno::ENOTDIR, "Not a directory - file1") {
				zf.dir.new("file1")
			}

			assert_raise(Errno::ENOENT, "No such file or directory - noSuchFile") {
				zf.dir.new("noSuchFile")
			}

			d = zf.dir.new(".")
			assert_equal(['.', '..', "file1", "dir1", "dir2"].sort, d.entries.sort)
			d.close

			zf.dir.open("dir1") {
				|d2|
				assert_equal(['.', '..', "dir11", "file11", "file12"].sort, d2.entries.sort)
			}
		}
	end

end

class OleFsDirIteratorTest < Test::Unit::TestCase
	
	FILENAME_ARRAY = [ "f1", "f2", "f3", "f4", "f5", "f6"  ]

	def setup
		@dirIt = Ole::Storage::DirClass::Dir.new('/', FILENAME_ARRAY)
	end

	def test_close
		@dirIt.close
		assert_raise(IOError, "closed directory") {
			@dirIt.each { |e| p e }
		}
		assert_raise(IOError, "closed directory") {
			@dirIt.read
		}
		assert_raise(IOError, "closed directory") {
			@dirIt.rewind
		}
		assert_raise(IOError, "closed directory") {
			@dirIt.seek(0)
		}
		assert_raise(IOError, "closed directory") {
			@dirIt.tell
		}
		
	end

	def test_each 
		# Tested through Enumerable.entries
		assert_equal(FILENAME_ARRAY, @dirIt.entries)
	end

	def test_read
		FILENAME_ARRAY.size.times {
			|i|
			assert_equal(FILENAME_ARRAY[i], @dirIt.read)
		}
	end

	def test_rewind
		@dirIt.read
		@dirIt.read
		assert_equal(FILENAME_ARRAY[2], @dirIt.read)
		@dirIt.rewind
		assert_equal(FILENAME_ARRAY[0], @dirIt.read)
	end
	
	def test_tell_seek
		@dirIt.read
		@dirIt.read
		pos = @dirIt.tell
		valAtPos = @dirIt.read
		@dirIt.read
		@dirIt.seek(pos)
		assert_equal(valAtPos, @dirIt.read)
	end

end

class OleUnicodeTest < Test::Unit::TestCase
	def setup
		@io = StringIO.new ''.dup
	end
	
	def test_unicode
		# in ruby-1.8, encoding is assumed to be UTF-8 (and converted with iconv).
		# in ruby-1.9, UTF-8 should work also, but probably shouldn't be using fixed
		# TO_UTF16 iconv for other encodings.
		resume = "R\xc3\xa9sum\xc3\xa9".dup
		resume.force_encoding Encoding::UTF_8 if resume.respond_to? :encoding
		Ole::Storage.open @io do |ole|
			ole.file.open(resume, 'w') { |f| f.write 'Skills: writing bad unit tests' }
		end
		Ole::Storage.open @io do |ole|
			assert_equal ['.', '..', resume], ole.dir.entries('.')
			# use internal api to verify utf16 encoding
			assert_equal "R\x00\xE9\x00s\x00u\x00m\x00\xE9\x00", ole.root.children[0].name_utf16[0, 6 * 2]
			# FIXME: there is a bug in ruby-1.9 (at least in p376), which makes encoded
			# strings useless as hash keys. identical bytes, identical encodings, identical
			# according to #==, but different hash.
			temp = File.expand_path("/#{resume}").split('/').last
			if resume == temp and resume.hash != temp.hash
				warn 'skipping assertion due to broken String#hash'
			else
				assert_equal 'Skills', ole.file.read(resume).split(': ', 2).first
			end
		end
	end

	def test_write_utf8_string
		programmer = "programa\xC3\xA7\xC3\xA3o ".dup
		programmer.force_encoding Encoding::UTF_8 if programmer.respond_to? :encoding
		Ole::Storage.open @io do |ole|
			ole.file.open '1', 'w' do |writer|
				writer.write(programmer)
				writer.write('ruby')
			end
		end
		Ole::Storage.open @io do |ole|
			ole.file.open '1', 'r' do |reader|
				s = reader.read
				s = s.force_encoding('UTF-8') if s.respond_to?(:encoding)
				assert_equal(programmer + 'ruby', s)
			end
		end
	end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.

