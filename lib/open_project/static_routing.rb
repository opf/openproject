module OpenProject
  module StaticRouting
    ##
    # Makes URL helpers accessible outside the view or controller context.
    # It's called static routing url helpers as it does not use request information.
    # For instance it does not read the host from the request but instead
    # it takes the host from the Settings. This may or may not work completely.
    #
    # Most importantly it does work for the '#{model}_path|url' helpers, though.
    module UrlHelpers
      extend ActiveSupport::Concern
      include Rails.application.routes.url_helpers

      included do
        def default_url_options
          options = ActionMailer::Base.default_url_options

          root = OpenProject::Configuration.rails_relative_url_root
          unless options[:script_name] || root.blank?
            options[:script_name] = root
          end

          host = OpenProject::StaticRouting::UrlHelpers.host
          unless options[:host] || host.blank?
            options[:host] = host
          end

          options
        end
      end

      def self.host
        host = Setting.host_name
        host.gsub(/\/.*$/, "") if host # remove path in case it got into the host
      end
    end

    class StaticRouter
      def url_helpers
        @url_helpers ||= StaticUrlHelpers.new
      end
    end

    class StaticUrlHelpers
      include StaticRouting::UrlHelpers
    end
  end
end
