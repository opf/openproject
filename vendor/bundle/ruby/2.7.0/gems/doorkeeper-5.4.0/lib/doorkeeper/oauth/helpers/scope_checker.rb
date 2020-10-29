# frozen_string_literal: true

module Doorkeeper
  module OAuth
    module Helpers
      module ScopeChecker
        class Validator
          attr_reader :parsed_scopes, :scope_str

          def initialize(scope_str, server_scopes, app_scopes, grant_type)
            @parsed_scopes = OAuth::Scopes.from_string(scope_str)
            @scope_str = scope_str
            @valid_scopes = valid_scopes(server_scopes, app_scopes)

            if grant_type
              @scopes_by_grant_type = Doorkeeper.config.scopes_by_grant_type[grant_type.to_sym]
            end
          end

          def valid?
            scope_str.present? &&
              scope_str !~ /[\n\r\t]/ &&
              @valid_scopes.has_scopes?(parsed_scopes) &&
              permitted_to_grant_type?
          end

          private

          def valid_scopes(server_scopes, app_scopes)
            app_scopes.presence || server_scopes
          end

          def permitted_to_grant_type?
            return true unless @scopes_by_grant_type

            OAuth::Scopes.from_array(@scopes_by_grant_type)
              .has_scopes?(parsed_scopes)
          end
        end

        def self.valid?(scope_str:, server_scopes:, app_scopes: nil, grant_type: nil)
          Validator.new(
            scope_str,
            server_scopes,
            app_scopes,
            grant_type,
          ).valid?
        end
      end
    end
  end
end
