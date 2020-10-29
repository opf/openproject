# encoding: UTF-8

require "prawn"
require_relative "../lib/prawn/table"

require "prawn/manual_builder"

Prawn::ManualBuilder.manual_dir = File.dirname(__FILE__)
