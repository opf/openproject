# frozen_string_literal: true

class IconComponent < ViewComponent::Base
  def initialize(name:, classnames: '')
    @name = name
    @classnames = classnames
  end

  def call
    helpers.spot_icon @name, classnames: @classnames
  end
end
