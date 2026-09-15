# frozen_string_literal: true

require 'rails'
require 'aasm'

module OpenProject
  module Cde
    class Engine < Rails::Engine
      isolate_namespace Cde

      paths['db/migrate'] = Engine.root.join('db/migrate').to_s
      paths['config/locales'] = Engine.root.join('config/locales').to_s

      initializer 'cde.assets.precompile', before: :load_config_initializers do |app|
        app.config.assets.precompile += %w[cde/*.css cde/*.js]
      end

      initializer 'cde.initializer' do
        # Load conventions from config
        config.after_initialize do
          Cde::Conventions.initialize if defined?(Cde::Conventions)
        end
      end
    end
  end
end
