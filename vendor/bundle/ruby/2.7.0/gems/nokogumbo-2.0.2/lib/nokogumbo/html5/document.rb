module Nokogiri
  module HTML5
    class Document < Nokogiri::HTML::Document
      def self.parse(string_or_io, url = nil, encoding = nil, **options, &block)
        yield options if block_given?
	string_or_io = '' unless string_or_io

        if string_or_io.respond_to?(:encoding) && string_or_io.encoding.name != 'ASCII-8BIT'
          encoding ||= string_or_io.encoding.name
        end

        if string_or_io.respond_to?(:read) && string_or_io.respond_to?(:path)
          url ||= string_or_io.path
        end
        do_parse(string_or_io, url, encoding, options)
      end

      def self.read_io(io, url = nil, encoding = nil, **options)
        raise ArgumentError.new("io object doesn't respond to :read") unless io.respond_to?(:read)
        do_parse(io, url, encoding, options)
      end

      def self.read_memory(string, url = nil, encoding = nil, **options)
        do_parse(string.to_s, url, encoding, options)
      end

      def fragment(tags = nil)
        DocumentFragment.new(self, tags, self.root)
      end

      def to_xml(options = {}, &block)
        # Bypass XML::Document#to_xml which doesn't add
        # XML::Node::SaveOptions::AS_XML like XML::Node#to_xml does.
        XML::Node.instance_method(:to_xml).bind(self).call(options, &block)
      end

      private
      def self.do_parse(string_or_io, url, encoding, options)
        string = HTML5.read_and_encode(string_or_io, encoding)
        max_errors = options[:max_errors] || options[:max_parse_errors] || Nokogumbo::DEFAULT_MAX_ERRORS
        max_depth = options[:max_tree_depth] || Nokogumbo::DEFAULT_MAX_TREE_DEPTH
        doc = Nokogumbo.parse(string.to_s, url, max_errors, max_depth)
        doc.encoding = 'UTF-8'
        doc
      end
    end
  end
end
