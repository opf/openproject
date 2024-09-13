# frozen_string_literal: true

module Patterns
  # @hidden
  class FormsPreview < ViewComponent::Preview
    # @display min_height 500px
    def default; end

    # @display min_height 300px
    # @label Overview
    def custom_width_fields_form; end
  end
end
