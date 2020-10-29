#!/usr/bin/env ruby
# -*- encoding: binary -*-
# Reads from stdin and outputs the SHA1 hex digest of the input

require 'digest/sha1'
$stdout.sync = $stderr.sync = true
$stdout.binmode
$stdin.binmode
bs = 16384
digest = Digest::SHA1.new
if buf = $stdin.read(bs)
  begin
    digest.update(buf)
  end while $stdin.read(bs, buf)
end

$stdout.syswrite("#{digest.hexdigest}\n")
