# frozen_string_literal: true

module TestManagement
  # Per-user switches of the shortcut tips and badges (0019): "Don't show tips again" in a tip
  # (fetch, JSON → 204) and the checkboxes of the shortcuts dialog (form → back to the page).
  class HotkeyPreferencesController < ApplicationController
    before_action :require_login
    no_authorization_required! :update

    def update
      preference = TestManagement::UserPreference.for(User.current)
      preference.assign_options(params.permit(*TestManagement::UserPreference::BOOLEAN_OPTIONS).to_h)
      saved = preference.save

      respond_to do |format|
        format.json { saved ? head(:no_content) : head(:unprocessable_entity) }
        format.html do
          flash[:notice] = I18n.t(:notice_successful_update) if saved
          redirect_back_or_to(home_path)
        end
      end
    end
  end
end
