module OpenProject
  module Common
    # @hidden
    class PageHeaderPreview < Lookbook::Preview
      def default
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title { "Some important page" }
          header.with_description { "Some optional description" }
          header.with_breadcrumbs([{ href: "/foo", text: "Project A" },
                                   { href: "/bar", text: "Module B" },
                                   "Some important page"])

          header.with_action_button(mobile_icon: "star", mobile_label: "Star") do |button|
            button.with_leading_visual_icon(icon: "star")
            "Star"
          end

          header.with_action_icon_button(icon: :trash, mobile_icon: :trash, label: "Delete", scheme: :danger)

          header.with_action_menu(menu_arguments: { anchor_align: :end },
                                  button_arguments: { icon: "op-kebab-vertical", "aria-label": "Menu" }) do |menu|
            menu.with_item(label: "Subitem 1") do |item|
              item.with_leading_visual_icon(icon: :paste)
            end
            menu.with_item(label: "Subitem 2") do |item|
              item.with_leading_visual_icon(icon: :log)
            end
          end
        end
      end
    end
  end
end
