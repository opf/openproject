# frozen_string_literal: true

module OpPrimer
  # @logical_path OpenProject/Primer
  # @display min_height 300px
  class BorderBoxTableComponentPreview < Lookbook::Preview
    def default
      render_with_template
    end

    def custom_column_widths
      render_with_template
    end

    def with_action_menu
      render_with_template
    end
  end
end
