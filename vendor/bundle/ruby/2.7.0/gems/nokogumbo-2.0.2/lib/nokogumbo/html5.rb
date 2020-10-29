require 'nokogumbo/html5/document'
require 'nokogumbo/html5/document_fragment'
require 'nokogumbo/html5/node'

module Nokogiri
  # Parse an HTML 5 document. Convenience method for Nokogiri::HTML5::Document.parse
  def self.HTML5(string_or_io, url = nil, encoding = nil, **options, &block)
    Nokogiri::HTML5::Document.parse(string_or_io, url, encoding, **options, &block)
  end

  module HTML5
    # HTML uses the XHTML namespace.
    HTML_NAMESPACE = 'http://www.w3.org/1999/xhtml'.freeze
    MATHML_NAMESPACE = 'http://www.w3.org/1998/Math/MathML'.freeze
    SVG_NAMESPACE = 'http://www.w3.org/2000/svg'.freeze
    XLINK_NAMESPACE = 'http://www.w3.org/1999/xlink'.freeze
    XML_NAMESPACE = 'http://www.w3.org/XML/1998/namespace'.freeze
    XMLNS_NAMESPACE = 'http://www.w3.org/2000/xmlns/'.freeze

    # Parse an HTML 5 document. Convenience method for Nokogiri::HTML5::Document.parse
    def self.parse(string, url = nil, encoding = nil, **options, &block)
      Document.parse(string, url, encoding, options, &block)
    end

    # Parse a fragment from +string+. Convenience method for
    # Nokogiri::HTML5::DocumentFragment.parse.
    def self.fragment(string, encoding = nil, **options)
      DocumentFragment.parse(string, encoding, options)
    end

    # Fetch and parse a HTML document from the web, following redirects,
    # handling https, and determining the character encoding using HTML5
    # rules.  +uri+ may be a +String+ or a +URI+.  +options+ contains
    # http headers and special options.  Everything which is not a
    # special option is considered a header.  Special options include:
    #  * :follow_limit => number of redirects which are followed
    #  * :basic_auth => [username, password]
    def self.get(uri, options={})
      headers = options.clone
      headers = {:follow_limit => headers} if Numeric === headers # deprecated
      limit=headers[:follow_limit] ? headers.delete(:follow_limit).to_i : 10

      require 'net/http'
      uri = URI(uri) unless URI === uri

      http = Net::HTTP.new(uri.host, uri.port)

      # TLS / SSL support
      http.use_ssl = true if uri.scheme == 'https'

      # Pass through Net::HTTP override values, which currently include:
      #   :ca_file, :ca_path, :cert, :cert_store, :ciphers,
      #   :close_on_empty_response, :continue_timeout, :key, :open_timeout,
      #   :read_timeout, :ssl_timeout, :ssl_version, :use_ssl,
      #   :verify_callback, :verify_depth, :verify_mode
      options.each do |key, value|
        http.send "#{key}=", headers.delete(key) if http.respond_to? "#{key}="
      end

      request = Net::HTTP::Get.new(uri.request_uri)

      # basic authentication
      auth = headers.delete(:basic_auth)
      auth ||= [uri.user, uri.password] if uri.user && uri.password
      request.basic_auth auth.first, auth.last if auth

      # remaining options are treated as headers
      headers.each {|key, value| request[key.to_s] = value.to_s}

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        doc = parse(reencode(response.body, response['content-type']), options)
        doc.instance_variable_set('@response', response)
        doc.class.send(:attr_reader, :response)
        doc
      when Net::HTTPRedirection
        response.value if limit <= 1
        location = URI.join(uri, response['location'])
        get(location, options.merge(:follow_limit => limit-1))
      else
        response.value
      end
    end

    private

    def self.read_and_encode(string, encoding)
      # Read the string with the given encoding.
      if string.respond_to?(:read)
        if encoding.nil?
          string = string.read
        else
        string = string.read(encoding: encoding)
        end
      else
        # Otherwise the string has the given encoding.
        if encoding && string.respond_to?(:force_encoding)
          string = string.dup
          string.force_encoding(encoding)
        end
      end

      # convert to UTF-8 (Ruby 1.9+)
      if string.respond_to?(:encoding) && string.encoding != Encoding::UTF_8
        string = reencode(string.dup)
      end
      string
    end

    # Charset sniffing is a complex and controversial topic that understandably
    # isn't done _by default_ by the Ruby Net::HTTP library.  This being said,
    # it is a very real problem for consumers of HTML as the default for HTML
    # is iso-8859-1, most "good" producers use utf-8, and the Gumbo parser
    # *only* supports utf-8.
    #
    # Accordingly, Nokogiri::HTML::Document.parse provides limited encoding
    # detection.  Following this lead, Nokogiri::HTML5 attempts to do likewise,
    # while attempting to more closely follow the HTML5 standard.
    #
    # http://bugs.ruby-lang.org/issues/2567
    # http://www.w3.org/TR/html5/syntax.html#determining-the-character-encoding
    #
    def self.reencode(body, content_type=nil)
      return body unless body.respond_to? :encoding

      if body.encoding == Encoding::ASCII_8BIT
        encoding = nil

        # look for a Byte Order Mark (BOM)
        if body[0..1] == "\xFE\xFF"
          encoding = 'utf-16be'
        elsif body[0..1] == "\xFF\xFE"
          encoding = 'utf-16le'
        elsif body[0..2] == "\xEF\xBB\xBF"
          encoding = 'utf-8'
        end

        # look for a charset in a content-encoding header
        if content_type
          encoding ||= content_type[/charset=["']?(.*?)($|["';\s])/i, 1]
        end

        # look for a charset in a meta tag in the first 1024 bytes
        if not encoding
          data = body[0..1023].gsub(/<!--.*?(-->|\Z)/m, '')
          data.scan(/<meta.*?>/m).each do |meta|
            encoding ||= meta[/charset=["']?([^>]*?)($|["'\s>])/im, 1]
          end
        end

        # if all else fails, default to the official default encoding for HTML
        encoding ||= Encoding::ISO_8859_1

        # change the encoding to match the detected or inferred encoding
        begin
          body.force_encoding(encoding)
        rescue ArgumentError
          body.force_encoding(Encoding::ISO_8859_1)
        end
      end

      body.encode(Encoding::UTF_8)
    end

    def self.serialize_node_internal(current_node, io, encoding, options)
      case current_node.type
      when XML::Node::ELEMENT_NODE
        ns = current_node.namespace
        ns_uri = ns.nil? ? nil : ns.href
        # XXX(sfc): attach namespaces to all nodes, even html?
        if ns_uri.nil? || ns_uri == HTML_NAMESPACE || ns_uri == MATHML_NAMESPACE || ns_uri == SVG_NAMESPACE
          tagname = current_node.name
        else
          tagname = "#{ns.prefix}:#{current_node.name}"
        end
        io << '<' << tagname
        current_node.attribute_nodes.each do |attr|
          attr_ns = attr.namespace
          if attr_ns.nil?
            attr_name = attr.name
          else
            ns_uri = attr_ns.href
            if ns_uri == XML_NAMESPACE
              attr_name = 'xml:' + attr.name.sub(/^[^:]*:/, '')
            elsif ns_uri == XMLNS_NAMESPACE && attr.name.sub(/^[^:]*:/, '') == 'xmlns'
              attr_name = 'xmlns'
            elsif ns_uri == XMLNS_NAMESPACE
              attr_name = 'xmlns:' + attr.name.sub(/^[^:]*:/, '')
            elsif ns_uri == XLINK_NAMESPACE
              attr_name = 'xlink:' + attr.name.sub(/^[^:]*:/, '')
            else
              attr_name = "#{attr_ns.prefix}:#{attr.name}"
            end
          end
          io << ' ' << attr_name << '="' << escape_text(attr.content, encoding, true) << '"'
        end
        io << '>'
        if !%w[area base basefont bgsound br col embed frame hr img input keygen
               link meta param source track wbr].include?(current_node.name)
          io << "\n" if options[:preserve_newline] && prepend_newline?(current_node)
          current_node.children.each do |child|
            # XXX(sfc): Templates handled specially?
            serialize_node_internal(child, io, encoding, options)
          end
          io << '</' << tagname << '>'
        end
      when XML::Node::TEXT_NODE
        parent = current_node.parent
        if parent.element? && %w[style script xmp iframe noembed noframes plaintext noscript].include?(parent.name)
          io << current_node.content
        else
          io << escape_text(current_node.content, encoding, false)
        end
      when XML::Node::CDATA_SECTION_NODE
        io << '<![CDATA[' << current_node.content << ']]>'
      when XML::Node::COMMENT_NODE
        io << '<!--' << current_node.content << '-->'
      when XML::Node::PI_NODE
        io << '<?' << current_node.content << '>'
      when XML::Node::DOCUMENT_TYPE_NODE, XML::Node::DTD_NODE
          io << '<!DOCTYPE ' << current_node.name << '>'
      when XML::Node::HTML_DOCUMENT_NODE, XML::Node::DOCUMENT_FRAG_NODE
        current_node.children.each do |child|
          serialize_node_internal(child, io, encoding, options)
        end
      else
        raise "Unexpected node '#{current_node.name}' of type #{current_node.type}"
      end
    end

    def self.escape_text(text, encoding, attribute_mode)
      if attribute_mode
        text = text.gsub(/[&\u00a0"]/,
                           '&' => '&amp;', "\u00a0" => '&nbsp;', '"' => '&quot;')
      else
        text = text.gsub(/[&\u00a0<>]/,
                           '&' => '&amp;', "\u00a0" => '&nbsp;',  '<' => '&lt;', '>' => '&gt;')
      end
      # Not part of the standard
      text.encode(encoding, fallback: lambda { |c| "&\#x#{c.ord.to_s(16)};" })
    end

    def self.prepend_newline?(node)
      return false unless %w[pre textarea listing].include?(node.name) && !node.children.empty?
      first_child = node.children[0]
      first_child.text? && first_child.content.start_with?("\n")
    end
  end
end
