# frozen_string_literal: true

module LdapDepartments
  module SynchronizedTrees
    class SidePanelComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(tree:)
        super()
        @tree = tree
      end

      private

      attr_reader :tree

      # [label, value] pairs shown in the side panel; optional attributes are only listed when set.
      def attributes
        shown_keys.map { |key| [SynchronizedTree.human_attribute_name(key), value_for(key)] }
      end

      def shown_keys
        keys = %i[ldap_auth_source base_dn structure_filter_string ou_name_attribute]
        keys << :guid_attribute if tree.guid_attribute.present?
        keys << :user_filter_string if tree.user_filter_string.present?
        keys << :sync_users
        keys
      end

      def value_for(key)
        case key
        when :ldap_auth_source then tree.ldap_auth_source&.name
        when :sync_users then checkmark_text(tree.sync_users)
        else tree.public_send(key)
        end
      end

      def checkmark_text(value)
        value ? I18n.t(:general_text_Yes) : I18n.t(:general_text_No)
      end
    end
  end
end
