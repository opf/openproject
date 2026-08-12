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
        # rubocop:disable Rails/ActionControllerFlashBeforeRender
        if result.success?
          flash[:notice] = result.result
        else
          flash[:error] = result.errors.full_messages.join(", ")
        end
        # rubocop:enable Rails/ActionControllerFlashBeforeRender

        # A full reload (not a Turbo visit) is needed so the browser refetches the
        # cached avatar image; the turbo_power "reload" action does just that.
        render turbo_stream: turbo_stream.reload
      else
        head :method_not_allowed
      end
    end

    private

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
        service.destroy
      end
    end
  end
end
