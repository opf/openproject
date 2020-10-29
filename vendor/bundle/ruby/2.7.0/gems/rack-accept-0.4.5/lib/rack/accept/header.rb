module Rack::Accept
  # Contains methods that are useful for working with Accept-style HTTP
  # headers. The MediaType, Charset, Encoding, and Language classes all mixin
  # this module.
  module Header
    # Parses the value of an Accept-style request header into a hash of
    # acceptable values and their respective quality factors (qvalues). The
    # +join+ method may be used on the resulting hash to obtain a header
    # string that is the semantic equivalent of the one provided.
    def parse(header)
      qvalues = {}

      header.to_s.split(/,\s*/).each do |part|
        m = /^([^\s,]+?)(?:\s*;\s*q\s*=\s*(\d+(?:\.\d+)?))?$/.match(part)

        if m
          qvalues[m[1].downcase] = normalize_qvalue((m[2] || 1).to_f)
        else
          raise "Invalid header value: #{part.inspect}"
        end
      end

      qvalues
    end
    module_function :parse

    # Returns a string suitable for use as the value of an Accept-style HTTP
    # header from the map of acceptable values to their respective quality
    # factors (qvalues). The +parse+ method may be used on the resulting string
    # to obtain a hash that is the equivalent of the one provided.
    def join(qvalues)
      qvalues.map {|k, v| k + (v == 1 ? '' : ";q=#{v}") }.join(', ')
    end
    module_function :join

    # Parses a media type string into its relevant pieces. The return value
    # will be an array with three values: 1) the content type, 2) the content
    # subtype, and 3) the media type parameters. An empty array is returned if
    # no match can be made.
    def parse_media_type(media_type)
      m = media_type.to_s.match(/^([a-z*]+)\/([a-z0-9*\-.+]+)(?:;([a-z0-9=;]+))?$/)
      m ? [m[1], m[2], m[3] || ''] : []
    end
    module_function :parse_media_type

    # Parses a string of media type range parameters into a hash of parameters
    # to their respective values.
    def parse_range_params(params)
      params.split(';').inject({}) do |m, p|
        k, v = p.split('=', 2)
        m[k] = v if v
        m
      end
    end
    module_function :parse_range_params

    # Converts 1.0 and 0.0 qvalues to 1 and 0 respectively. Used to maintain
    # consistency across qvalue methods.
    def normalize_qvalue(q)
      (q == 1 || q == 0) && q.is_a?(Float) ? q.to_i : q
    end
    module_function :normalize_qvalue

    module PublicInstanceMethods
      # A table of all values of this header to their respective quality
      # factors (qvalues).
      attr_accessor :qvalues

      def initialize(header='')
        @qvalues = parse(header)
      end

      # The name of this header. Should be overridden in classes that mixin
      # this module.
      def name
        ''
      end

      # Returns the quality factor (qvalue) of the given +value+. Should be
      # overridden in classes that mixin this module.
      def qvalue(value)
        1
      end

      # Returns the value of this header as a string.
      def value
        join(@qvalues)
      end

      # Returns an array of all values of this header, in no particular order.
      def values
        @qvalues.keys
      end

      # Determines if the given +value+ is acceptable (does not have a qvalue
      # of 0) according to this header.
      def accept?(value)
        qvalue(value) != 0
      end

      # Returns a copy of the given +values+ array, sorted by quality factor
      # (qvalue). Each element of the returned array is itself an array
      # containing two objects: 1) the value's qvalue and 2) the original
      # value.
      #
      # It is important to note that this sort is a "stable sort". In other
      # words, the order of the original values is preserved so long as the
      # qvalue for each is the same. This expectation can be useful when
      # trying to determine which of a variety of options has the highest
      # qvalue. If the user prefers using one option over another (for any
      # number of reasons), he should put it first in +values+. He may then
      # use the first result with confidence that it is both most acceptable
      # to the client and most convenient for him as well.
      def sort_with_qvalues(values, keep_unacceptables=true)
        qvalues = {}
        values.each do |v|
          q = qvalue(v)
          if q != 0 || keep_unacceptables
            qvalues[q] ||= []
            qvalues[q] << v
          end
        end
        order = qvalues.keys.sort.reverse
        order.inject([]) {|m, q| m.concat(qvalues[q].map {|v| [q, v] }) }
      end

      # Sorts the given +values+ according to the qvalue of each while
      # preserving the original order. See #sort_with_qvalues for more
      # information on exactly how the sort is performed.
      def sort(values, keep_unacceptables=false)
        sort_with_qvalues(values, keep_unacceptables).map {|q, v| v }
      end

      # A shortcut for retrieving the first result of #sort.
      def best_of(values, keep_unacceptables=false)
        sort(values, keep_unacceptables).first
      end

      # Returns a string representation of this header.
      def to_s
        [name, value].join(': ')
      end
    end

    include PublicInstanceMethods
  end
end
