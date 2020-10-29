# frozen_string_literal: true

# annotations.rb : Implements low-level annotation support for PDF
#
# Copyright November 2008, Jamis Buck. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
module PDF
  module Core
    # Provides very low-level support for annotations.
    #
    module Annotations #:nodoc:
      # Adds a new annotation (section 8.4 in PDF spec) to the current page.
      # +options+ must be a Hash describing the annotation.
      #
      def annotate(options)
        state.page.dictionary.data[:Annots] ||= []
        options = sanitize_annotation_hash(options)
        state.page.dictionary.data[:Annots] << ref!(options)
        options
      end

      # A convenience method for creating Text annotations. +rect+ must be an
      # array of four numbers, describing the bounds of the annotation.
      # +contents+ should be a string, to be shown when the annotation is
      # activated.
      #
      def text_annotation(rect, contents, options = {})
        options = options.merge(Subtype: :Text, Rect: rect, Contents: contents)
        annotate(options)
      end

      # A convenience method for creating Link annotations. +rect+ must be an
      # array of four numbers, describing the bounds of the annotation. The
      # +options+ hash should include either :Dest (describing the target
      # destination, usually as a string that has been recorded in the
      # document's Dests tree), or :A (describing an action to perform on
      # clicking the link), or :PA (for describing a URL to link to).
      #
      def link_annotation(rect, options = {})
        options = options.merge(Subtype: :Link, Rect: rect)
        annotate(options)
      end

      private

      def sanitize_annotation_hash(options)
        options = options.merge(Type: :Annot)

        if options[:Dest].is_a?(String)
          options[:Dest] = PDF::Core::LiteralString.new(options[:Dest])
        end

        options
      end
    end
  end
end
