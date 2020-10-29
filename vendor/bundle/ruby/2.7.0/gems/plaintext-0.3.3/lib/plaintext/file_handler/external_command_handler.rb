# frozen_string_literal: true

require 'pathname'

module Plaintext
  class ExternalCommandHandler < FileHandler
    # TODO: Extract this to a proper module
    # Executes the given command through IO.popen and yields an IO object
    # representing STDIN / STDOUT
    #
    # Due to how popen works the command will be executed directly without
    # involving the shell if cmd is an array.
    require 'fileutils'

    FILE_PLACEHOLDER = '__FILE__'.freeze
    DEFAULT_STREAM_ENCODING = 'ASCII-8BIT'.freeze

    def shellout(cmd, options = {}, &block)
      mode = "r+"
      IO.popen(cmd, mode) do |io|
        set_stream_encoding(io)
        io.close_write unless options[:write_stdin]
        block.call(io) if block_given?
      end
    end

    def text(file, options = {})
      cmd = @command.dup
      cmd[cmd.index(FILE_PLACEHOLDER)] = Pathname(file).to_s
      shellout(cmd) { |io| read io, options[:max_size] }.to_s
    end


    def accept?(content_type)
      super and available?
    end

    def available?
      @command.present? and File.executable?(@command[0])
    end

    def self.available?
      new.available?
    end

    protected

    def utf8_stream?
      false
    end

    private

    def set_stream_encoding(io)
      return unless io.respond_to?(:set_encoding)

      if utf8_stream?
        io.set_encoding('UTF-8'.freeze)
      else
        io.set_encoding(DEFAULT_STREAM_ENCODING)
      end
    end

    def read(io, max_size = nil)
      piece = io.read(max_size)

      if utf8_stream?
        piece
      else
        Plaintext::CodesetUtil.to_utf8 piece, DEFAULT_STREAM_ENCODING
      end
    end
  end
end
