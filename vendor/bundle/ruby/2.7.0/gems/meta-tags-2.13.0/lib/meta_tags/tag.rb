# frozen_string_literal: true

module MetaTags
  # Represents an HTML meta tag with no content (<tag />).
  class Tag
    attr_reader :name, :attributes

    # Initializes a new instance of Tag class.
    #
    # @param [String, Symbol] name HTML tag name
    # @param [Hash] attributes list of HTML tag attributes
    #
    def initialize(name, attributes = {})
      @name = name
      @attributes = attributes
    end

    # Render tag into a Rails view.
    #
    # @param [ActionView::Base] view instance of a Rails view.
    # @return [String] HTML string for the tag.
    #
    def render(view)
      view.tag(name, prepare_attributes(attributes), MetaTags.config.open_meta_tags?)
    end

    protected

    def prepare_attributes(attributes)
      attributes.each do |key, value|
        attributes[key] = value.iso8601 if value.respond_to?(:iso8601)
      end
    end
  end
end
