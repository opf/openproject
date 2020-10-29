######################################################################
# example_mount.rb
#
# Example program that demonstrates the Filesystem.mount method.
# Simulates the `mount` command in ruby
######################################################################
require 'optparse'

options = {:mount_options => []}
OptionParser.new do |opts|
  opts.banner = "Usage: #$0 [-o options] [-t external_type] special node"

  opts.on("-o=OPTIONS",       "Set one or many mount options (comma delimited)") do |opts|
    options[:mount_options] += opts.split(',')
  end

  opts.on("-r",               "Set readonly flag") do
    options[:read_only] = true
  end

  opts.on("-t=EXTERNAL_TYPE", "Set the filesystem type") do |type|
    options[:type] = type
  end

  opts.on("-v", "--version",  "Display version") do
    options[:version] = true
  end

  opts.separator ""
  opts.separator "Examples:"
  opts.separator ""
  opts.separator "  NFS: ruby #$0 -t nfs 192.168.0.10:/var/nfs /mnt/nfs"
  opts.separator ""
  opts.separator "  SMB: ruby #$0 -t cifs //192.168.0.10/share /mnt/smb/ -o username=user,password=pass,domain=example.com"
  opts.separator ""
end.parse!

require 'sys/filesystem'
include Sys

if options[:version]
  puts "Sys::Filesystem::VERSION: #{Filesystem::VERSION}"
  exit
end

def die msg
  warn msg
  exit 1
end

mount_flags = options[:read_only] ? Filesystem::MNT_RDONLY : 0
mnt_path, mnt_point = ARGV[0,2]

case options[:type]
when "cifs"
  # keep mnt_path as is
when "nfs"
  host, path, err = mnt_path.split(":")

  die "ERROR:  mount_pount '#{mnt_path}' should only contain 1 ':'" if err

  mnt_path                 = ":#{path}"
  options[:mount_options] << "addr=#{host}"
else
  die "ERROR:  unknown mount type!"
end

Filesystem.mount mnt_path,
                 mnt_point,
                 options[:type],
                 mount_flags,
                 options[:mount_options].join(',')
