module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class SubmenuComponentPreview < Lookbook::Preview
      # @label Default
      def default
        render_with_template(template: "open_project/common/submenu_preview/playground",
                             locals: { sidebar_menu_items: menu_items, searchable: false, create_btn_options: nil })
      end

      # @label Searchable
      # Searching is currently not working in the lookbook because stimulus controllers are not loaded correctly.
      # It will be fine in production.
      def searchable
        render_with_template(template: "open_project/common/submenu_preview/playground",
                             locals: { sidebar_menu_items: menu_items, searchable: true, create_btn_options: nil })
      end

      # @label With create Button
      # `create_btn_options: { href: "/#", text: "User"}`
      def with_create_button
        render_with_template(template: "open_project/common/submenu_preview/playground",
                             locals: { sidebar_menu_items: menu_items, searchable: true,
                                       create_btn_options: { href: "/#", module_key: "user" } })
      end

      private

      def menu_items
        [
          OpenProject::Menu::MenuGroup.new(
            header: nil,
            children: [
              OpenProject::Menu::MenuItem.new(title: I18n.t("members.menu.all"), href: "", selected: true),
              OpenProject::Menu::MenuItem.new(title: I18n.t("members.menu.locked"), href: "", selected: false),
              OpenProject::Menu::MenuItem.new(title: I18n.t("members.menu.invited"), href: "", selected: false)
            ]
          ),
          OpenProject::Menu::MenuGroup.new(
            header: I18n.t("members.menu.project_roles"),
            children: [
              OpenProject::Menu::MenuItem.new(title: "Developer", href: "", selected: false),
              OpenProject::Menu::MenuItem.new(title: "Manager", href: "", selected: true)
            ]
          ),
          OpenProject::Menu::MenuGroup.new(
            header: I18n.t("members.menu.groups"),
            children: [
              OpenProject::Menu::MenuItem.new(title: "UX", href: "", selected: false),
              OpenProject::Menu::MenuItem.new(title: "Customer success", href: "", selected: false),
              OpenProject::Menu::MenuItem.new(title: "Core dev team", href: "", selected: false)
            ]
          )
        ]
      end
    end
  end
end
