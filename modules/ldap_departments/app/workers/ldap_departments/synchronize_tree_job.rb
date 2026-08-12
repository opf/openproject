# frozen_string_literal: true

module LdapDepartments
  # Synchronizes a single tree in the background. Triggered when a tree is created or when an admin
  # requests a manual synchronization, since syncing a large organizational unit tree can be slow.
  class SynchronizeTreeJob < ApplicationJob
    def perform(tree)
      return unless EnterpriseToken.allows_to?(:ldap_groups)
      return if tree.nil?

      ::LdapDepartments::SynchronizationService.synchronize_tree!(tree)
    end
  end
end
