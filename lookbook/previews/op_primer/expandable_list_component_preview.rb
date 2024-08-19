# frozen_string_literal: true

module OpPrimer
  # @logical_path OpenProject/Primer
  class ExpandableListComponentPreview < Lookbook::Preview
    # Renders an expandable list with a given number of elements
    # @param cutoff_limit number The cutoff limit for the number of elements to render
    def default(cutoff_limit: 5)
      render_with_template(locals: { cutoff_limit:, elements: ("a".."z").to_a })
    end

    # Renders a turbo-stream tag with given action and target
    # @param cutoff_limit number The cutoff limit for the number of elements to render
    def primer(cutoff_limit: 5)
      render_with_template(locals: { cutoff_limit:, elements: ("a".."z").to_a })
    end
  end
end
