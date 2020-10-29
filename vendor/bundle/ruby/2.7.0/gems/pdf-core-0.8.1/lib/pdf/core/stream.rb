# frozen_string_literal: true

# prawn/core/stream.rb : Implements Stream objects
#
# Copyright February 2013, Alexander Mankuta.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module PDF
  module Core
    class Stream
      attr_reader :filters

      def initialize(io = nil)
        @filtered_stream = ''
        @stream = io
        @filters = FilterList.new
      end

      def <<(io)
        (@stream ||= +'') << io
        @filtered_stream = nil
        self
      end

      def compress!
        unless @filters.names.include? :FlateDecode
          @filtered_stream = nil
          @filters << :FlateDecode
        end
      end

      def compressed?
        @filters.names.include? :FlateDecode
      end

      def empty?
        @stream.nil?
      end

      def filtered_stream
        if @stream
          if @filtered_stream.nil?
            @filtered_stream = @stream.dup

            @filters.each do |(filter_name, params)|
              filter = PDF::Core::Filters.const_get(filter_name)
              if filter
                @filtered_stream = filter.encode @filtered_stream, params
              end
            end
          end

          @filtered_stream
          # XXX Fillter stream
        end
      end

      def length
        @stream.length
      end

      def object
        if filtered_stream
          "stream\n#{filtered_stream}\nendstream\n"
        else
          ''
        end
      end

      def data
        if @stream
          filter_names = @filters.names
          filter_params = @filters.decode_params

          d = {
            Length: filtered_stream.length
          }
          if filter_names.any?
            d[:Filter] = filter_names
          end
          if filter_params.any? { |f| !f.nil? }
            d[:DecodeParms] = filter_params
          end

          d
        else
          {}
        end
      end

      def inspect
        "#<#{self.class.name}:0x#{format '%014x', object_id} "\
          "@stream=#{@stream.inspect}, @filters=#{@filters.inspect}>"
      end
    end
  end
end
