# frozen_string_literal: true

require 'stringio'

module TTFunk
  class UnresolvedPlaceholderError < StandardError
  end

  class DuplicatePlaceholderError < StandardError
  end

  class EncodedString
    def initialize
      yield self if block_given?
    end

    def <<(obj)
      case obj
      when String
        io << obj
      when Placeholder
        add_placeholder(obj)
        io << "\0" * obj.length
      when self.class
        # adjust placeholders to be relative to the entire encoded string
        obj.placeholders.each_pair do |_, placeholder|
          add_placeholder(placeholder.dup, placeholder.position + io.length)
        end

        self << obj.unresolved_string
      end

      self
    end

    def align!(width = 4)
      if length % width > 0
        self << "\0" * (width - length % width)
      end

      self
    end

    def length
      io.length
    end

    def string
      unless placeholders.empty?
        raise UnresolvedPlaceholderError, 'string contains '\
          "#{placeholders.size} unresolved placeholder(s)"
      end

      io.string
    end

    def bytes
      string.bytes
    end

    def unresolved_string
      io.string
    end

    def resolve_placeholder(name, value)
      last_pos = io.pos

      if (placeholder = placeholders[name])
        io.seek(placeholder.position)
        io.write(value[0..placeholder.length])
        placeholders.delete(name)
      end
    ensure
      io.seek(last_pos)
    end

    def placeholders
      @placeholders ||= {}
    end

    private

    def add_placeholder(new_placeholder, pos = io.pos)
      if placeholders.include?(new_placeholder.name)
        raise DuplicatePlaceholderError,
          "placeholder #{new_placeholder.name} already exists"
      end

      new_placeholder.position = pos
      placeholders[new_placeholder.name] = new_placeholder
    end

    def io
      @io ||= StringIO.new(''.b).binmode
    end
  end
end
