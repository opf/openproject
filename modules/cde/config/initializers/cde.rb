# frozen_string_literal: true

# CDE Plugin initializer
# This file is loaded by Rails when the engine is mounted

require 'cde/conventions'
require 'cde/identifier_validator'
require 'cde/publication_gate'

# Load models
Dir[Rails.root.join('modules/cde/app/models/**/*.rb')].each do |f|
  require f
end

# Load services
Dir[Rails.root.join('modules/cde/app/services/**/*.rb')].each do |f|
  require f
end

# Load controllers
Dir[Rails.root.join('modules/cde/app/controllers/**/*.rb')].each do |f|
  require f
end

# Initialize conventions
Cde::Conventions.initialize
