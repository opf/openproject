# frozen_string_literal: true

class Mngt::PwaInstallBannerComponent < ApplicationComponent
  def render?
    User.current.logged?
  end
end
