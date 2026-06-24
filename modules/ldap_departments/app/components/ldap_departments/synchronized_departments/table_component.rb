# frozen_string_literal: true

module LdapDepartments
  module SynchronizedDepartments
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :group, :dn, :users
      main_column :group
      mobile_columns :group
      mobile_labels :dn, :users

      def mobile_title
        I18n.t("ldap_departments.synchronized_departments.plural")
      end

      def row_class
        RowComponent
      end

      def has_actions?
        true
      end

      def headers
        [
          [:group, { caption: SynchronizedDepartment.human_attribute_name(:group) }],
          [:dn, { caption: SynchronizedDepartment.human_attribute_name(:dn) }],
          [:users, { caption: SynchronizedDepartment.human_attribute_name(:users_count) }]
        ]
      end

      def blank_title
        I18n.t("ldap_departments.synchronized_departments.blankslate.heading")
      end

      def blank_description
        I18n.t("ldap_departments.synchronized_departments.blankslate.description")
      end

      def blank_icon
        :organization
      end

      # The full department path (e.g. "Human Resources / Support"), built in memory from the
      # tree's departments to avoid a hierarchy query per row.
      def path_for(group)
        names = []
        current = group
        while current
          names.unshift(current.name)
          current = groups_by_id[current.parent_id]
        end
        names.join(" / ")
      end

      private

      def groups_by_id
        @groups_by_id ||= rows.filter_map(&:group).index_by(&:id)
      end
    end
  end
end
