# frozen_string_literal: true

module LdapDepartments
  module SynchronizedTrees
    class DeleteDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      def initialize(tree:)
        super()
        @tree = tree
      end

      private

      attr_reader :tree

      def form_arguments
        {
          action: ldap_departments_synchronized_tree_path(tree_id: tree.id),
          method: :delete
        }
      end

      def title
        I18n.t("ldap_departments.synchronized_trees.destroy.title", name: tree.name)
      end

      def heading
        I18n.t("ldap_departments.synchronized_trees.destroy.heading", name: tree.name)
      end

      def confirmation_text
        I18n.t("ldap_departments.synchronized_trees.destroy.confirmation",
               name: tree.name,
               departments_count: tree.synchronized_departments.size)
      end

      def info_text
        I18n.t("ldap_departments.synchronized_trees.destroy.info")
      end
    end
  end
end
