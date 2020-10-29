# frozen_string_literal: true

module MetaTags
  # Represents an HTML meta tag with content (<tag></tag>).
  # Content should be passed as a `:content` attribute.
  class ContentTag < Tag
    # Render tag into a Rails view.
    #
    # @param [ActionView::Base] view instance of a Rails view.
    # @return [String] HTML string for the tag.
    #
    def render(view)
      view.content_tag(name, attributes[:content], prepare_attributes(attributes.except(:content)))
    end
  end
end
