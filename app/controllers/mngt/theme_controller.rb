# frozen_string_literal: true

class Mngt::ThemeController < ApplicationController
  before_action :require_login
  no_authorization_required! :update

  def update
    theme = params[:theme].to_s
    valid = UserPreference::THEMES.map(&:to_s)
    return render json: { error: "invalid_theme" }, status: :unprocessable_entity unless valid.include?(theme)

    current_user.pref.update!(theme:)
    render json: { theme: }
  end
end
