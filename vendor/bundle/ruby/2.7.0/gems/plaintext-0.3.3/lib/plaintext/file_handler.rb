# frozen_string_literal: true

module Plaintext
  class FileHandler
    def accept?(content_type)
      if @content_type
        content_type == @content_type
      elsif @content_types
        @content_types.include? content_type
      else
        false
      end
    end

    # use `#set(max_size: 1.megabyte)` to give an upper limit of data to be read.
    #
    # By default, all data (whole file / command output) will be read which can
    # be a problem with huge text files (eg SQL dumps)
    def set(args = {})
      options.update args
      self
    end

    private

    # maximum number of bytes to read from external command output or text
    # files
    def max_size
      options[:max_size]
    end

    def options
      @options ||= {}
    end

  end
end
