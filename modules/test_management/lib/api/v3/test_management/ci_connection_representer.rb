# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # A CI connection of a project. The access token is write-only and never part of the
      # representation; tokenSet only tells whether one is stored. The CA certificate PEM is not
      # rendered either (caCertificates summarizes it).
      class CiConnectionRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_ci_connection(represented.id), title: represented.name }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        link :repository do
          { href: represented.repository_url }
        end

        property :id
        property :name
        property :provider
        property :repository
        property :base_url, as: :baseUrl, getter: ->(*) { effective_base_url }
        property :ingest_mode, as: :ingestMode
        property :target_run_name, as: :targetRunName, render_nil: true
        property :active
        property :token_set, as: :tokenSet, getter: ->(*) { token_set? }
        # "Run in CI" (0011); trigger secrets are write-only like the token.
        property :workflow, render_nil: true
        property :trigger_ref, as: :ref, getter: ->(*) { effective_trigger_ref }
        property :ci_username, as: :username, render_nil: true
        property :trigger_token_set, as: :triggerTokenSet, getter: ->(*) { trigger_token_set? }
        property :trigger_ready, as: :triggerReady, getter: ->(*) { trigger_ready? }
        property :check_status, as: :checkStatus, render_nil: true
        # Self-hosted servers (0015). The CA certificate is public data; only a summary is rendered.
        property :inbound_only, as: :inboundOnly, getter: ->(*) { inbound_only? }
        property :server_version, as: :serverVersion, render_nil: true
        property :ca_certificates, as: :caCertificates, exec_context: :decorator,
                                   getter: ->(*) {
                                     represented.ca_summary.map do |ca|
                                       { "subject" => ca[:name], "notAfter" => ca[:not_after].utc.iso8601, "expired" => ca[:expired] }
                                     end
                                   }
        # 0016: server part of the uniqueness rule, repo-qualified references, attached repository
        # of the Repositories module. referenceQualifier is the prefix used ("shop" -> shop:…).
        property :server_url, as: :serverUrl
        property :reference_name, as: :referenceName, render_nil: true
        property :reference_qualifier, as: :referenceQualifier, render_nil: true,
                                       getter: ->(*) { reference_qualifier_name }
        property :e2e_tests, as: :e2eTests
        property :scm_repository_id, as: :scmRepositoryId, render_nil: true
        date_time_property :checked_at, render_nil: true
        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "TestManagementCiConnection"
        end
      end
    end
  end
end
