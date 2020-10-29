# Multi-Processing-safe monkey patch for Logger
#
# This monkey patch fixes the case where "preload_app true" is used and
# the application spawns a background thread upon being loaded.
#
# This removes all lock from the Logger code and solely relies on the
# underlying filesystem to handle write(2) system calls atomically when
# O_APPEND is used.  This is safe in the presence of both multiple
# threads (native or green) and multiple processes when writing to
# a filesystem with POSIX O_APPEND semantics.
#
# It should be noted that the original locking on Logger could _never_ be
# considered reliable on non-POSIX filesystems with multiple processes,
# either, so nothing is lost in that case.

require 'logger'
class Logger::LogDevice
  def write(message)
    @dev.syswrite(message)
  end

  def close
    @dev.close
  end
end
