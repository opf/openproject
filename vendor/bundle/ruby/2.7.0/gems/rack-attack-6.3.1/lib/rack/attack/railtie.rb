# frozen_string_literal: true

module Rack
  class Attack
    class Railtie < ::Rails::Railtie
      initializer "rack-attack.middleware" do |app|
        if Gem::Version.new(::Rails::VERSION::STRING) >= Gem::Version.new("5.1")
          app.middleware.use(Rack::Attack)
        end
      end
    end
  end
end
