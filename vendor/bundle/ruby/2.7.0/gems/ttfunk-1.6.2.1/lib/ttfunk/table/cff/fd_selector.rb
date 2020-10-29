# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class FdSelector < TTFunk::SubTable
        include Enumerable

        ARRAY_FORMAT = 0
        RANGE_FORMAT = 3

        RANGE_ENTRY_SIZE = 3
        ARRAY_ENTRY_SIZE = 1

        attr_reader :top_dict, :count, :entries, :n_glyphs

        def initialize(top_dict, file, offset, length = nil)
          @top_dict = top_dict
          super(file, offset, length)
        end

        def [](glyph_id)
          case format_sym
          when :array_format
            entries[glyph_id]

          when :range_format
            if (entry = range_cache[glyph_id])
              return entry
            end

            range, entry = entries.bsearch do |rng, _|
              if rng.cover?(glyph_id)
                0
              elsif glyph_id < rng.first
                -1
              else
                1
              end
            end

            range.each { |i| range_cache[i] = entry }
            entry
          end
        end

        def each
          return to_enum(__method__) unless block_given?

          count.times { |i| yield self[i] }
        end

        # mapping is new -> old glyph ids
        def encode(mapping)
          # get list of [new_gid, fd_index] pairs
          new_indices = mapping.keys.sort.map do |new_gid|
            [new_gid, self[mapping[new_gid]]]
          end

          ranges = rangify_gids(new_indices)
          total_range_size = ranges.size * RANGE_ENTRY_SIZE
          total_array_size = new_indices.size * ARRAY_ENTRY_SIZE

          ''.b.tap do |result|
            if total_array_size <= total_range_size
              result << [ARRAY_FORMAT].pack('C')
              result << new_indices.map(&:last).pack('C*')
            else
              result << [RANGE_FORMAT, ranges.size].pack('Cn')
              ranges.each { |range| result << range.pack('nC') }

              # "A sentinel GID follows the last range element and serves to
              # delimit the last range in the array. (The sentinel GID is set
              # equal to the number of glyphs in the font. That is, its value
              # is 1 greater than the last GID in the font)."
              result << [new_indices.size].pack('n')
            end
          end
        end

        private

        def range_cache
          @range_cache ||= {}
        end

        # values is an array of [new_gid, fd_index] pairs
        def rangify_gids(values)
          start_gid = 0

          [].tap do |ranges|
            values.each_cons(2) do |(_, first_idx), (sec_gid, sec_idx)|
              if first_idx != sec_idx
                ranges << [start_gid, first_idx]
                start_gid = sec_gid
              end
            end

            ranges << [start_gid, values.last[1]]
          end
        end

        def parse!
          @format = read(1, 'C').first
          @length = 1

          case format_sym
          when :array_format
            @n_glyphs = top_dict.charstrings_index.count
            data = io.read(n_glyphs)
            @length += data.bytesize
            @count = data.bytesize
            @entries = data.bytes

          when :range_format
            # +2 for sentinel GID, +2 for num_ranges
            num_ranges = read(2, 'n').first
            @length += (num_ranges * RANGE_ENTRY_SIZE) + 4

            ranges = Array.new(num_ranges) { read(RANGE_ENTRY_SIZE, 'nC') }

            @entries = ranges.each_cons(2).map do |first, second|
              first_gid, fd_index = first
              second_gid, = second
              [(first_gid...second_gid), fd_index]
            end

            # read the sentinel GID, otherwise known as the number of glyphs
            # in the font
            @n_glyphs = read(2, 'n').first

            last_start_gid, last_fd_index = ranges.last
            @entries << [(last_start_gid...(n_glyphs + 1)), last_fd_index]

            @count = entries.inject(0) { |sum, entry| sum + entry.first.size }
          end
        end

        def format_sym
          case @format
          when ARRAY_FORMAT then :array_format
          when RANGE_FORMAT then :range_format
          else
            raise "unsupported fd select format '#{@format}'"
          end
        end
      end
    end
  end
end
