# frozen_string_literal: true

class IconComponentPreview < ViewComponent::Preview

  # Icon component
  # ------------
  # Wrap an icon with the given name
  # See [Icon page](/lookbook/pages/styles/icons) for available icons
  #
  # @param name
  # @param classnames
  def default(name: 'help1', classnames: '')
    render(IconComponent.new(name:, classnames:))
  end
end
