module UiComponents
  module Dsl
    module Common
      def self.included(receiver)
        receiver.send :include, Redmine::I18n
        receiver.send :include, Rails.application.routes.url_helpers
      end
    end
  end
end
