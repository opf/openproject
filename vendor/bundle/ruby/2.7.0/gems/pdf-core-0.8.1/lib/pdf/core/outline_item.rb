# frozen_string_literal: true

module PDF
  module Core
    class OutlineItem #:nodoc:
      attr_accessor :count, :first, :last, :next, :prev, :parent, :title, :dest,
        :closed

      def initialize(title, parent, options)
        @closed = options[:closed]
        @title = title
        @parent = parent
        @count = 0
      end

      def to_hash
        hash = {
          Title: title,
          Parent: parent,
          Count: closed ? -count : count
        }
        [
          { First: first }, { Last: last }, { Next: defined?(@next) && @next },
          { Prev: prev }, { Dest: dest }
        ].each do |h|
          unless h.values.first.nil?
            hash.merge!(h)
          end
        end
        hash
      end
    end
  end
end
