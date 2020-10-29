module OkComputer
  # Check if a file system directory exists and has the correct access. This
  # may prove useful if the application relies on a mounted shared file system.
  class DirectoryCheck < Check
    ConnectionFailed = Class.new(StandardError)

    attr_accessor :directory, :writable

    # Public: Initialize a new directory check.
    #
    # directory - the path of the directory.  Can be relative or absolute.
    # writable - true if directory should allow writes;  false if not.
    def initialize(directory, writable = true)
      raise ArgumentError if directory.blank?

      self.directory = directory
      self.writable = writable
    end

    # Public: Return the status of the directory check
    def check
      stat = File.stat(directory) if File.exist?(directory)
      if stat
        if stat.directory?
          if !stat.readable?
            mark_message "Directory '#{directory}' is not readable."
            mark_failure
          elsif writable && !stat.writable?
            mark_message "Directory '#{directory}' is not writable."
            mark_failure
          elsif !writable && stat.writable?
            mark_message "Directory '#{directory}' is writable (undesired)."
            mark_failure
          else
            mark_message "Directory '#{directory}' is #{writable ? nil : 'NOT '}writable (as expected)."
          end
        else
          mark_message "'#{directory}' is not a directory."
          mark_failure
        end
      else
        mark_message "Directory '#{directory}' does not exist."
        mark_failure
      end
    end
  end
end
