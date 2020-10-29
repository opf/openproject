module OkComputer
  # Display app version SHA
  #
  # * If `ENV["SHA"]` is set, uses that value.
  # * Otherwise, checks for Capistrano's REVISION file in the app root.
  # * Failing these, the check fails
  class AppVersionCheck < Check
    # Public: Return the application version
    def check
      mark_message "Version: #{version}"
    rescue UnknownRevision
      mark_failure
      mark_message "Unable to determine version"
    end

    # Public: The application version
    #
    # Returns a String
    def version
      version_from_env || version_from_file || raise(UnknownRevision)
    end

    private

    # Private: Version stored in environment variable
    def version_from_env
      ENV["SHA"]
    end

    # Private: Version stored in Capistrano revision file
    def version_from_file
      if File.exist?(Rails.root.join("REVISION"))
        File.read(Rails.root.join("REVISION")).chomp
      end
    end

    UnknownRevision = Class.new(StandardError)
  end
end
