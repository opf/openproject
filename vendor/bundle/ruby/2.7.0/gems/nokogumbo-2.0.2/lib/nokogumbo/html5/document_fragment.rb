require 'nokogiri'

module Nokogiri
  module HTML5
    class DocumentFragment < Nokogiri::HTML::DocumentFragment
      attr_accessor :document
      attr_accessor :errors

      # Create a document fragment.
      def initialize(doc, tags = nil, ctx = nil, options = {})
        self.document = doc
        self.errors = []
        return self unless tags

        max_errors = options[:max_errors] || Nokogumbo::DEFAULT_MAX_ERRORS
        max_depth = options[:max_tree_depth] || Nokogumbo::DEFAULT_MAX_TREE_DEPTH
        tags = Nokogiri::HTML5.read_and_encode(tags, nil)
        Nokogumbo.fragment(self, tags, ctx, max_errors, max_depth)
      end

      def serialize(options = {}, &block)
        # Bypass XML::Document.serialize which doesn't support options even
        # though XML::Node.serialize does!
        XML::Node.instance_method(:serialize).bind(self).call(options, &block)
      end

      # Parse a document fragment from +tags+, returning a Nodeset.
      def self.parse(tags, encoding = nil, options = {})
        doc = HTML5::Document.new
        tags = HTML5.read_and_encode(tags, encoding)
        doc.encoding = 'UTF-8'
        new(doc, tags, nil, options)
      end

      def extract_params params # :nodoc:
        handler = params.find do |param|
          ![Hash, String, Symbol].include?(param.class)
        end
        params -= [handler] if handler

        hashes = []
        while Hash === params.last || params.last.nil?
          hashes << params.pop
          break if params.empty?
        end
        ns, binds = hashes.reverse

        ns ||=
          begin
            ns = Hash.new
            children.each { |child| ns.merge!(child.namespaces) }
            ns
          end

        [params, handler, ns, binds]
      end

    end
  end
end
# vim: set shiftwidth=2 softtabstop=2 tabstop=8 expandtab:
