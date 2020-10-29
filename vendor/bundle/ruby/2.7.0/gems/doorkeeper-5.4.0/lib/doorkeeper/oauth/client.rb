# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class Client
      attr_reader :application

      delegate :id, :name, :uid, :redirect_uri, :scopes, to: :@application

      def initialize(application)
        @application = application
      end

      def self.find(uid, method = Doorkeeper.config.application_model.method(:by_uid))
        return unless (application = method.call(uid))

        new(application)
      end

      def self.authenticate(credentials, method = Doorkeeper.config.application_model.method(:by_uid_and_secret))
        return if credentials.blank?
        return unless (application = method.call(credentials.uid, credentials.secret))

        new(application)
      end
    end
  end
end
