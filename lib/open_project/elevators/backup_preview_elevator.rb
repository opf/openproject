require 'apartment/elevators/generic'
require_relative '../../../app/helpers/backup_preview_helper'

module OpenProject
  module Elevators
    class BackupPreviewElevator
      include BackupPreviewHelper

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        return maintenance_response if maintenance?(env)
        return app.call env if skip?(env)

        request = make_request env
        schema = preview_schema request

        if schema.present?
          preview! schema, env
        else
          app.call env
        end
      end

      def preview!(schema, env)
        Apartment::Tenant.switch(schema) do
          app.call env
        end
      rescue Apartment::TenantNotFound
        set_flash env, error: 'tenant not found'

        app.call env
      end

      def make_request(env)
        ActionDispatch::Request.new Rails.application.env_config.merge(env)
      end

      def skip?(env)
        env["HTTP_COOKIE"].exclude?("backup_preview=")
      end

      def maintenance?(env)
        enabled = Hash(Setting._maintenance_mode)['enabled']

        enabled && paths_allowed_during_maintenance.none? { |p| env["REQUEST_PATH"] =~ p }
      end

      def paths_allowed_during_maintenance
        [
          # we allow this so the status of the back restoration can still be checked
          /\/api\/v3\/job_statuses\//,
          # allow to perform the schema switch after successful restoration
          /\/admin\/backups\/\d+\/restore/
        ]
      end

      def preview_schema(request)
        yaml = request.cookie_jar.signed[:backup_preview]

        return nil if yaml.blank?

        preview = load_backup_preview_yaml yaml

        preview[:schema].presence
      end

      def set_flash(env, content)
        env[ActionDispatch::Flash::KEY] = ActionDispatch::Flash::FlashHash.new(content)
      end

      def maintenance_response
        message = Hash(Setting._maintenance_mode)['message'].presence || 'maintenance mode'
        response = Rack::Response.new(
          [message],
          503,
          {
            'Content-Type' => 'text/html',
            'Cache-Control' => 'no-cache, no-store',
            'Pragma' => 'no-cache',
            'Expires' => 'Fri, 01 Jan 1990 00:00:00 GMT'
          }
        )

        response.finish
      end
    end
  end
end
