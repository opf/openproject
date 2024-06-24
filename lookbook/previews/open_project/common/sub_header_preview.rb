module OpenProject
  module Common
    # @hidden
    class SubHeaderPreview < Lookbook::Preview
      def default
        render(Primer::OpenProject::SubHeader.new) do |component|
          component.with_filter_input(name: "filter", label: "Filter")
          component.with_filter_button do |button|
            button.with_trailing_visual_counter(count: "15")
            "Filter"
          end
          component.with_action_button(scheme: :primary) do |button|
            button.with_leading_visual_icon(icon: :plus)
            "Create"
          end
        end
      end

      # @label Playground
      # @param show_filter_input toggle
      # @param show_filter_button toggle
      # @param show_action_button toggle
      # @param text text
      def playground(show_filter_input: true, show_filter_button: true, show_action_button: true, text: "Monday, 12th")
        render(Primer::OpenProject::SubHeader.new) do |component|
          component.with_filter_input(name: "filter", label: "Filter") if show_filter_input
          if show_filter_button
            component.with_filter_button do |button|
              button.with_trailing_visual_counter(count: "15")
              "Filter"
            end
          end

          component.with_text { text } unless text.nil?

          if show_action_button
            component.with_action_button(scheme: :primary) do |button|
              button.with_leading_visual_icon(icon: :plus)
              "Create"
            end
          end
        end
      end
    end
  end
end
