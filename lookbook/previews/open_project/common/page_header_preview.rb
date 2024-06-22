module OpenProject
  module Common
    # @hidden
    class PageHeaderPreview < Lookbook::Preview
      def default
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title { "Some important page" }
          header.with_description do
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore."
          end
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

      # @label Playground
      # @param variant [Symbol] select [medium, large]
      # @param title [String] text
      # @param description [String] text
      # @param with_leading_action [Symbol] octicon
      # @param with_actions [Boolean]
      # @param with_tab_nav [Boolean]
      # rubocop:disable Metrics/AbcSize
      def playground(
        variant: :medium,
        title: "Hello",
        description: "Last updated 5 minutes ago by XYZ.",
        with_leading_action: :none,
        with_actions: true,
        with_tab_nav: false
      )

        breadcrumb_items = [{ href: "/foo", text: "Project A" },
                            { href: "/bar", text: "Module B" },
                            "Some important page"]

        render Primer::OpenProject::PageHeader.new do |header|
          header.with_title(variant:) { title }
          header.with_description { description }
          if with_leading_action && with_leading_action != :none
            header.with_leading_action(icon: with_leading_action, href: "#",
                                       "aria-label": "A leading action")
          end
          header.with_breadcrumbs(breadcrumb_items)
          if with_actions
            header.with_action_icon_button(icon: "pencil", mobile_icon: "pencil", label: "Edit")
            header.with_action_menu(menu_arguments: { anchor_align: :end },
                                    button_arguments: { icon: "op-kebab-vertical",
                                                        "aria-label": "Menu" }) do |menu, _button|
              menu.with_item(label: "Subitem 1") do |item|
                item.with_leading_visual_icon(icon: :unlock)
              end
              menu.with_item(label: "Subitem 2", scheme: :danger) do |item|
                item.with_leading_visual_icon(icon: :trash)
              end
            end
          end
          if with_tab_nav
            header.with_tab_nav(label: "label") do |nav|
              nav.with_tab(selected: true, href: "#") { "Tab 1" }
              nav.with_tab(href: "#") { "Tab 2" }
              nav.with_tab(href: "#") { "Tab 3" }
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
