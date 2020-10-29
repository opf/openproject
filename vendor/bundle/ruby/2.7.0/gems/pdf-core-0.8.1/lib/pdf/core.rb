# frozen_string_literal: true

require_relative 'core/pdf_object'
require_relative 'core/annotations'
require_relative 'core/byte_string'
require_relative 'core/destinations'
require_relative 'core/filters'
require_relative 'core/stream'
require_relative 'core/reference'
require_relative 'core/literal_string'
require_relative 'core/filter_list'
require_relative 'core/page'
require_relative 'core/object_store'
require_relative 'core/document_state'
require_relative 'core/name_tree'
require_relative 'core/graphics_state'
require_relative 'core/page_geometry'
require_relative 'core/outline_root'
require_relative 'core/outline_item'
require_relative 'core/renderer'
require_relative 'core/text'

module PDF
  module Core
    module Errors
      # This error is raised when pdf_object() fails
      FailedObjectConversion = Class.new(StandardError)

      # This error is raise when trying to restore a graphic state that
      EmptyGraphicStateStack = Class.new(StandardError)

      # This error is raised when Document#page_layout is set to anything
      # other than :portrait or :landscape
      InvalidPageLayout = Class.new(StandardError)
    end
  end
end
