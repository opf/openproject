require 'securerandom'

module Icalendar

  class Component
    include HasProperties
    include HasComponents

    attr_reader :name
    attr_reader :ical_name
    attr_accessor :parent

    def self.parse(source)
      parser = Parser.new(source)
      parser.component_class = self
      parser.parse
    end

    def initialize(name, ical_name = nil)
      @name = name
      @ical_name = ical_name || "V#{name.upcase}"
      super()
    end

    def new_uid
      SecureRandom.uuid
    end

    def to_ical
      [
        "BEGIN:#{ical_name}",
        ical_properties,
        ical_components,
        "END:#{ical_name}\r\n"
      ].compact.join "\r\n"
    end

    private

    def ical_properties
      (self.class.properties + custom_properties.keys).map do |prop|
        value = property prop
        unless value.nil?
          if value.is_a? ::Array
            value.map do |part|
              ical_fold "#{ical_prop_name prop}#{part.to_ical self.class.default_property_types[prop]}"
            end.join "\r\n" unless value.empty?
          else
            ical_fold "#{ical_prop_name prop}#{value.to_ical self.class.default_property_types[prop]}"
          end
        end
      end.compact.join "\r\n"
    end

    def ical_prop_name(prop_name)
      prop_name.gsub(/\Aip_/, '').gsub('_', '-').upcase
    end

    def ical_fold(long_line, indent = "\x20")
      # rfc2445 says:
      # Lines of text SHOULD NOT be longer than 75 octets, excluding the line
      # break. Long content lines SHOULD be split into a multiple line
      # representations using a line "folding" technique. That is, a long
      # line can be split between any two characters by inserting a CRLF
      # immediately followed by a single linear white space character (i.e.,
      # SPACE, US-ASCII decimal 32 or HTAB, US-ASCII decimal 9). Any sequence
      # of CRLF followed immediately by a single linear white space character
      # is ignored (i.e., removed) when processing the content type.
      #
      # Note the useage of "octets" and "characters": a line should not be longer
      # than 75 octets, but you need to split between characters, not bytes.
      # This is challanging with Unicode composing accents, for example.

      return long_line if long_line.bytesize <= Icalendar::MAX_LINE_LENGTH

      chars = long_line.scan(/\P{M}\p{M}*/u) # split in graphenes
      folded = ['']
      bytes = 0
      while chars.count > 0
        c = chars.shift
        cb = c.bytes.count
        if bytes + cb > Icalendar::MAX_LINE_LENGTH
          # Split here
          folded.push "#{indent}"
          bytes = indent.bytes.count
        end
        folded[-1] += c
        bytes += cb
      end

      folded.join("\r\n")
    end

    def ical_components
      collection = []
      (self.class.components + custom_components.keys).each do |component_name|
        components = send component_name
        components.each do |component|
          collection << component.to_ical
        end
      end
      collection.empty? ? nil : collection.join.chomp("\r\n")
    end
  end

end
