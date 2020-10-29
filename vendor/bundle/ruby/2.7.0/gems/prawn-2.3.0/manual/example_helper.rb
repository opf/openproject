# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, '../lib')
require 'prawn'
require 'prawn/manual_builder'

Prawn::ManualBuilder.manual_dir = File.dirname(__FILE__)
Prawn::Fonts::AFM.hide_m17n_warning = true
