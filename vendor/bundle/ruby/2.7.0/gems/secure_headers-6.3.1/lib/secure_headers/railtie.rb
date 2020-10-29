# frozen_string_literal: true
# rails 3.1+
if defined?(Rails::Railtie)
  module SecureHeaders
    class Railtie < Rails::Railtie
      isolate_namespace SecureHeaders if defined? isolate_namespace # rails 3.0
      conflicting_headers = ["X-Frame-Options", "X-XSS-Protection",
                             "X-Permitted-Cross-Domain-Policies", "X-Download-Options",
                             "X-Content-Type-Options", "Strict-Transport-Security",
                             "Content-Security-Policy", "Content-Security-Policy-Report-Only",
                             "Public-Key-Pins", "Public-Key-Pins-Report-Only", "Referrer-Policy"]

      initializer "secure_headers.middleware" do
        Rails.application.config.middleware.insert_before 0, SecureHeaders::Middleware
      end

      rake_tasks do
        load File.expand_path(File.join("..", "..", "lib", "tasks", "tasks.rake"), File.dirname(__FILE__))
      end

      initializer "secure_headers.action_controller" do
        ActiveSupport.on_load(:action_controller) do
          include SecureHeaders

          unless Rails.application.config.action_dispatch.default_headers.nil?
            conflicting_headers.each do |header|
              Rails.application.config.action_dispatch.default_headers.delete(header)
            end
          end
        end
      end
    end
  end
else
  module ActionController
    class Base
      include SecureHeaders
    end
  end
end
