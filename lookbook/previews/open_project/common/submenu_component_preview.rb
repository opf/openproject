module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class SubmenuComponentPreview < Lookbook::Preview
      # @label Default
      # @display min_height 450px
      def default
        render_with_template(template: "open_project/common/submenu_preview/default")
      end

      # @label Playground
      # @display min_height 450px
      # @param searchable [Boolean]
      # @param with_create_button [Boolean]
      # @param favored [Boolean]
      # @param count [Integer]
      # @param show_enterprise_icon [Boolean]
      # @param icon [Symbol] octicon
      def playground(searchable: false,
                     with_create_button: false,
                     favored: false,
                     count: nil,
                     show_enterprise_icon: false,
                     icon: nil)
        render_with_template(template: "open_project/common/submenu_preview/playground",
                             locals: {
                               searchable:,
                               create_btn_options: with_create_button ? { href: "/#", module_key: "user" } : nil,
                               favored:,
                               count:,
                               show_enterprise_icon:,
                               icon:
                             })
      end
    end
  end
end
