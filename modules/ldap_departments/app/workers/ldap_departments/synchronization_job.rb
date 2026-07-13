# frozen_string_literal: true

module LdapDepartments
  class SynchronizationJob < ApplicationJob
    def perform
      return unless EnterpriseToken.allows_to?(:ldap_groups)
      return if skipped?

      ::LdapDepartments::SynchronizationService.synchronize!
    end

    def skipped?
      OpenProject::Configuration.ldap_departments_disable_sync_job?
    end
  end
end
