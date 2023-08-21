module ::Avatars
  class AvatarController < ::ApplicationController
    before_action :ensure_enabled
    before_action :find_avatar

    def show
      send_file @avatar.diskfile,
                filename: filename_for_content_disposition(@avatar.filename),
                type: @avatar.content_type,
                disposition: 'inline'
    rescue StandardError => e
      Rails.logger.error "Failed to render avatar for #{@avatar&.id}: #{e.message}"
      head :not_found
    end

    private

    def find_avatar
      @avatar = User.get_local_avatar(params[:id])

      unless @avatar
        head :not_found
        false
      end
    end

    def ensure_enabled
      unless ::OpenProject::Avatars::AvatarManager.local_avatars_enabled?
        head :not_found
        false
      end
    end
  end
end
