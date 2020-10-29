require 'rails/railtie'

module ActiveRecord
  module SessionStore
    class Railtie < Rails::Railtie
      rake_tasks { load File.expand_path("../../../tasks/database.rake", __FILE__) }
    end
  end
end
