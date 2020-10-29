require 'fileutils'

module WithAdvisoryLock
  class Flock < Base
    def filename
      @filename ||= begin
        safe = lock_str.to_s.gsub(/[^a-z0-9]/i, '')
        fn = ".lock-#{safe}-#{stable_hashcode(lock_str)}"
        # Let the user specify a directory besides CWD.
        ENV['FLOCK_DIR'] ? File.expand_path(fn, ENV['FLOCK_DIR']) : fn
      end
    end

    def file_io
      @file_io ||= begin
        FileUtils.touch(filename)
        File.open(filename, 'r+')
      end
    end

    def try_lock
      if transaction
        raise ArgumentError, 'transaction level locks are not supported on SQLite'
      end
      0 == file_io.flock((shared ? File::LOCK_SH : File::LOCK_EX) | File::LOCK_NB)
    end

    def release_lock
      0 == file_io.flock(File::LOCK_UN)
    end
  end
end
