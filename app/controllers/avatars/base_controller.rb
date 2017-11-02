module ::Avatars
  class BaseController < ::ApplicationController
    helper :avatar
    before_action :ensure_enabled

    include AttachmentsHelper

    def update
      if request.put?
        result = service_request(type: :update)
        if result.success?
          render plain: result.result, status: 200
        else
          render plain: result.errors.full_messages.join(", "), status: 400
        end
      else
        head :method_not_allowed
      end
    end

    def destroy
      if request.delete?
        result = service_request(type: :destroy)
        if result.success?
          flash[:notice] = result.result
        else
          flash[:error] = result.errors.full_messages.join(", ")
        end
        redirect_to redirect_path
      else
        head :method_not_allowed
      end
    end

    private

    def redirect_path
      raise NotImplementedError
    end

    def ensure_enabled
      unless ::OpenProject::Avatars::AvatarManager.avatars_enabled?
        render_404
      end
    end

    def service_request(type:)
      service = ::Avatars::UpdateService.new @user

      if type == :update
        service.replace params[:avatar]
      elsif type == :destroy
        service.destroy
      end
    end
  end
end
