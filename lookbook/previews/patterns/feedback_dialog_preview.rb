# frozen_string_literal: true

module Patterns
  # @hidden
  class FeedbackDialogPreview < ViewComponent::Preview
    # @display min_height 300px
    def default
      render_with_template
    end

    # @display min_height 300px
    def loading
      render_with_template
    end

    # @display min_height 300px
    def custom_icon
      render_with_template
    end
  end
end
