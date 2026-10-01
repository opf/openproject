# frozen_string_literal: true

module LdapDepartments
  module SynchronizedTrees
    class RowComponent < OpPrimer::BorderBoxRowComponent
      def name
        render(Primer::Beta::Link.new(
                 href: ldap_departments_synchronized_tree_path(tree_id: model.id),
                 font_weight: :bold
               )) { model.name }
      end

      def ldap_auth_source
        model.ldap_auth_source&.name
      end

      delegate :base_dn, to: :model

      def departments
        model.synchronized_departments.size
      end

      def button_links
        [actions_menu]
      end

      private

      def actions_menu
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", scheme: :invisible, "aria-label": I18n.t(:label_actions))
          add_edit_item(menu)
          add_delete_item(menu)
        end
      end

      def add_edit_item(menu)
        menu.with_item(
          label: I18n.t(:button_edit),
          tag: :a,
          href: edit_ldap_departments_synchronized_tree_path(tree_id: model.id)
        ) { it.with_leading_visual_icon(icon: :pencil) }
      end

      def add_delete_item(menu)
        menu.with_item(
          label: I18n.t(:button_delete),
          scheme: :danger,
          tag: :a,
          href: deletion_dialog_ldap_departments_synchronized_tree_path(tree_id: model.id),
          content_arguments: { data: { controller: "async-dialog" } }
        ) { it.with_leading_visual_icon(icon: :trash) }
      end
    end
  end
end
