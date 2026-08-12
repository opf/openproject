# frozen_string_literal: true

module LdapDepartments
  module SynchronizedDepartments
    class RowComponent < OpPrimer::BorderBoxRowComponent
      def group
        return if model.group.nil?

        render(Primer::Beta::Link.new(href: admin_department_path(model.group), font_weight: :bold)) do
          table.path_for(model.group)
        end
      end

      delegate :dn, to: :model

      def users
        model.users_count
      end

      def button_links
        [actions_menu]
      end

      private

      def actions_menu
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", scheme: :invisible, "aria-label": I18n.t(:label_actions))

          menu.with_item(
            label: I18n.t(:button_delete),
            scheme: :danger,
            tag: :a,
            href: deletion_dialog_ldap_departments_synchronized_department_path(department_id: model.id),
            content_arguments: { data: { controller: "async-dialog" } }
          ) { it.with_leading_visual_icon(icon: :trash) }
        end
      end
    end
  end
end
