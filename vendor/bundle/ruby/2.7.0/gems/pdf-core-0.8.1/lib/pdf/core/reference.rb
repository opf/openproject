# frozen_string_literal: true

# reference.rb : Implementation of PDF indirect objects
#
# Copyright April 2008, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'pdf/core/utils'

module PDF
  module Core
    class Reference #:nodoc:
      attr_accessor :gen, :data, :offset, :stream, :identifier

      def initialize(id, data)
        @identifier = id
        @gen        = 0
        @data       = data
        @stream     = Stream.new
      end

      def object
        output = +"#{@identifier} #{gen} obj\n"
        if @stream.empty?
          output << PDF::Core.pdf_object(data) << "\n"
        else
          output << PDF::Core.pdf_object(data.merge(@stream.data)) <<
            "\n" << @stream.object
        end

        output << "endobj\n"
      end

      def <<(io)
        unless @data.is_a?(::Hash)
          raise 'Cannot attach stream to non-dictionary object'
        end
        (@stream ||= Stream.new) << io
      end

      def to_s
        "#{@identifier} #{gen} R"
      end

      # Creates a deep copy of this ref. If +share+ is provided, shares the
      # given dictionary entries between the old ref and the new.
      #
      def deep_copy(share = [])
        r = dup

        case r.data
        when ::Hash
          # Copy each entry not in +share+.
          (r.data.keys - share).each do |k|
            r.data[k] = Utils.deep_clone(r.data[k])
          end
        when PDF::Core::NameTree::Node
          r.data = r.data.deep_copy
        else
          r.data = Utils.deep_clone(r.data)
        end

        r.stream = Utils.deep_clone(r.stream)
        r
      end

      # Replaces the data and stream with that of other_ref.
      def replace(other_ref)
        @data   = other_ref.data
        @stream = other_ref.stream
      end
    end
  end
end
