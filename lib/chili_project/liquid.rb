require 'chili_project/liquid/liquid_ext'
require 'chili_project/liquid/tags'

module ChiliProject
  module Liquid
    Liquid::Template.file_system = FileSystem.new
  end
end