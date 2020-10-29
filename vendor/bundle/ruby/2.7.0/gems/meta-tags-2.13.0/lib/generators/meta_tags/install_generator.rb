# frozen_string_literal: true

module MetaTags
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Copy MetaTags default files"
      source_root File.expand_path('templates', __dir__)

      def copy_config
        template "config/initializers/meta_tags.rb"
      end
    end
  end
end
