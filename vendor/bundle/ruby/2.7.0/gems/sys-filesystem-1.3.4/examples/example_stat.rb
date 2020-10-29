######################################################################
# example_stat.rb
#
# Example program that demonstrates the FileSystem.stat method.
# Use the 'rake example' task to run this program.
######################################################################
require 'sys/filesystem'
include Sys

p Filesystem::VERSION

stat = Filesystem.stat("/")
puts "Path: " + stat.path
puts "Block size: " + stat.block_size.to_s
puts "Fragment size: " + stat.fragment_size.to_s
puts "Blocks free: " + stat.blocks_free.to_s
puts "Blocks available: " + stat.blocks_available.to_s
puts "Bytes free: " + stat.bytes_free.to_s
puts "Bytes available: " + stat.bytes_available.to_s
puts "Files/Inodes: " + stat.files.to_s
puts "Files/Inodes free: " + stat.files_free.to_s
puts "Files/Inodes available: " + stat.files_available.to_s
puts "File system id: " + stat.filesystem_id.to_s
puts "Base type: " + stat.base_type if stat.base_type
puts "Flags: " + stat.flags.to_s
puts "Name max: " + stat.name_max.to_s
