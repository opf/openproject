module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class SubmenuComponentPreview < Lookbook::Preview
      def default
        # Meant to be rendered inside the left-handed sidebar
        render OpenProject::Common::SubmenuComponent.new(
          sidebar_menu_items: [
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
                OpenProject::Menu::MenuItem.new(title: "ROLE X", href: "", selected: false)
              ]
            ),
            OpenProject::Menu::MenuGroup.new(
              header: I18n.t("members.menu.groups"),
              children: [
                OpenProject::Menu::MenuItem.new(title: "GROUP X", href: "", selected: false)
              ]
            )
          ]
        )
      end
    end
  end
end
