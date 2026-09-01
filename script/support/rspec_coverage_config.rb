# frozen_string_literal: true

require "simplecov"

module RSpecCoverage
  ROOT = File.expand_path("../..", __dir__).freeze

  def self.configure
    SimpleCov.configure do
      root ROOT
      enable_coverage :branch, :eval
      cover "app/**/*.rb", "lib/**/*.rb", "lib_static/**/*.rb", "modules/*/{app,lib}/**/*.rb"
      cover %r{\A/?(?:app|lib|lib_static|modules/[^/]+/(?:app|lib))/.*\.erb\z}
      group "Application", %r{\A/?app/}
      group "Libraries", %r{\A/?lib/}
      group "Static libraries", %r{\A/?lib_static/}
      group "Modules", %r{\A/?modules/}
      parallel_tests false
      formatters []
    end
  end
end
