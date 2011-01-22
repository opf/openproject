# =GZip Simple
#
# A simplified interface to the gzip library +zlib+ (from the Ruby Standard Library.)
#
# Author: murphy (mail to murphy rubychan de)
#
# Version: 0.2 (2005.may.28)
#
# ==Documentation
#
# See +GZip+ module and the +String+ extensions.
#
module GZip

  require 'zlib'

  # The default zipping level. 7 zips good and fast.
  DEFAULT_GZIP_LEVEL = 7

  # Unzips the given string +s+.
  #
  # Example:
  #   require 'gzip_simple'
  #   print GZip.gunzip(File.read('adresses.gz'))
  def GZip.gunzip s
    Zlib::Inflate.inflate s
  end

  # Zips the given string +s+.
  #
  # Example:
  #   require 'gzip_simple'
  #   File.open('adresses.gz', 'w') do |file
  #     file.write GZip.gzip('Mum: 0123 456 789', 9)
  #   end
  #
  # If you provide a +level+, you can control how strong
  # the string is compressed:
  # - 0: no compression, only convert to gzip format
  # - 1: compress fast
  # - 7: compress more, but still fast (default)
  # - 8: compress more, slower
  # - 9: compress best, very slow
  def GZip.gzip s, level = DEFAULT_GZIP_LEVEL
    Zlib::Deflate.new(level).deflate s, Zlib::FINISH
  end
end


# String extensions to use the GZip module.
#
# The methods gzip and gunzip provide an even more simple
# interface to the ZLib:
#
#   # create a big string
#   x = 'a' * 1000
#   
#   # zip it
#   x_gz = x.gzip
#   
#   # test the result
#   puts 'Zipped %d bytes to %d bytes.' % [x.size, x_gz.size]
#   #-> Zipped 1000 bytes to 19 bytes.
#   
#   # unzipping works
#   p x_gz.gunzip == x  #-> true
class String
  # Returns the string, unzipped.
  # See GZip.gunzip
  def gunzip
    GZip.gunzip self
  end
  # Replaces the string with its unzipped value.
  # See GZip.gunzip
  def gunzip!
    replace gunzip
  end

  # Returns the string, zipped.
  # +level+ is the gzip compression level, see GZip.gzip.
  def gzip level = GZip::DEFAULT_GZIP_LEVEL
    GZip.gzip self, level
  end
  # Replaces the string with its zipped value.
  # See GZip.gzip.
  def gzip!(*args)
    replace gzip(*args)
  end
end

if $0 == __FILE__
  eval DATA.read, nil, $0, __LINE__+4
end

__END__
#CODE

# Testing / Benchmark
x = 'a' * 1000
x_gz = x.gzip
puts 'Zipped %d bytes to %d bytes.' % [x.size, x_gz.size]  #-> Zipped 1000 bytes to 19 bytes.
p x_gz.gunzip == x  #-> true

require 'benchmark'

INFO = 'packed to %0.3f%%'  # :nodoc:

x = Array.new(100000) { rand(255).chr + 'aaaaaaaaa' + rand(255).chr }.join
Benchmark.bm(10) do |bm|
  for level in 0..9
    bm.report "zip #{level}" do
      $x = x.gzip level
    end
    puts INFO % [100.0 * $x.size / x.size]
  end
  bm.report 'zip' do
    $x = x.gzip
  end
  puts INFO % [100.0 * $x.size / x.size]
  bm.report 'unzip' do
    $x.gunzip
  end
end
