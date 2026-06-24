# frozen_string_literal: true

module LdapDepartments
  module SynchronizedTrees
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :name, :ldap_auth_source, :base_dn, :departments
      main_column :name
      mobile_columns :name
      mobile_labels :ldap_auth_source, :base_dn, :departments

      def mobile_title
        I18n.t("ldap_departments.synchronized_trees.plural")
      end

      def row_class
        RowComponent
      end

      def has_actions?
        true
      end

      def headers
        [
          [:name, { caption: SynchronizedTree.human_attribute_name(:name) }],
          [:ldap_auth_source, { caption: SynchronizedTree.human_attribute_name(:ldap_auth_source) }],
          [:base_dn, { caption: SynchronizedTree.human_attribute_name(:base_dn) }],
          [:departments, { caption: I18n.t("ldap_departments.synchronized_departments.plural") }]
        ]
      end

      def blank_title
        I18n.t("ldap_departments.synchronized_trees.blankslate.heading")
      end

      def blank_description
        I18n.t("ldap_departments.synchronized_trees.blankslate.description")
      end

      def blank_icon
        :organization
      end
    end
  end
end
