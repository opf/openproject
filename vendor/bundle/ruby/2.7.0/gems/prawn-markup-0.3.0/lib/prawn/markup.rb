# frozen_string_literal: true

require 'prawn'
require 'prawn/measurement_extensions'
require 'prawn/table'
require 'nokogiri'
require 'prawn/markup/support/hash_merger'
require 'prawn/markup/support/size_converter'
require 'prawn/markup/support/normalizer'
require 'prawn/markup/elements/item'
require 'prawn/markup/elements/cell'
require 'prawn/markup/elements/list'
require 'prawn/markup/builders/nestable_builder'
require 'prawn/markup/builders/list_builder'
require 'prawn/markup/builders/table_builder'
require 'prawn/markup/processor'
require 'prawn/markup/interface'
require 'prawn/markup/version'

module Prawn
  module Markup
  end
end

Prawn::Document.extensions << Prawn::Markup::Interface
