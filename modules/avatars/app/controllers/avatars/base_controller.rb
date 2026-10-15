module ::Avatars
  class BaseController < ::ApplicationController
    before_action :ensure_local_avatars_enabled, only: %i[update destroy image]

    def update_settings
      set_preference_flash(settings_request, "avatars.message_avatar_updated")
      redirect_to redirect_path, status: :see_other
    end

    def image
      response.headers["Cache-Control"] = "private, no-store"
      attachment = helpers.local_avatar?(@principal)
      return head :not_found unless attachment
      return head :forbidden unless image_accessible?(attachment)

      send_image(attachment)
    end

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

    def update_color
      render_preference_update(update_color_request, "avatars.message_avatar_color_updated")
    end

    def update_text
      render_preference_update(update_text_request, "avatars.message_avatar_text_updated")
    end

    private

    def settings_request
      attributes = params.permit(:avatar_type, :avatar_text, :avatar_color).to_h.symbolize_keys
      SettingsService.new(principal: @principal, user: current_user).call(attributes:, file: params[:file])
    end

    def image_accessible?(attachment)
      !attachment.status_quarantined? && (!attachment.pending_virus_scan? || attachment.author == current_user)
    end

    def send_image(attachment)
      if attachment.external_storage?
        redirect_to attachment.external_url.to_s, allow_other_host: true
      else
        send_file attachment.diskfile.path, type: attachment.served_content_type, disposition: "inline"
      end
    end

    def set_preference_flash(result, message)
      if result.success?
        flash[:notice] = t(message)
      else
        flash[:error] = result.errors.full_messages.join(", ")
      end
    end

    def render_preference_update(result, message)
      set_preference_flash(result, message)
      render turbo_stream: turbo_stream.reload
    end

    # Users and groups store/update avatar_color through different services and
    # param shapes (UserPreference vs. a plain Group attribute), so subclasses
    # provide their own.
    def update_color_request
      raise SubclassResponsibilityError
    end

    def update_text_request
      raise SubclassResponsibilityError
    end

    def redirect_path
      raise SubclassResponsibilityError
    end

    def ensure_local_avatars_enabled
      unless ::OpenProject::Avatars::AvatarManager.local_avatars_enabled?
        render_404
      end
    end

    def service_request(type:)
      service = ::Avatars::UpdateService.new @principal

      if type == :update
        service.replace params[:file]
      elsif type == :destroy
        service.destroy
      end
    end
  end
end
