# frozen_string_literal: true

module LdapDepartments
  module SynchronizedTrees
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      private

      def form_options
        form_target.merge(model:, scope: :synchronized_tree)
      end

      def form_target
        if model.new_record?
          { method: :post, url: ldap_departments_synchronized_trees_path }
        else
          { method: :patch, url: ldap_departments_synchronized_tree_path(tree_id: model.id) }
        end
      end
    end
  end
end
