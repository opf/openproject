# frozen_string_literal: true

# Implements PDF object repository
#
# Copyright August 2009, Brad Ediger.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module PDF
  module Core
    class ObjectStore #:nodoc:
      include Enumerable

      attr_reader :min_version

      def initialize(opts = {})
        @objects = {}
        @identifiers = []

        @info  ||= ref(opts[:info] || {}).identifier
        @root  ||= ref(Type: :Catalog).identifier
        if opts[:print_scaling] == :none
          root.data[:ViewerPreferences] = { PrintScaling: :None }
        end
        if pages.nil?
          root.data[:Pages] = ref(Type: :Pages, Count: 0, Kids: [])
        end
      end

      def ref(data, &block)
        push(size + 1, data, &block)
      end

      def info
        @objects[@info]
      end

      def root
        @objects[@root]
      end

      def pages
        root.data[:Pages]
      end

      def page_count
        pages.data[:Count]
      end

      # Adds the given reference to the store and returns the reference object.
      # If the object provided is not a PDF::Core::Reference, one is created
      # from the arguments provided.
      #
      def push(*args, &block)
        reference =
          if args.first.is_a?(PDF::Core::Reference)
            args.first
          else
            PDF::Core::Reference.new(*args, &block)
          end

        @objects[reference.identifier] = reference
        @identifiers << reference.identifier
        reference
      end

      alias << push

      def each
        @identifiers.each do |id|
          yield @objects[id]
        end
      end

      def [](id)
        @objects[id]
      end

      def size
        @identifiers.size
      end
      alias length size

      # returns the object ID for a particular page in the document. Pages
      # are indexed starting at 1 (not 0!).
      #
      #   object_id_for_page(1)
      #   => 5
      #   object_id_for_page(10)
      #   => 87
      #   object_id_for_page(-11)
      #   => 17
      #
      def object_id_for_page(page)
        page -= 1 if page.positive?
        flat_page_ids = get_page_objects(pages).flatten
        flat_page_ids[page]
      end
    end
  end
end
