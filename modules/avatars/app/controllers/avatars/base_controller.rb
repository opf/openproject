# frozen_string_literal: true

module ::Avatars
  class BaseController < ::ApplicationController
    before_action :ensure_enabled

    def update
      if request.put?
        result = service_request(type: :update)
        if result.success?
          flash[:notice] = result.result
          render plain: result.result, status: :ok
        else
          render plain: result.errors.full_messages.join(", "), status: :bad_request
        end
      else
        head :method_not_allowed
      end
    end

    def destroy
      if request.delete?
        result = service_request(type: :destroy)

        # Regular flash (not flash.now): the turbo_stream "reload" response below
        # triggers a full page reload, so the message must survive to that request.
        if result.success?
          flash[:notice] = result.result
        else
          flash[:error] = result.errors.full_messages.join(", ")
        end

        # A full reload (not a Turbo visit) is needed so the browser refetches the
        # cached avatar image; the turbo_power "reload" action does just that.
        render turbo_stream: turbo_stream.reload
      else
        head :method_not_allowed
      end
    end

    def update_color
      result = update_color_request

      # rubocop:disable-next Rails/ActionControllerFlashBeforeRender
      if result.success?
        flash[:notice] = t("avatars.message_avatar_color_updated")
      else
        flash[:error] = result.errors.full_messages.join(", ")
      end

      # A full reload is needed so every already-rendered avatar on the page
      # (not just the one in the avatar section) picks up the new color.
      render turbo_stream: turbo_stream.reload
    end

    private

    def update_color_request
      ::Users::UpdateService
        .new(model: @user, user: current_user)
        .call(pref: { avatar_color: params[:avatar_color] })
    end

    def redirect_path
      raise SubclassResponsibilityError
    end

    def ensure_enabled
      unless ::OpenProject::Avatars::AvatarManager.avatars_enabled?
        render_404
      end
    end

    def service_request(type:)
      service = ::Avatars::UpdateService.new @user

      if type == :update
        service.replace params[:file]
      elsif type == :destroy
        service.destroy!
      end
    end
  end
end
