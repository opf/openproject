# frozen_string_literal: true

# internals.rb : Implements document internals for Prawn
#
# Copyright August 2008, Gregory Brown. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'forwardable'

module Prawn
  class Document
    # This module exposes a few low-level PDF features for those who want
    # to extend Prawn's core functionality.  If you are not comfortable with
    # low level PDF functionality as defined by Adobe's specification, chances
    # are you won't need anything you find here.
    #
    # @private
    module Internals
      extend Forwardable

      # These methods are not officially part of Prawn's public API,
      # but they are used in documentation and possibly in extensions.
      # Perhaps they will become part of the extension API?
      # Anyway, for now it's not clear what we should do w. them.
      delegate %i[
        graphic_state
        on_page_create
      ] => :renderer

      def save_graphics_state(state = nil, &block)
        save_transformation_stack
        renderer.save_graphics_state(state, &block)
      end

      def restore_graphics_state
        restore_transformation_stack
        renderer.restore_graphics_state
      end

      # FIXME: This is a circular reference, because in theory Prawn should
      # be passing instances of renderer to PDF::Core::Page, but it's
      # passing Prawn::Document objects instead.
      #
      # A proper design would probably not require Prawn to directly instantiate
      # PDF::Core::Page objects at all!
      delegate [:compression_enabled?] => :renderer

      # FIXME: More circular references in PDF::Core::Page.
      delegate %i[ref ref! deref] => :renderer

      # FIXME: Another circular reference, because we mix in a module from
      # PDF::Core to provide destinations, which in theory should not
      # rely on a Prawn::Document object but is currently wired up that way.
      delegate [:names] => :renderer

      # FIXME: Circular reference because we mix PDF::Core::Text into
      # Prawn::Document. PDF::Core::Text should either be split up or
      # moved in its entirety back up into Prawn.
      delegate [:add_content] => :renderer

      def renderer
        @renderer ||= PDF::Core::Renderer.new(state)
      end
    end
  end
end
