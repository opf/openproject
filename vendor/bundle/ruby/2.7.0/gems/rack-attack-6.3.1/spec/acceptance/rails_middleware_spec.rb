# frozen_string_literal: true

require_relative "../spec_helper"

if defined?(Rails)
  describe "Middleware for Rails" do
    before do
      @app = Class.new(Rails::Application) do
        config.eager_load = false
        config.logger = Logger.new(nil) # avoid creating the log/ directory automatically
        config.cache_store = :null_store # avoid creating tmp/ directory for cache
      end
    end

    if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new("5.1")
      it "is used by default" do
        @app.initialize!
        assert_equal 1, @app.middleware.count(Rack::Attack)
      end

      it "is not added when it was explicitly deleted" do
        @app.config.middleware.delete(Rack::Attack)
        @app.initialize!
        refute @app.middleware.include?(Rack::Attack)
      end
    end

    if Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new("5.1")
      it "is not used by default" do
        @app.initialize!
        assert_equal 0, @app.middleware.count(Rack::Attack)
      end
    end
  end
end
