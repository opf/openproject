# frozen_string_literal: true

require "net/ldap"

module LdapDepartments
  # Mirrors the organizational unit subtree below a SynchronizedTree's base DN into the OpenProject
  # department hierarchy. Creates/updates one department (Group with organizational_unit: true) per
  # OU and prunes mappings for OUs that disappeared (keeping the department itself).
  class SynchronizeTreeService
    attr_reader :tree, :ldap

    def initialize(tree)
      @tree = tree
      @ldap = tree.ldap_auth_source
      @by_dn = {}
    end

    def call
      count = synchronize!
      ServiceResult.success(result: count)
    rescue StandardError => e
      message = "[LDAP departments] Failed to synchronize tree '#{tree.name}': #{e.class}: #{e.message}"
      Rails.logger.error(message)
      ServiceResult.failure(message:)
    end

    def synchronize!
      entries = fetch_ou_entries
      # Process shallow OUs first so a child can always resolve its already-persisted parent.
      entries.sort_by! { |entry| Dn.depth(entry[:dn]) }

      seen = []
      entries.each do |entry|
        next if entry[:name].blank?

        sync = upsert_department(entry)
        normalized = Dn.normalize(sync.dn)
        @by_dn[normalized] = sync
        seen << normalized
      end

      prune_removed(seen)
      seen.size
    end

    private

    def fetch_ou_entries
      base = Dn.normalize(tree.base_dn)

      entries = []
      ldap.with_connection do |connection|
        connection.search(base: tree.base_dn, filter: tree.parsed_structure_filter, attributes: ou_search_attributes) do |entry|
          # The base DN itself is the anchor, not a department.
          next if Dn.normalize(entry.dn) == base

          entries << build_ou_entry(entry)
        end
      end

      entries
    end

    def ou_search_attributes
      ["dn", tree.ou_name_attribute, tree.guid_attribute].compact
    end

    def build_ou_entry(entry)
      {
        dn: entry.dn,
        name: LdapAuthSource.get_attr(entry, tree.ou_name_attribute),
        uuid: guid_value(entry)
      }
    end

    def guid_value(entry)
      return nil unless tree.guid_lookup?

      raw = Array(entry[tree.guid_attribute]).first
      return nil if raw.nil?

      if raw.encoding == Encoding::BINARY || !raw.valid_encoding?
        raw.unpack1("H*")
      else
        raw
      end
    end

    def upsert_department(entry)
      sync = find_existing(entry) || tree.synchronized_departments.build
      assign_department_group(sync, entry)
      sync.save!
      sync
    end

    def assign_department_group(sync, entry)
      sync.synchronized_tree = tree
      sync.ldap_auth_source = ldap
      sync.dn = entry[:dn]
      sync.ldap_entry_uuid = entry[:uuid] if entry[:uuid].present?
      apply_group(sync, entry)
    end

    def apply_group(sync, entry)
      parent_group_id = resolve_parent_group_id(entry[:dn])

      if sync.group_id
        update_department(sync.group, entry[:name], parent_group_id)
      else
        sync.group = create_department(entry[:name], parent_group_id)
      end
    end

    def find_existing(entry)
      if entry[:uuid].present?
        tree.synchronized_departments.find_by(ldap_entry_uuid: entry[:uuid]) ||
          find_by_dn(entry[:dn])
      else
        find_by_dn(entry[:dn])
      end
    end

    def find_by_dn(value)
      tree.synchronized_departments.find_by(dn: value)
    end

    # The parent OU's department, or nil when the parent is the base DN (→ top-level department).
    def resolve_parent_group_id(child_dn)
      parent = Dn.parent(child_dn)
      return nil if parent.nil?

      normalized_parent = Dn.normalize(parent)
      return nil if normalized_parent == Dn.normalize(tree.base_dn)

      parent_sync = @by_dn[normalized_parent]
      unless parent_sync
        Rails.logger.warn { "[LDAP departments] No synced parent for #{child_dn}, treating as top-level" }
      end

      parent_sync&.group_id
    end

    def create_department(name, parent_group_id)
      call = Groups::CreateService
        .new(user: User.system, contract_class: Groups::SyncCreateContract)
        .call(name:, organizational_unit: true, parent_id: parent_group_id)
      require_success!(call, "create department '#{name}'")
      call.result
    end

    def update_department(group, name, parent_group_id)
      return if group.name == name && group.parent_id == parent_group_id

      call = Groups::UpdateService
        .new(user: User.system, model: group, contract_class: Groups::SyncUpdateContract)
        .call(name:, parent_id: parent_group_id)
      require_success!(call, "update department '#{name}'")
    end

    def require_success!(call, action)
      raise "Failed to #{action}: #{call.message}" unless call.success?
    end

    def prune_removed(seen)
      SynchronizedDepartment
        .where(synchronized_tree_id: tree.id)
        .reject { |sync| seen.include?(Dn.normalize(sync.dn)) }
        .each do |sync|
          Rails.logger.info { "[LDAP departments] OU #{sync.dn} no longer present, unmanaging department" }
          sync.destroy!
        end
    end
  end
end
