# frozen_string_literal: true

module Doorkeeper
  module DashboardHelper
    def doorkeeper_errors_for(object, method)
      return if object.errors[method].blank?

      output = object.errors[method].map do |msg|
        content_tag(:span, class: "form-text") do
          msg.capitalize
        end
      end

      safe_join(output)
    end

    def doorkeeper_submit_path(application)
      application.persisted? ? oauth_application_path(application) : oauth_applications_path
    end
  end
end
