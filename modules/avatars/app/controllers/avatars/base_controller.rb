module ::Avatars
  class BaseController < ::ApplicationController
    before_action :ensure_local_avatars_enabled, only: %i[destroy]

    def update_settings
      flash_result(settings_request, t("avatars.message_avatar_updated"))
      redirect_to redirect_path, status: :see_other
    end

    def destroy
      if request.delete?
        result = ::Avatars::UpdateService.new(@principal).destroy

        # Regular flash (not flash.now): the turbo_stream "reload" response below
        # triggers a full page reload, so the message must survive to that request.
        flash_result(result, result.result)

        # A full reload (not a Turbo visit) is needed so the browser refetches the
        # cached avatar image; the turbo_power "reload" action does just that.
        render turbo_stream: turbo_stream.reload
      else
        head :method_not_allowed
      end
    end

    private

    def settings_request
      attributes = params.permit(:avatar_type, :avatar_text, :avatar_color).to_h.symbolize_keys
      SettingsService.new(principal: @principal, user: current_user).call(attributes:, file: params[:file])
    end

    def flash_result(result, success_message)
      if result.success?
        flash[:notice] = success_message
      else
        flash[:error] = result.errors.full_messages.join(", ")
      end
    end

    def redirect_path
      raise SubclassResponsibilityError
    end

    def ensure_local_avatars_enabled
      unless ::OpenProject::Avatars::AvatarManager.local_avatars_enabled?
        render_404
      end
    end
  end
end
