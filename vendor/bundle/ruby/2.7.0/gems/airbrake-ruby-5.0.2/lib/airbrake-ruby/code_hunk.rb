module Airbrake
  # Represents a small hunk of code consisting of a base line and a couple lines
  # around it
  # @api private
  class CodeHunk
    # @return [Integer] the maximum length of a line
    MAX_LINE_LEN = 200

    # @return [Integer] how many lines should be read around the base line
    NLINES = 2

    include Loggable

    # @param [String] file The file to read
    # @param [Integer] line The base line in the file
    # @return [Hash{Integer=>String}, nil] lines of code around the base line
    def get(file, line)
      return unless File.exist?(file)
      return unless line

      lines = get_lines(file, [line - NLINES, 1].max, line + NLINES) || {}
      return { 1 => '' } if lines.empty?

      lines
    end

    private

    def get_from_cache(file)
      Airbrake::FileCache[file] ||= File.foreach(file)
    rescue StandardError => ex
      logger.error(
        "#{self.class.name}: can't read code hunk for #{file}: #{ex}",
      )
      nil
    end

    def get_lines(file, start_line, end_line)
      return unless (cached_file = get_from_cache(file))

      lines = {}
      cached_file.with_index(1) do |l, i|
        next if i < start_line
        break if i > end_line

        lines[i] = l[0...MAX_LINE_LEN].rstrip
      end
      lines
    end
  end
end
